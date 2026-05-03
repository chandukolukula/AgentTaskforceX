/**
 * Apex controller for the repDashboard and shelfAuditCapture LWC components.
 */
public with sharing class RepDashboardController {

    @AuraEnabled(cacheable=true)
    public static List<Visit> getTodayVisits() {
        Date today = Date.today();
        DateTime startOfDay = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay   = DateTime.newInstance(today.addDays(1), Time.newInstance(0, 0, 0, 0));
        // WITH SECURITY_ENFORCED omitted — child subquery (ShelfAudits__r) is incompatible
        return [
            SELECT Id, Name, Status, PlannedVisitStartTime, PlannedVisitEndTime,
                   PlaceId, RetailStore.Name, RetailStore.Street, RetailStore.City
            FROM   Visit
            WHERE  VisitorId = :UserInfo.getUserId()
              AND  PlannedVisitStartTime >= :startOfDay
              AND  PlannedVisitStartTime < :endOfDay
            ORDER BY PlannedVisitStartTime ASC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<AuditRecommendation__c> getPriorityRecommendations() {
        return [
            SELECT Id, Priority__c, Category__c, Recommendation__c, Status__c,
                   ShelfAudit__r.Name,
                   ShelfAudit__r.RetailStore__r.Name
            FROM   AuditRecommendation__c
            WHERE  Status__c = 'Pending'
              AND  ShelfAudit__r.Visit__r.OwnerId = :UserInfo.getUserId()
              AND  CreatedDate = TODAY
            WITH   SECURITY_ENFORCED
            ORDER BY Priority__c ASC, CreatedDate DESC
            LIMIT  20
        ];
    }

    @AuraEnabled(cacheable=false)
    public static DashboardKPI getDashboardKPIs() {
        DashboardKPI kpi = new DashboardKPI();
        Id userId = UserInfo.getUserId();

        AggregateResult[] ar = [
            SELECT AVG(OverallComplianceScore__c) avgScore, COUNT(Id) cnt
            FROM   ShelfAudit__c
            WHERE  Visit__r.OwnerId = :userId
              AND  CreatedDate = TODAY
              AND  Status__c = 'Completed'
            WITH   SECURITY_ENFORCED
        ];
        kpi.avgComplianceScore = ar[0].get('avgScore') != null
            ? ((Decimal) ar[0].get('avgScore')).setScale(1) : 0;

        kpi.openTasks = [
            SELECT COUNT() FROM Task
            WHERE  OwnerId = :userId AND Status != 'Completed' AND ActivityDate >= :Date.today()
            WITH   SECURITY_ENFORCED
        ];

        kpi.criticalTasks = [
            SELECT COUNT() FROM Task
            WHERE  OwnerId = :userId AND Status != 'Completed'
              AND  Priority = 'High' AND ActivityDate >= :Date.today()
            WITH   SECURITY_ENFORCED
        ];

        kpi.pendingOrders = [
            SELECT COUNT() FROM Order
            WHERE  CreatedDate = TODAY AND Status = 'Draft'
              AND  Type = 'Replenishment'
            WITH   SECURITY_ENFORCED
        ];

        kpi.trend = kpi.avgComplianceScore >= 80 ? '↑ On Track'
                  : kpi.avgComplianceScore >= 60 ? '→ Needs Attention'
                  : '↓ Critical';
        return kpi;
    }

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserPhone() {
        User u = [SELECT MobilePhone FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        return u.MobilePhone;
    }

    @AuraEnabled(cacheable=true)
    public static List<ComplianceTrendPoint> getComplianceTrend() {
        List<ShelfAudit__c> audits = [
            SELECT AuditDate__c, OverallComplianceScore__c
            FROM   ShelfAudit__c
            WHERE  Visit__r.OwnerId = :UserInfo.getUserId()
              AND  Status__c = 'Completed'
              AND  OverallComplianceScore__c != null
            WITH   SECURITY_ENFORCED
            ORDER BY AuditDate__c DESC
            LIMIT  7
        ];
        List<ComplianceTrendPoint> points = new List<ComplianceTrendPoint>();
        List<String> months = new List<String>{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        for (Integer i = audits.size() - 1; i >= 0; i--) {
            ShelfAudit__c a = audits[i];
            ComplianceTrendPoint pt = new ComplianceTrendPoint();
            pt.score = a.OverallComplianceScore__c.setScale(1);
            DateTime dt = a.AuditDate__c;
            pt.dateLabel = months[dt.month() - 1] + ' ' + dt.day();
            points.add(pt);
        }
        return points;
    }

    public class DashboardKPI {
        @AuraEnabled public Decimal avgComplianceScore;
        @AuraEnabled public Integer openTasks;
        @AuraEnabled public Integer criticalTasks;
        @AuraEnabled public Integer pendingOrders;
        @AuraEnabled public String  trend;
    }

    public class ComplianceTrendPoint {
        @AuraEnabled public Decimal score;
        @AuraEnabled public String  dateLabel;
    }
}