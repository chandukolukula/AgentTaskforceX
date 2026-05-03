/**
 * Agentforce Action: Detects competitor products from shelf image analysis results.
 * Matches detected labels against the CompetitorProduct__c master list and
 * creates CompetitorPresence__c child records on the ShelfAudit__c.
 */
public with sharing class CompetitorIntelligenceService {

    @InvocableMethod(
        label='Get Competitor Intelligence'
        description='Returns a summary of competitor products detected on the shelf, including brand names, estimated quantities, and shelf share percentage.'
        category='Retail Execution'
    )
    public static List<CompetitorIntelligenceResult> getCompetitorIntelligence(
        List<CompetitorIntelligenceRequest> requests
    ) {
        List<CompetitorIntelligenceResult> results = new List<CompetitorIntelligenceResult>();
        for (CompetitorIntelligenceRequest req : requests) {
            CompetitorResult cr = detect(req.auditId, req.detectedLabels);
            CompetitorIntelligenceResult r = new CompetitorIntelligenceResult();
            r.competitorSummary         = cr.competitorSummary;
            r.competitorCount           = cr.detectedCompetitors.size();
            r.dominantCompetitorBrand   = cr.dominantBrand;
            r.success                   = true;
            results.add(r);
        }
        return results;
    }

    public static CompetitorResult detect(Id auditId, List<String> detectedLabels) {
        // Load active competitor product master
        List<CompetitorProduct__c> masterList = [
            SELECT Id, Name, CompetitorBrand__c, Category__c, AIDetectionKeywords__c
            FROM   CompetitorProduct__c
            WHERE  IsActive__c = true
            WITH   SECURITY_ENFORCED
        ];

        CompetitorResult result = new CompetitorResult();
        result.detectedCompetitors = new List<CompetitorPresence__c>();
        Map<String, Integer> brandCount = new Map<String, Integer>();
        List<CompetitorPresence__c> presenceRecords = new List<CompetitorPresence__c>();

        for (CompetitorProduct__c cp : masterList) {
            // Build keyword list from the detection keywords field
            List<String> keywords = new List<String>{
                cp.Name.toLowerCase(),
                String.isNotBlank(cp.CompetitorBrand__c) ? cp.CompetitorBrand__c.toLowerCase() : ''
            };
            if (String.isNotBlank(cp.AIDetectionKeywords__c)) {
                for (String kw : cp.AIDetectionKeywords__c.split(',')) {
                    keywords.add(kw.trim().toLowerCase());
                }
            }

            for (String label : detectedLabels) {
                String lowerLabel = label.toLowerCase();
                for (String kw : keywords) {
                    if (String.isNotBlank(kw) && lowerLabel.containsIgnoreCase(kw)) {
                        // Match found — record competitor presence
                        Integer qty = estimateQuantity(lowerLabel);
                        CompetitorPresence__c presence = new CompetitorPresence__c(
                            ShelfAudit__c        = auditId,
                            CompetitorProduct__c = cp.Id,
                            EstimatedQuantity__c = qty,
                            ShelfSharePercentage__c = 0,
                            ShelfPosition__c     = extractPosition(label)
                        );
                        presenceRecords.add(presence);
                        result.detectedCompetitors.add(presence);

                        Integer current = brandCount.get(cp.CompetitorBrand__c) != null
                            ? brandCount.get(cp.CompetitorBrand__c) : 0;
                        brandCount.put(cp.CompetitorBrand__c, current + qty);
                        break;
                    }
                }
            }
        }

        if (!presenceRecords.isEmpty()) {
            insert presenceRecords;
        }

        // Find dominant competitor
        Integer maxCount = 0;
        for (String brand : brandCount.keySet()) {
            if (brandCount.get(brand) > maxCount) {
                maxCount = brandCount.get(brand);
                result.dominantBrand = brand;
            }
        }

        result.competitorSummary = buildCompetitorSummary(brandCount);
        return result;
    }

    private static String buildCompetitorSummary(Map<String, Integer> brandCount) {
        if (brandCount.isEmpty()) return 'No competitor products detected.';
        List<String> lines = new List<String>();
        for (String brand : brandCount.keySet()) {
            lines.add('• ' + brand + ': ~' + brandCount.get(brand) + ' units');
        }
        return String.join(lines, '\n');
    }

    private static Integer estimateQuantity(String label) {
        // Simple heuristic: multiply by 3 for multi-pack labels, else default
        if (label.containsIgnoreCase('pack') || label.containsIgnoreCase('multi')) return 6;
        return 3;
    }

    private static String extractPosition(String label) {
        if (label.containsIgnoreCase('Eye Level')) return 'Eye Level';
        if (label.containsIgnoreCase('Bottom'))    return 'Bottom Shelf';
        if (label.containsIgnoreCase('Top'))       return 'Top Shelf';
        return 'Eye Level'; // default for demo
    }

    // ─── Data classes ─────────────────────────────────────────────────────────

    public class CompetitorResult {
        public List<CompetitorPresence__c> detectedCompetitors;
        public String                      competitorSummary;
        public String                      dominantBrand;
    }

    public class CompetitorIntelligenceRequest {
        @InvocableVariable(required=true label='Audit ID'        description='ID of the ShelfAudit__c record')
        public String       auditId;
        @InvocableVariable(required=false label='Visit ID'       description='ID of the Visit record')
        public String       visitId;
        @InvocableVariable(required=true label='Detected Labels' description='Comma-separated list of labels from AI image analysis')
        public List<String> detectedLabels;
    }

    public class CompetitorIntelligenceResult {
        @InvocableVariable public String  competitorSummary;
        @InvocableVariable public Integer competitorCount;
        @InvocableVariable public String  dominantCompetitorBrand;
        @InvocableVariable public Boolean success;
    }
}