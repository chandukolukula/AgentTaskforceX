/**
 * Agentforce Action: Retrieves the active Visit ID for the logged-in rep
 * so the Shelf Audit Screen Flow can be launched from the chatbot.
 */
public with sharing class ShelfAuditAgentService {

    @InvocableMethod(
        label='Get Active Visit for Shelf Audit'
        description='Returns the Visit ID of the most recent in-progress or planned Visit for the logged-in rep today. Used to launch the Shelf Audit from the Agentforce chatbot.'
        category='Retail Execution'
    )
    public static List<VisitContext> getActiveVisit(List<VisitRequest> requests) {
        List<VisitContext> results = new List<VisitContext>();

        Date today = Date.today();
        DateTime startOfDay = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay   = DateTime.newInstance(today.addDays(1), Time.newInstance(0, 0, 0, 0));
        Id userId = UserInfo.getUserId();

        List<Visit> visits = [
            SELECT Id, Status, RetailStore.Name
            FROM   Visit
            WHERE  VisitorId = :userId
              AND  PlannedVisitStartTime >= :startOfDay
              AND  PlannedVisitStartTime <  :endOfDay
              AND  Status IN ('InProgress', 'Planned')
            ORDER BY PlannedVisitStartTime ASC
        ];

        // Prefer InProgress, fall back to first Planned
        Visit best = null;
        for (Visit v : visits) {
            if (best == null || (v.Status == 'InProgress' && best.Status != 'InProgress')) {
                best = v;
            }
        }

        VisitContext ctx = new VisitContext();
        if (best != null) {
            ctx.visitId = best.Id;
            ctx.found   = true;
            ctx.message = 'Active visit found: ' + (best.RetailStore?.Name ?? 'store');
        } else {
            ctx.found   = false;
            ctx.message = 'No active visit found for today. Please create a visit first.';
        }

        results.add(ctx);
        return results;
    }

    public class VisitRequest {
        @InvocableVariable(label='Placeholder' description='No input required' required=false)
        public String placeholder;
    }

    public class VisitContext {
        @InvocableVariable(label='Visit ID' description='Salesforce ID of the active Visit — pass this to the Shelf Audit flow')
        public String visitId;

        @InvocableVariable(label='Found' description='True if an active visit was found for today')
        public Boolean found;

        @InvocableVariable(label='Message' description='Status message to display to the rep')
        public String message;
    }
}
