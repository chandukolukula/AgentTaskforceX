/**
 * Core Agentforce Action: Orchestrates the complete shelf audit workflow.
 * Invoked by the Retail Compliance Agent when a rep captures a shelf image.
 */
public with sharing class ShelfAuditService {

    @InvocableMethod(
        label='Conduct Shelf Audit'
        description='Analyzes a shelf image for planogram compliance, detects missing SKUs, identifies competitor products, and generates prioritized recommendations. Returns a complete audit report.'
        category='Retail Execution'
    )
    public static List<ShelfAuditResult> conductShelfAudit(List<ShelfAuditRequest> requests) {
        List<ShelfAuditResult> results = new List<ShelfAuditResult>();

        for (ShelfAuditRequest req : requests) {
            try {
                results.add(processAudit(req));
            } catch (Exception e) {
                ShelfAuditResult errorResult = new ShelfAuditResult();
                errorResult.success = false;
                errorResult.errorMessage = e.getMessage();
                results.add(errorResult);
            }
        }
        return results;
    }

    private static ShelfAuditResult processAudit(ShelfAuditRequest req) {
        // Derive storeId from Visit when not explicitly provided
        if (String.isBlank(req.storeId) && String.isNotBlank(req.visitId)) {
            List<Visit> visits = [SELECT PlaceId FROM Visit WHERE Id = :req.visitId LIMIT 1];
            if (!visits.isEmpty()) req.storeId = visits[0].PlaceId;
        }

        // Query parent audit score for rescan delta (SOQL before DML)
        Decimal parentScore = null;
        if (String.isNotBlank(req.parentAuditId)) {
            List<ShelfAudit__c> parents = [
                SELECT OverallComplianceScore__c FROM ShelfAudit__c
                WHERE Id = :req.parentAuditId WITH SECURITY_ENFORCED LIMIT 1
            ];
            if (!parents.isEmpty()) parentScore = parents[0].OverallComplianceScore__c;
        }

        // 1. Fetch expected SKUs — SOQL before any DML
        List<Product2> expectedProducts = [
            SELECT Id, Name, ProductCode, Family,
                   Planogram_Position__c, Placement__c, Expected_Facings__c
            FROM   Product2
            WHERE  ProductCode LIKE 'ABCF-%'
              AND  IsActive = true
            WITH   SECURITY_ENFORCED
        ];

        // 2. Call AI image analysis — callout must happen before any DML
        ImageAnalysisService.AnalysisResult imageResult =
            ImageAnalysisService.analyzeWithPromptTemplate(req.contentDocumentId, req.storeId);

        // 3. Create the ShelfAudit header record — DML after callout
        ShelfAudit__c audit = new ShelfAudit__c(
            Visit__c           = req.visitId,
            RetailStore__c     = req.storeId,
            AuditDate__c       = System.now(),
            Status__c          = 'AI Analysis Pending',
            ShelfImageURL__c   = null,
            ParentAudit__c     = String.isNotBlank(req.parentAuditId) ? (Id) req.parentAuditId : null
        );
        insert audit;

        // Link uploaded image to the created Shelf Audit record.
        if (String.isNotBlank(req.contentDocumentId)) {
            insert new ContentDocumentLink(
                ContentDocumentId = (Id) req.contentDocumentId,
                LinkedEntityId    = audit.Id,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
        }

        // 4. Evaluate planogram compliance
        PlanogramComplianceService.ComplianceResult compResult =
            PlanogramComplianceService.evaluate(audit.Id, expectedProducts, imageResult.detectedProducts);

        // 5. Detect competitor products
        CompetitorIntelligenceService.CompetitorResult compIntel =
            CompetitorIntelligenceService.detect(audit.Id, imageResult.detectedLabels);

        // 5a. Fallback: create CompetitorProduct__c + CompetitorPresence__c from AI text when no master-data keyword matched
        if (compIntel.detectedCompetitors.isEmpty() && String.isNotBlank(imageResult.competitorProductsText)) {
            List<CompetitorProduct__c> newCompProducts = new List<CompetitorProduct__c>();
            List<String>              compProductLines  = new List<String>();

            for (String line : imageResult.competitorProductsText.split('\n')) {
                String l = line.trim().replaceAll('^[-*•|]+\\s*', '');
                if (String.isNotBlank(l) && !l.equalsIgnoreCase('None')) {
                    String brand = imageResult.competitorNameToBrand != null
                        ? imageResult.competitorNameToBrand.get(l) : null;
                    newCompProducts.add(new CompetitorProduct__c(
                        Name                   = l,
                        CompetitorBrand__c     = brand,
                        Category__c            = 'Salty Snacks',
                        AIDetectionKeywords__c = l.toLowerCase(),
                        IsActive__c            = true
                    ));
                    compProductLines.add(l);
                }
            }

            if (!newCompProducts.isEmpty()) {
                insert newCompProducts;

                List<CompetitorPresence__c> fallbackPresence = new List<CompetitorPresence__c>();
                Id visitId = String.isNotBlank(req.visitId) ? (Id) req.visitId : null;
                for (Integer i = 0; i < newCompProducts.size(); i++) {
                    fallbackPresence.add(new CompetitorPresence__c(
                        ShelfAudit__c           = audit.Id,
                        Visit__c                = visitId,
                        CompetitorProduct__c    = newCompProducts[i].Id,
                        EstimatedQuantity__c    = 3,
                        ShelfSharePercentage__c = 0,
                        ShelfPosition__c        = 'Eye Level'
                    ));
                }

                if (imageResult.competitorShelfShare != null && imageResult.competitorShelfShare > 0) {
                    Decimal perRecord = (imageResult.competitorShelfShare / fallbackPresence.size()).setScale(1);
                    for (CompetitorPresence__c cp : fallbackPresence) {
                        cp.ShelfSharePercentage__c = perRecord;
                    }
                }

                insert fallbackPresence;
                compIntel.detectedCompetitors.addAll(fallbackPresence);
                if (String.isBlank(compIntel.competitorSummary) || compIntel.competitorSummary.startsWith('No competitor')) {
                    compIntel.competitorSummary = imageResult.competitorProductsText;
                }
            }
        }

        // 5b. Distribute total competitor shelf share proportionally across presence records
        if (!compIntel.detectedCompetitors.isEmpty()
                && imageResult.competitorShelfShare != null
                && imageResult.competitorShelfShare > 0) {
            Decimal totalUnits = 0;
            for (CompetitorPresence__c cp : compIntel.detectedCompetitors) {
                totalUnits += cp.EstimatedQuantity__c != null ? cp.EstimatedQuantity__c : 0;
            }
            if (totalUnits > 0) {
                List<CompetitorPresence__c> toUpdate = new List<CompetitorPresence__c>();
                for (CompetitorPresence__c cp : compIntel.detectedCompetitors) {
                    Decimal qty = cp.EstimatedQuantity__c != null ? cp.EstimatedQuantity__c : 0;
                    cp.ShelfSharePercentage__c = (qty / totalUnits * imageResult.competitorShelfShare).setScale(1);
                    toUpdate.add(cp);
                }
                update toUpdate;
            }
        }

        // 6. Calculate compliance from prompt-template found/missing counts
        Integer foundCount   = imageResult.foundAbcCount  != null ? imageResult.foundAbcCount  : ImageAnalysisService.countItems(imageResult.foundAbcProducts);
        Integer missingCount = imageResult.missingAbcCount != null ? imageResult.missingAbcCount : ImageAnalysisService.countItems(imageResult.missingAbcProducts);
        Integer totalCount   = foundCount + missingCount;
        Decimal finalCompliance;
        if (totalCount > 0) {
            finalCompliance = ((Decimal) foundCount / totalCount * 100).setScale(1);
            System.debug('### Prompt-based compliance: ' + foundCount + '/' + totalCount + ' = ' + finalCompliance + '%');
        } else {
            finalCompliance = compResult.complianceScore;
            System.debug('### No prompt products — using planogram compliance: ' + finalCompliance + '%');
        }

        // 7. Update audit header with computed metrics
        audit.Status__c                    = 'Completed';
        audit.OverallComplianceScore__c    = finalCompliance;
        audit.TotalSKUsExpected__c         = totalCount > 0 ? totalCount : expectedProducts.size();
        audit.TotalSKUsFound__c            = totalCount > 0 ? foundCount : compResult.skusFound;
        audit.ShelfSharePercentage__c      = imageResult.abcFoodsShelfShare;
        audit.CompetitorPresenceDetected__c = !compIntel.detectedCompetitors.isEmpty();
        audit.AIAnalysisSummary__c         = buildAISummary(compResult, compIntel, imageResult);
        update audit;

        // 7b. Store AI summary on the Visit record
        if (String.isNotBlank(req.visitId)) {
            Visit v = new Visit(Id = req.visitId);
            v.Prompt_Response__c = audit.AIAnalysisSummary__c;
            update v;
        }

        // 8. Insert AI-generated recommendations
        List<AuditRecommendation__c> recs = buildRecommendations(audit.Id, req.visitId, compResult, compIntel);
        if (!recs.isEmpty()) {
            insert recs;
        }

        // 9. Auto-create follow-up Tasks for the rep
        List<Task> tasks = buildFollowUpTasks(audit.Id, req.visitId, req.storeId, compResult, imageResult.lowStockProducts);
        if (!tasks.isEmpty()) {
            insert tasks;
        }

        ShelfAuditResult r = buildResult(audit, compResult, compIntel, recs);
        r.abcBrandsDetected      = imageResult.foundAbcProducts;
        r.abcBrandsMissing       = imageResult.missingAbcProducts;
        r.competitorShelfShare   = imageResult.competitorShelfShare;
        r.otherProductsSummary   = imageResult.otherProductsText;
        r.otherShelfShare        = imageResult.otherShelfShare;
        r.placementIssues        = imageResult.placementIssues;
        r.lowStockProducts       = imageResult.lowStockProducts;
        System.debug('### ShelfAuditService.processAudit building result | lowStockProducts=' + r.lowStockProducts);
        if (parentScore != null) {
            r.improvementDelta = (finalCompliance - parentScore).setScale(1);
        }
        // Use AI-parsed competitor text when CompetitorIntelligenceService finds nothing from detectedLabels
        if (String.isNotBlank(imageResult.competitorProductsText) && String.isBlank(r.competitorSummary)
                || (r.competitorSummary != null && r.competitorSummary.startsWith('No competitor'))) {
            r.competitorSummary = imageResult.competitorProductsText;
        }
        System.debug('### ShelfAuditService.processAudit COMPLETE | auditId=' + r.auditId + ' | success=' + r.success);
        System.debug('### ShelfAuditService result | abcBrandsDetected=' + r.abcBrandsDetected);
        System.debug('### ShelfAuditService result | abcBrandsMissing=' + r.abcBrandsMissing);
        System.debug('### ShelfAuditService result | competitorSummary=' + r.competitorSummary);
        System.debug('### ShelfAuditService result | lowStockProducts=' + r.lowStockProducts);
        System.debug('### ShelfAuditService result | shelfShare=' + r.shelfShare);
        return r;
    }

    private static String buildAISummary(
        PlanogramComplianceService.ComplianceResult cr,
        CompetitorIntelligenceService.CompetitorResult ci,
        ImageAnalysisService.AnalysisResult ir
    ) {
        return 'SHELF AUDIT SUMMARY\n' +
               '====================\n' +
               'Compliance Score: ' + cr.complianceScore + '%\n' +
               'SKUs Found: ' + cr.skusFound + ' / Expected: ' + cr.skusExpected + '\n' +
               'Brand Shelf Share: ' + ir.abcFoodsShelfShare + '%\n' +
               'Competitors Detected: ' + ci.detectedCompetitors.size() + '\n\n' +
               'COMPETITOR PRESENCE:\n' + ci.competitorSummary;
    }

    private static List<AuditRecommendation__c> buildRecommendations(
        Id auditId,
        String visitId,
        PlanogramComplianceService.ComplianceResult cr,
        CompetitorIntelligenceService.CompetitorResult ci
    ) {
        List<AuditRecommendation__c> recs = new List<AuditRecommendation__c>();
        Id visitRecordId = String.isNotBlank(visitId) ? (Id) visitId : null;

        for (PlanogramComplianceService.ComplianceItem item : cr.nonCompliantItems) {
            recs.add(new AuditRecommendation__c(
                ShelfAudit__c     = auditId,
                Visit__c          = visitRecordId,
                Category__c       = 'Shelf Placement',
                Priority__c       = item.isEyeLevel ? 'Critical' : 'High',
                Recommendation__c = item.recommendation,
                Status__c         = 'Pending'
            ));
        }

        if (!ci.detectedCompetitors.isEmpty()) {
            recs.add(new AuditRecommendation__c(
                ShelfAudit__c     = auditId,
                Visit__c          = visitRecordId,
                Category__c       = 'Competitor Response',
                Priority__c       = 'Medium',
                Recommendation__c = 'Competitor products detected: ' + ci.competitorSummary +
                                    '. Consider requesting additional ABC Foods facings from store manager.',
                Status__c         = 'Pending'
            ));
        }

        return recs;
    }

    private static List<Task> buildFollowUpTasks(
        Id auditId,
        Id visitId,
        String storeId,
        PlanogramComplianceService.ComplianceResult cr,
        String lowStockProducts
    ) {
        List<Task> tasks = new List<Task>();
        Date dueDate = Date.today().addDays(1);

        for (PlanogramComplianceService.ComplianceItem item : cr.nonCompliantItems) {
            tasks.add(new Task(
                Subject         = item.recommendation.abbreviate(255),
                WhatId          = auditId,
                ActivityDate    = dueDate,
                Priority        = item.isEyeLevel ? 'High' : 'Normal',
                Status          = 'Not Started',
                Description     = item.recommendation,
                Type            = 'Shelf Audit Follow-Up'
            ));
        }

        if (String.isNotBlank(lowStockProducts) && String.isNotBlank(storeId)) {
            for (String line : lowStockProducts.split('\n')) {
                String product = line.trim().replaceAll('^[-*•|]+\\s*', '');
                if (String.isNotBlank(product)) {
                    tasks.add(new Task(
                        Subject      = 'Low Stock Alert: ' + product,
                        WhatId       = (Id) storeId,
                        ActivityDate = Date.today(),
                        Priority     = 'High',
                        Status       = 'Not Started',
                        Description  = 'Low stock detected for ' + product + ' during shelf audit. Immediate reorder required.',
                        Type         = 'Shelf Audit Follow-Up'
                    ));
                }
            }
        }

        return tasks;
    }

    private static ShelfAuditResult buildResult(
        ShelfAudit__c audit,
        PlanogramComplianceService.ComplianceResult cr,
        CompetitorIntelligenceService.CompetitorResult ci,
        List<AuditRecommendation__c> recs
    ) {
        ShelfAuditResult result = new ShelfAuditResult();
        result.auditId             = audit.Id;
        result.auditNumber         = audit.Name;
        result.complianceScore     = audit.OverallComplianceScore__c;
        result.shelfShare          = audit.ShelfSharePercentage__c;
        result.competitorSummary   = ci.competitorSummary;
        result.recommendationCount = recs.size();
        result.aiSummary           = audit.AIAnalysisSummary__c;
        result.success             = true;
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static String uploadShelfImage(String imageBase64, String visitId) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title        = 'ShelfAudit_' + System.now().getTime();
            cv.PathOnClient = cv.Title + '.jpg';
            cv.VersionData  = EncodingUtil.base64Decode(imageBase64);
            cv.IsMajorVersion = true;
            if (String.isNotBlank(visitId)) {
                cv.FirstPublishLocationId = (Id) visitId;
            }
            insert cv;
            ContentVersion inserted = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            System.debug('### uploadShelfImage — ContentDocumentId=' + inserted.ContentDocumentId + ', VisitId=' + visitId);
            return inserted.ContentDocumentId;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    @AuraEnabled(cacheable=false)
    public static ShelfAuditResult conductShelfAuditAura(
        String visitId, String storeId, String contentDocumentId, String aisleSection, String parentAuditId
    ) {
        try {
            ShelfAuditRequest req = new ShelfAuditRequest();
            req.visitId           = visitId;
            req.storeId           = storeId;
            req.contentDocumentId = contentDocumentId;
            req.aisleSection      = aisleSection;
            req.parentAuditId     = parentAuditId;
            return processAudit(req);
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    // ─── Inner classes ───────────────────────────────────────────────────────

    public class ShelfAuditRequest {
        @InvocableVariable(required=true  label='Visit ID'        description='Salesforce ID of the field rep Visit record')
        public String visitId;

        @InvocableVariable(required=true  label='Retail Store ID' description='Salesforce ID of the Retail Store')
        public String storeId;

        @InvocableVariable(required=false label='Content Document ID' description='Salesforce ContentDocument ID of the uploaded shelf image')
        public String contentDocumentId;

        @InvocableVariable(required=false label='Aisle Section'       description='Aisle or section label (e.g. "Snacks Aisle 5")')
        public String aisleSection;

        @InvocableVariable(required=false label='Parent Audit ID' description='ID of the original ShelfAudit__c to link this rescan and calculate improvement delta')
        public String parentAuditId;
    }

    public class ShelfAuditResult {
        @InvocableVariable @AuraEnabled public String  auditId;
        @InvocableVariable @AuraEnabled public String  auditNumber;
        @InvocableVariable @AuraEnabled public Decimal complianceScore;
        @InvocableVariable @AuraEnabled public Decimal shelfShare;
        @InvocableVariable @AuraEnabled public String  competitorSummary;
        @InvocableVariable @AuraEnabled public Integer recommendationCount;
        @InvocableVariable @AuraEnabled public String  aiSummary;
        @InvocableVariable @AuraEnabled public Boolean success;
        @InvocableVariable @AuraEnabled public String  errorMessage;
        @InvocableVariable @AuraEnabled public String  abcBrandsDetected;
        @InvocableVariable @AuraEnabled public String  abcBrandsMissing;
        @InvocableVariable @AuraEnabled public Decimal competitorShelfShare;
        @InvocableVariable @AuraEnabled public String  otherProductsSummary;
        @InvocableVariable @AuraEnabled public Decimal otherShelfShare;
        @InvocableVariable @AuraEnabled public String  placementIssues;
        @InvocableVariable @AuraEnabled public String  lowStockProducts;
        @InvocableVariable @AuraEnabled public Decimal improvementDelta;
    }
}