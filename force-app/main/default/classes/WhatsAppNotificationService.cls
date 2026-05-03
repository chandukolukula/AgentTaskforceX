/**
 * Agentforce Action: Sends a formatted compliance report to the field rep's WhatsApp
 * using the Salesforce Messaging for WhatsApp (or an external webhook via Named Credential).
 *
 * Named Credential required: WhatsApp_Business_API
 * External URL: https://graph.facebook.com/v19.0/{PHONE_NUMBER_ID}/messages
 */
public with sharing class WhatsAppNotificationService {

    private static final String WHATSAPP_NC = 'callout:WhatsApp_Business_API';

    @InvocableMethod(
        label='Send WhatsApp Compliance Report'
        description='Sends an instant shelf audit compliance report to the field rep via WhatsApp, including brand visibility score, shelf share percentage, missing SKUs, and recommended actions.'
        category='Retail Execution'
    )
    public static List<WhatsAppResult> sendComplianceReport(List<WhatsAppRequest> requests) {
        List<WhatsAppResult> results = new List<WhatsAppResult>();
        for (WhatsAppRequest req : requests) {
            try {
                sendReport(req);
                WhatsAppResult r = new WhatsAppResult();
                r.success        = true;
                r.messageSent    = true;
                results.add(r);
            } catch (Exception e) {
                WhatsAppResult r = new WhatsAppResult();
                r.success        = false;
                r.errorMessage   = e.getMessage();
                results.add(r);
            }
        }
        return results;
    }

    private static void sendReport(WhatsAppRequest req) {
        if (String.isBlank(req.repPhoneNumber)) { return; }
        // Load the ShelfAudit for full context
        ShelfAudit__c audit = [
            SELECT Id, Name, OverallComplianceScore__c, ShelfSharePercentage__c,
                   MissingSKUs__c, AIAnalysisSummary__c, RetailStore__r.Name,
                   CompetitorPresenceDetected__c, TotalSKUsExpected__c, TotalSKUsFound__c
            FROM   ShelfAudit__c
            WHERE  Id = :req.auditId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];

        List<AuditRecommendation__c> recs = [
            SELECT Category__c, Priority__c, Recommendation__c
            FROM   AuditRecommendation__c
            WHERE  ShelfAudit__c = :req.auditId
              AND  Status__c = 'Pending'
            ORDER BY Priority__c ASC
            LIMIT  5
        ];

        String message = formatWhatsAppMessage(audit, recs, req.repName);
        sendViaWhatsAppAPI(req.repPhoneNumber, message);

        // Mark report as sent
        update new ShelfAudit__c(Id = req.auditId, WhatsAppReportSent__c = true, Status__c = 'Report Sent');
    }

    private static String formatWhatsAppMessage(
        ShelfAudit__c audit,
        List<AuditRecommendation__c> recs,
        String repName
    ) {
        String scoreEmoji = audit.OverallComplianceScore__c >= 80 ? '✅' :
                            audit.OverallComplianceScore__c >= 60 ? '⚠️' : '🚨';

        // Count missing SKUs and build critical alert if > 3
        String criticalAlert = '';
        if (String.isNotBlank(audit.MissingSKUs__c)) {
            List<String> skuLines = audit.MissingSKUs__c.split('\n');
            List<String> nonEmpty = new List<String>();
            for (String line : skuLines) {
                if (String.isNotBlank(line.trim())) nonEmpty.add(line.trim());
            }
            if (nonEmpty.size() > 3) {
                List<String> top3 = new List<String>{ nonEmpty[0], nonEmpty[1], nonEmpty[2] };
                criticalAlert = '🛒 *CRITICAL STOCKOUT DETECTED!*\n' +
                                'Request same-day delivery for:\n' +
                                '• ' + String.join(top3, '\n• ') + '\n' +
                                '_(+ ' + (nonEmpty.size() - 3) + ' more missing SKUs below)_\n' +
                                '─────────────────────\n\n';
            }
        }

        String msg = criticalAlert +
                     '*ABC Foods – Shelf Audit Report*\n' +
                     '📍 Store: ' + audit.RetailStore__r.Name + '\n' +
                     '📋 Audit: ' + audit.Name + '\n\n' +
                     scoreEmoji + ' *Compliance Score: ' + audit.OverallComplianceScore__c + '%*\n' +
                     '📊 SKUs Found: ' + audit.TotalSKUsFound__c + '/' + audit.TotalSKUsExpected__c + '\n' +
                     '🏪 Brand Shelf Share: ' + audit.ShelfSharePercentage__c + '%\n' +
                     '🔍 Competitor Products: ' + (audit.CompetitorPresenceDetected__c ? 'YES – Action Required' : 'None Detected') + '\n\n';

        if (String.isNotBlank(audit.MissingSKUs__c)) {
            msg += '*❌ Missing SKUs:*\n' + audit.MissingSKUs__c + '\n\n';
        }

        if (!recs.isEmpty()) {
            msg += '*🎯 Top Recommended Actions:*\n';
            for (AuditRecommendation__c rec : recs) {
                String emoji = rec.Priority__c == 'Critical' ? '🚨' :
                               rec.Priority__c == 'High'     ? '🔴' : '🟡';
                msg += emoji + ' ' + rec.Recommendation__c + '\n';
            }
        }

        msg += '\n_Powered by ABC Foods Agentforce • ' + System.now().format('dd MMM yyyy HH:mm') + '_';
        return msg;
    }

    private static void sendViaWhatsAppAPI(String phoneNumber, String message) {
        Organization org = [SELECT IsSandbox, OrganizationType FROM Organization LIMIT 1];
        if (Test.isRunningTest() || org.IsSandbox || org.OrganizationType == 'Developer Edition') {
            System.debug('WhatsApp message to ' + phoneNumber + ':\n' + message);
            return;
        }

        HttpRequest req = new HttpRequest();
        req.setEndpoint(WHATSAPP_NC + '/messages');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(15000);

        Map<String, Object> body = new Map<String, Object>{
            'messaging_product' => 'whatsapp',
            'to'                => phoneNumber,
            'type'              => 'text',
            'text'              => new Map<String, Object>{ 'body' => message }
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
            AuraHandledException ex = new AuraHandledException('WhatsApp API error: ' + res.getStatus() + ' – ' + res.getBody());
            ex.setMessage('WhatsApp API error: ' + res.getStatus() + ' – ' + res.getBody());
            throw ex;
        }
    }

    // ─── Data classes ─────────────────────────────────────────────────────────

    public class WhatsAppRequest {
        @InvocableVariable(required=true  label='Audit ID'         description='Salesforce ID of the completed ShelfAudit__c record')
        public String auditId;
        @InvocableVariable(required=false label='Rep Phone Number' description='Rep\'s WhatsApp phone number with country code (e.g. +14155552671)')
        public String repPhoneNumber;
        @InvocableVariable(required=false label='Rep Name'         description='First name of the field rep for personalized message')
        public String repName;
    }

    @AuraEnabled(cacheable=false)
    public static String getFormattedReport(String auditId) {
        ShelfAudit__c audit = [
            SELECT Id, Name, OverallComplianceScore__c, ShelfSharePercentage__c,
                   MissingSKUs__c, AIAnalysisSummary__c, RetailStore__r.Name,
                   CompetitorPresenceDetected__c, TotalSKUsExpected__c, TotalSKUsFound__c
            FROM   ShelfAudit__c
            WHERE  Id = :auditId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];
        List<AuditRecommendation__c> recs = [
            SELECT Category__c, Priority__c, Recommendation__c
            FROM   AuditRecommendation__c
            WHERE  ShelfAudit__c = :auditId AND Status__c = 'Pending'
            ORDER BY Priority__c ASC LIMIT 5
        ];
        return formatWhatsAppMessage(audit, recs, null);
    }

    @AuraEnabled(cacheable=false)
    public static WhatsAppResult sendComplianceReportAura(
        String auditId, String repPhoneNumber, String repName
    ) {
        WhatsAppRequest req = new WhatsAppRequest();
        req.auditId       = auditId;
        req.repPhoneNumber = repPhoneNumber;
        req.repName       = repName;
        List<WhatsAppResult> results = sendComplianceReport(new List<WhatsAppRequest>{ req });
        return results.isEmpty() ? null : results[0];
    }

    public class WhatsAppResult {
        @InvocableVariable @AuraEnabled public Boolean success;
        @InvocableVariable @AuraEnabled public Boolean messageSent;
        @InvocableVariable @AuraEnabled public String  errorMessage;
    }
}