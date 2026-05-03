/**
 * Agentforce Action: Creates a Salesforce Order (replenishment) when the
 * shelf audit detects critically missing SKUs, reducing supply-chain friction.
 */
public with sharing class ReplenishmentOrderService {

    @InvocableMethod(
        label='Create Replenishment Order'
        description='Automatically creates a replenishment order in Salesforce when missing SKUs are detected during a shelf audit. Returns the order number and line item details.'
        category='Retail Execution'
    )
    public static List<OrderResult> createReplenishmentOrder(List<OrderRequest> requests) {
        List<OrderResult> results = new List<OrderResult>();
        for (OrderRequest req : requests) {
            try {
                String details = createOrder(req.storeId, req.auditId, req.missingProductIds);
                OrderResult r  = new OrderResult();
                r.orderDetails = details;
                r.success      = true;
                results.add(r);
            } catch (Exception e) {
                OrderResult r  = new OrderResult();
                r.success      = false;
                r.errorMessage = e.getMessage();
                results.add(r);
            }
        }
        return results;
    }

    public static String createOrder(String storeId, Id auditId, List<Id> missingProductIds) {
        if (missingProductIds == null || missingProductIds.isEmpty()) {
            return 'No missing products — order not required.';
        }
        if (String.isBlank(storeId)) {
            return 'Replenishment order skipped — no store linked to this audit.';
        }

        // Get the Account linked to this retail store for the Order
        List<RetailStore> stores = [
            SELECT Id, Name, AccountId
            FROM   RetailStore
            WHERE  Id = :storeId
            WITH   SECURITY_ENFORCED
            LIMIT  1
        ];
        if (stores.isEmpty()) {
            return 'Replenishment order skipped — retail store not found.';
        }
        RetailStore store = stores[0];

        // Create the Order header
        Order ord = new Order(
            AccountId       = store.AccountId,
            EffectiveDate   = Date.today(),
            Status          = 'Draft',
            Type            = 'Replenishment',
            Description     = 'Auto-generated replenishment from Shelf Audit: ' + auditId
        );
        insert ord;

        // Load missing products with their standard pricebook entries
        List<PricebookEntry> entries = [
            SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice
            FROM   PricebookEntry
            WHERE  Product2Id IN :missingProductIds
              AND  Pricebook2.IsStandard = true
              AND  IsActive = true
            WITH   SECURITY_ENFORCED
        ];

        List<OrderItem> lineItems = new List<OrderItem>();
        List<String>    skuNames  = new List<String>();

        for (PricebookEntry pbe : entries) {
            Integer qty = replenishmentQty(pbe.Product2.Family);
            lineItems.add(new OrderItem(
                OrderId          = ord.Id,
                PricebookEntryId = pbe.Id,
                Product2Id       = pbe.Product2Id,
                Quantity         = qty,
                UnitPrice        = pbe.UnitPrice
            ));
            skuNames.add(pbe.Product2.Name + ' x' + qty);
        }

        if (!lineItems.isEmpty()) {
            insert lineItems;
        }

        // Update the ShelfAudit record to flag order creation
        update new ShelfAudit__c(
            Id = auditId,
            ReplenishmentOrderCreated__c = true
        );

        return 'Order ' + ord.OrderNumber + ' created for: ' + String.join(skuNames, ', ');
    }

    private static final Map<String, Integer> QTY_BY_FAMILY = new Map<String, Integer>{
        'Salty Snacks'  => 24,
        'Kids Range'    => 18,
        'Confectionery' => 18,
        'Health Bars'   => 12,
        'Biscuits'      => 12,
        'Premium Range' => 6
    };

    private static Integer replenishmentQty(String family) {
        if (String.isNotBlank(family) && QTY_BY_FAMILY.containsKey(family)) {
            return QTY_BY_FAMILY.get(family);
        }
        return 12;
    }

    // ─── Data classes ─────────────────────────────────────────────────────────

    public class OrderRequest {
        @InvocableVariable(required=true label='Store ID'           description='Salesforce ID of the Retail Store')
        public String    storeId;
        @InvocableVariable(required=true label='Audit ID'           description='Salesforce ID of the ShelfAudit__c record')
        public String    auditId;
        @InvocableVariable(required=true label='Missing Product IDs' description='List of Product2 IDs for missing SKUs')
        public List<Id>  missingProductIds;
    }

    public class OrderResult {
        @InvocableVariable public String  orderDetails;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String  errorMessage;
    }
}