/**
 * Evaluates detected shelf products against the planogram for a given store.
 * Creates PlanogramCompliance__c child records on the ShelfAudit__c.
 */
public with sharing class PlanogramComplianceService {

    public static ComplianceResult evaluate(
        Id auditId,
        List<Product2> expectedProducts,
        List<ImageAnalysisService.DetectedProduct> detectedProducts
    ) {
        // Build lookup map: productCode → detected product
        Map<String, ImageAnalysisService.DetectedProduct> detectedMap = new Map<String, ImageAnalysisService.DetectedProduct>();
        for (ImageAnalysisService.DetectedProduct dp : detectedProducts) {
            if (dp.isABCFoods && String.isNotBlank(dp.productCode)) {
                detectedMap.put(dp.productCode, dp);
            }
        }

        // Also match by label for demo (when productCode not on detected item)
        Map<String, ImageAnalysisService.DetectedProduct> labelMap = new Map<String, ImageAnalysisService.DetectedProduct>();
        for (ImageAnalysisService.DetectedProduct dp : detectedProducts) {
            if (dp.isABCFoods) {
                labelMap.put(dp.label.toLowerCase(), dp);
            }
        }

        ComplianceResult result = new ComplianceResult();
        result.skusExpected      = expectedProducts.size();
        result.nonCompliantItems = new List<ComplianceItem>();
        result.missingSKUList    = new List<String>();
        result.missingProductIds = new List<Id>();

        List<PlanogramCompliance__c> complianceRecords = new List<PlanogramCompliance__c>();
        Integer skusFound = 0;
        Integer criticallyMissing = 0;

        for (Product2 p : expectedProducts) {
            Boolean found = detectedMap.containsKey(p.ProductCode);

            // Fallback: fuzzy match on product name
            if (!found) {
                for (String key : labelMap.keySet()) {
                    if (key.containsIgnoreCase(p.Name) ||
                        p.Name.toLowerCase().containsIgnoreCase(key.split(' ')[0])) {
                        found = true;
                        break;
                    }
                }
            }

            // Placement__c is the canonical picklist (used by PT v9); Planogram_Position__c is display fallback
            String  expectedPlacement = String.isNotBlank(p.Placement__c) ? p.Placement__c : p.Planogram_Position__c;
            Integer expectedFace      = p.Expected_Facings__c != null ? Integer.valueOf(p.Expected_Facings__c) : 2;
            Boolean isCompliant       = false;
            String  actualPos         = '';
            Integer actualFace        = 0;
            String  recommendation    = '';

            if (found) {
                skusFound++;
                ImageAnalysisService.DetectedProduct dp = detectedMap.get(p.ProductCode);
                if (dp == null) {
                    for (String k : labelMap.keySet()) {
                        if (k.containsIgnoreCase(p.Name)) {
                            dp = labelMap.get(k);
                            break;
                        }
                    }
                }
                actualPos  = dp != null && String.isNotBlank(dp.position) ? dp.position : 'Detected (position unknown)';
                actualFace = 1;

                // Trust AI placementStatus when available; fall back to position string matching
                if (dp != null && String.isNotBlank(dp.placementStatus)) {
                    isCompliant = dp.placementStatus.equalsIgnoreCase('Correct');
                } else {
                    isCompliant = (expectedPlacement == null || actualPos.containsIgnoreCase('Eye Level'));
                }

                if (!isCompliant) {
                    recommendation = 'Move ' + p.Name + ' to ' + (expectedPlacement != null ? expectedPlacement : 'Eye-Level Placement') +
                                     '. Currently at: ' + actualPos;
                    ComplianceItem ci = new ComplianceItem();
                    ci.productName    = p.Name;
                    ci.recommendation = recommendation;
                    ci.isEyeLevel     = expectedPlacement != null && expectedPlacement.containsIgnoreCase('Eye-Level');
                    result.nonCompliantItems.add(ci);
                }
            } else {
                result.missingSKUList.add(p.Name + ' (' + p.ProductCode + ')');
                result.missingProductIds.add(p.Id);
                recommendation = 'MISSING: ' + p.Name + ' not found on shelf. Restock immediately.';
                criticallyMissing++;

                ComplianceItem ci = new ComplianceItem();
                ci.productName    = p.Name;
                ci.recommendation = recommendation;
                ci.isEyeLevel     = expectedPlacement != null && expectedPlacement.containsIgnoreCase('Eye-Level');
                result.nonCompliantItems.add(ci);
            }

            complianceRecords.add(new PlanogramCompliance__c(
                ShelfAudit__c        = auditId,
                Product__c           = p.Id,
                ExpectedPosition__c  = expectedPlacement,
                ActualPosition__c    = actualPos,
                IsCompliant__c       = isCompliant,
                ExpectedFacings__c   = expectedFace,
                ActualFacings__c     = actualFace,
                RecommendedAction__c = recommendation
            ));
        }

        if (!complianceRecords.isEmpty()) {
            insert complianceRecords;
        }

        result.skusFound             = skusFound;
        result.criticallyMissingSKUs = criticallyMissing;
        result.complianceScore       = result.skusExpected > 0
            ? ((Decimal) skusFound / result.skusExpected * 100).setScale(1)
            : 0;
        result.missingSKUsSummary    = String.join(result.missingSKUList, '\n');
        return result;
    }

    // ─── Data classes ─────────────────────────────────────────────────────────

    public class ComplianceResult {
        public Decimal       complianceScore;
        public Integer       skusExpected;
        public Integer       skusFound;
        public Integer       criticallyMissingSKUs;
        public String        missingSKUsSummary;
        public List<String>  missingSKUList;
        public List<Id>      missingProductIds;
        public List<ComplianceItem> nonCompliantItems;
    }

    public class ComplianceItem {
        public String  productName;
        public String  recommendation;
        public Boolean isEyeLevel;
    }
}