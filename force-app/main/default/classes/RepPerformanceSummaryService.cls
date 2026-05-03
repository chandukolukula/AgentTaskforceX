public with sharing class RepPerformanceSummaryService {

    public class Request {
        @InvocableVariable(required=false label='User ID' description='Salesforce ID of the rep. Defaults to the current user if blank.')
        public String userId;
    }

    public class Response {
        @InvocableVariable(description='Rep performance summary result for the Agentforce output renderer')
        public RepPerformanceSummaryResult results;
    }

    public class RepPerformanceSummaryResult {
        @InvocableVariable public String  repName;
        @InvocableVariable public String  displayMessage;
        @InvocableVariable public String  weekLabel;
        @InvocableVariable public Integer storesAudited;
        @InvocableVariable public Decimal avgCompliance;
        @InvocableVariable public String  trendLabel;
        @InvocableVariable public String  bestStoreName;
        @InvocableVariable public Decimal bestStoreScore;
        @InvocableVariable public String  worstStoreName;
        @InvocableVariable public Decimal worstStoreScore;
    }

    @InvocableMethod(
        label='Get Rep Performance Summary'
        description='Returns the field rep\'s weekly audit performance summary: stores visited, average compliance score, and best/worst store. Use when the rep asks "how am I doing?" or requests a performance update.'
        category='Retail Execution'
    )
    public static List<Response> getWeeklySummary(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            r.results = buildResult(String.isNotBlank(req.userId) ? req.userId : UserInfo.getUserId());
            results.add(r);
        }
        return results;
    }

    private static RepPerformanceSummaryResult buildResult(String userId) {
        RepPerformanceSummaryResult r = new RepPerformanceSummaryResult();

        List<User> users = [SELECT FirstName, Name FROM User WHERE Id = :userId WITH SECURITY_ENFORCED LIMIT 1];
        r.repName = users.isEmpty() ? 'Rep'
            : String.isNotBlank(users[0].FirstName) ? users[0].FirstName : users[0].Name;

        Date weekStart = Date.today().toStartOfWeek();
        List<String> months = new List<String>{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        r.weekLabel = months[weekStart.month()-1] + ' ' + weekStart.day()
                    + ' – ' + months[Date.today().month()-1] + ' ' + Date.today().day();

        List<ShelfAudit__c> audits = [
            SELECT OverallComplianceScore__c, RetailStore__r.Name
            FROM   ShelfAudit__c
            WHERE  Visit__r.OwnerId = :userId
              AND  Status__c = 'Completed'
              AND  AuditDate__c >= :weekStart
            WITH   SECURITY_ENFORCED
            ORDER BY OverallComplianceScore__c DESC
        ];

        r.storesAudited = audits.size();

        if (audits.isEmpty()) {
            r.trendLabel     = 'No Audits Yet';
            r.displayMessage = r.repName + ' has no completed audits this week yet. Ready to start!';
            return r;
        }

        Decimal total = 0;
        for (ShelfAudit__c a : audits) {
            if (a.OverallComplianceScore__c != null) total += a.OverallComplianceScore__c;
        }
        r.avgCompliance  = (total / audits.size()).setScale(1);
        r.trendLabel     = r.avgCompliance >= 80 ? 'Excellent' : r.avgCompliance >= 60 ? 'Good' : 'Needs Improvement';
        r.bestStoreName  = audits[0].RetailStore__r?.Name;
        r.bestStoreScore = audits[0].OverallComplianceScore__c != null ? audits[0].OverallComplianceScore__c.setScale(0) : 0;

        if (audits.size() > 1) {
            ShelfAudit__c last = audits[audits.size() - 1];
            r.worstStoreName  = last.RetailStore__r?.Name;
            r.worstStoreScore = last.OverallComplianceScore__c != null ? last.OverallComplianceScore__c.setScale(0) : 0;
        }

        String adj = r.avgCompliance >= 80 ? 'Great' : r.avgCompliance >= 60 ? 'Good' : 'Tough';
        r.displayMessage = adj + ' week, ' + r.repName + '! '
            + r.storesAudited + ' store(s) audited, averaging ' + r.avgCompliance + '% compliance. '
            + (r.avgCompliance >= 80 ? 'Keep it up!' : 'Focus on ' + r.worstStoreName + ' to raise the average.');
        return r;
    }
}
