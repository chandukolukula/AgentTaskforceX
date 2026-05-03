/**
 * @description Invocable Apex actions for Agentforce Shelf Audit
 * Provides agent-callable methods to conduct shelf audits and return structured results
 */
public with sharing class ShelfAuditCaptureAgentActions {

    public class Request {
        @InvocableVariable(required=true description='Visit ID for which to conduct the shelf audit')
        public String visitId;
    }

    public class Response {
        @InvocableVariable(description='Container for shelf audit results')
        public ShelfAuditResult results;
    }

    public class ShelfAuditResult {
        @InvocableVariable(description='Context message shown in the Agentforce panel before the rep captures a photo')
        public String displayMessage;

        @InvocableVariable(description='Visit ID linked to this audit')
        public String visitId;

        @InvocableVariable(description='Retail Store ID derived from the Visit — passed to the shelf audit capture component')
        public String storeId;

        @InvocableVariable(description='Store name for display in the panel header')
        public String storeName;

        @InvocableVariable(description='Compliance score from the last audit at this store, if one exists')
        public Decimal lastComplianceScore;

        @InvocableVariable(description='Date of the last audit at this store, formatted as a readable string')
        public String lastAuditDate;
    }

    @InvocableMethod(
        label='Conduct Shelf Audit via Agentforce'
        description='Prepares a shelf audit session by resolving store context from the Visit record and fetching the last audit summary. Returns store name, storeId, and context message for the Agentforce panel renderer.'
        category='Shelf Audit Capture'
    )
    public static List<Response> conductShelfAudit(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response res         = new Response();
            ShelfAuditResult out = new ShelfAuditResult();
            out.visitId          = req.visitId;

            try {
                // Resolve store from Visit
                List<Visit> visits = [
                    SELECT PlaceId, Place.Name
                    FROM   Visit
                    WHERE  Id = :req.visitId
                    LIMIT  1
                ];

                if (!visits.isEmpty() && visits[0].PlaceId != null) {
                    out.storeId   = visits[0].PlaceId;
                    out.storeName = visits[0].Place.Name;
                }

                // Fetch last audit for this store to surface context
                if (String.isNotBlank(out.storeId)) {
                    List<ShelfAudit__c> lastAudits = [
                        SELECT OverallComplianceScore__c, AuditDate__c
                        FROM   ShelfAudit__c
                        WHERE  RetailStore__c = :out.storeId
                          AND  Status__c      = 'Completed'
                        WITH   SECURITY_ENFORCED
                        ORDER BY AuditDate__c DESC
                        LIMIT  1
                    ];

                    if (!lastAudits.isEmpty()) {
                        out.lastComplianceScore = lastAudits[0].OverallComplianceScore__c;
                        out.lastAuditDate       = lastAudits[0].AuditDate__c != null
                            ? lastAudits[0].AuditDate__c.format('MMM d, yyyy')
                            : null;
                    }
                }

                out.displayMessage = buildDisplayMessage(out);

            } catch (Exception e) {
                out.displayMessage = 'Ready to start shelf audit. Capture a photo of the shelf below.';
            }

            res.results = out;
            responses.add(res);
        }

        return responses;
    }

    private static String buildDisplayMessage(ShelfAuditResult r) {
        String store = String.isNotBlank(r.storeName) ? r.storeName : 'this store';
        String msg   = 'Ready for shelf audit at ' + store + '. Capture a photo of the shelf to begin.';

        if (r.lastComplianceScore != null && String.isNotBlank(r.lastAuditDate)) {
            msg = 'Last audit at ' + store + ' on ' + r.lastAuditDate
                + ' scored ' + r.lastComplianceScore.setScale(0) + '% compliance. '
                + 'Capture a shelf photo below to start today\'s audit.';
        }

        return msg;
    }
}