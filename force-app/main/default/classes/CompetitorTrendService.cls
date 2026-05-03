public with sharing class CompetitorTrendService {

    public class Request {
        @InvocableVariable(required=false label='Store ID'
            description='Salesforce Record ID of the RetailStore. Provide this when the user is on a store record page. Takes priority over Store Name.')
        public String storeId;

        @InvocableVariable(required=false label='Store Name'
            description='Name of the retail store as mentioned by the user in conversation (e.g. "Metro Hypermarket"). Used when Store ID is not available.')
        public String storeName;

        @InvocableVariable(required=false label='Period Days' description='Days to look back for trend data (default 30)')
        public Integer periodDays;
    }

    public class Response {
        @InvocableVariable(description='Competitor trend result for the Agentforce output renderer')
        public CompetitorTrendResult results;
    }

    public class CompetitorTrendResult {
        @InvocableVariable public String  storeName;
        @InvocableVariable public String  displayMessage;
        @InvocableVariable public Integer periodDays;
        @InvocableVariable public Integer totalBrands;
        @InvocableVariable public String  brand1Name;
        @InvocableVariable public Decimal brand1AvgShare;
        @InvocableVariable public String  brand1Trend;
        @InvocableVariable public Decimal brand1Delta;
        @InvocableVariable public String  brand2Name;
        @InvocableVariable public Decimal brand2AvgShare;
        @InvocableVariable public String  brand2Trend;
        @InvocableVariable public Decimal brand2Delta;
        @InvocableVariable public String  brand3Name;
        @InvocableVariable public Decimal brand3AvgShare;
        @InvocableVariable public String  brand3Trend;
        @InvocableVariable public Decimal brand3Delta;
    }

    @InvocableMethod(
        label='Get Competitor Trend'
        description='Returns competitor shelf-share trends for a retail store. Provide storeId when on a store record page, or storeName when the rep mentions a store by name in conversation.'
        category='Retail Execution'
    )
    public static List<Response> getCompetitorTrend(List<Request> requests) {
        List<Response> results = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            String resolvedStoreId = resolveStoreId(req.storeId, req.storeName);
            r.results = buildResult(resolvedStoreId, req.storeName, req.periodDays != null ? req.periodDays : 30);
            results.add(r);
        }
        return results;
    }

    private static String resolveStoreId(String storeId, String storeName) {
        if (String.isNotBlank(storeId)) return storeId;
        if (String.isBlank(storeName)) return null;
        String pattern = '%' + storeName.trim() + '%';
        List<RetailStore> stores = [SELECT Id FROM RetailStore WHERE Name LIKE :pattern LIMIT 1];
        return stores.isEmpty() ? null : stores[0].Id;
    }

    private static CompetitorTrendResult buildResult(String storeId, String fallbackStoreName, Integer periodDays) {
        CompetitorTrendResult r = new CompetitorTrendResult();
        r.periodDays = periodDays;

        if (String.isBlank(storeId)) {
            r.storeName      = String.isNotBlank(fallbackStoreName) ? fallbackStoreName : 'this store';
            r.displayMessage = 'Store not found' + (String.isNotBlank(fallbackStoreName) ? ': ' + fallbackStoreName : '') + '. Please check the store name and try again.';
            return r;
        }

        List<RetailStore> stores = [SELECT Name FROM RetailStore WHERE Id = :storeId LIMIT 1];
        r.storeName = stores.isEmpty() ? 'this store' : stores[0].Name;

        Date cutoff   = Date.today().addDays(-periodDays);
        Date midpoint = Date.today().addDays(-(periodDays / 2));

        List<CompetitorPresence__c> presences = [
            SELECT CompetitorProduct__r.CompetitorBrand__c,
                   ShelfSharePercentage__c,
                   ShelfAudit__r.AuditDate__c
            FROM   CompetitorPresence__c
            WHERE  ShelfAudit__r.RetailStore__c = :storeId
              AND  ShelfAudit__r.Status__c = 'Completed'
              AND  ShelfAudit__r.AuditDate__c >= :cutoff
              AND  CompetitorProduct__c != null
            WITH   SECURITY_ENFORCED
            ORDER BY ShelfAudit__r.AuditDate__c ASC
            LIMIT  200
        ];

        Map<String, List<Decimal>> allShares   = new Map<String, List<Decimal>>();
        Map<String, List<Decimal>> earlyShares = new Map<String, List<Decimal>>();
        Map<String, List<Decimal>> lateShares  = new Map<String, List<Decimal>>();

        for (CompetitorPresence__c cp : presences) {
            String brand = cp.CompetitorProduct__r?.CompetitorBrand__c;
            if (String.isBlank(brand) || cp.ShelfSharePercentage__c == null) continue;
            if (!allShares.containsKey(brand)) {
                allShares.put(brand,   new List<Decimal>());
                earlyShares.put(brand, new List<Decimal>());
                lateShares.put(brand,  new List<Decimal>());
            }
            allShares.get(brand).add(cp.ShelfSharePercentage__c);
            if (cp.ShelfAudit__r.AuditDate__c.date() < midpoint) {
                earlyShares.get(brand).add(cp.ShelfSharePercentage__c);
            } else {
                lateShares.get(brand).add(cp.ShelfSharePercentage__c);
            }
        }

        r.totalBrands = allShares.size();

        if (allShares.isEmpty()) {
            r.displayMessage = 'No competitor products detected at ' + r.storeName + ' in the last ' + periodDays + ' days.';
            return r;
        }

        // Sort by average shelf share descending — take top 3
        List<BrandStat> stats = new List<BrandStat>();
        for (String brand : allShares.keySet()) {
            BrandStat bs  = new BrandStat();
            bs.name       = brand;
            bs.avgShare   = avg(allShares.get(brand));
            Decimal early = earlyShares.get(brand).isEmpty() ? bs.avgShare : avg(earlyShares.get(brand));
            Decimal late  = lateShares.get(brand).isEmpty()  ? bs.avgShare : avg(lateShares.get(brand));
            Decimal delta = (late - early).setScale(1);
            bs.trend = delta > 1 ? 'up' : delta < -1 ? 'down' : 'stable';
            bs.delta = delta.abs().setScale(1);
            stats.add(bs);
        }
        stats.sort();

        if (stats.size() > 0) { r.brand1Name = stats[0].name; r.brand1AvgShare = stats[0].avgShare; r.brand1Trend = stats[0].trend; r.brand1Delta = stats[0].delta; }
        if (stats.size() > 1) { r.brand2Name = stats[1].name; r.brand2AvgShare = stats[1].avgShare; r.brand2Trend = stats[1].trend; r.brand2Delta = stats[1].delta; }
        if (stats.size() > 2) { r.brand3Name = stats[2].name; r.brand3AvgShare = stats[2].avgShare; r.brand3Trend = stats[2].trend; r.brand3Delta = stats[2].delta; }

        String topBrand = stats[0].name;
        String trendWord = stats[0].trend == 'up' ? ', up ' + stats[0].delta + ' pts recently'
                         : stats[0].trend == 'down' ? ', down ' + stats[0].delta + ' pts recently' : '';
        r.displayMessage = r.totalBrands + ' competitor brand(s) detected at ' + r.storeName
            + '. ' + topBrand + ' leads with ' + stats[0].avgShare + '% shelf share' + trendWord + '.';
        return r;
    }

    private static Decimal avg(List<Decimal> vals) {
        if (vals.isEmpty()) return 0;
        Decimal s = 0;
        for (Decimal v : vals) s += v;
        return (s / vals.size()).setScale(1);
    }

    private class BrandStat implements Comparable {
        String  name;
        Decimal avgShare;
        String  trend;
        Decimal delta;
        public Integer compareTo(Object o) {
            BrandStat other = (BrandStat) o;
            return other.avgShare > this.avgShare ? 1 : other.avgShare < this.avgShare ? -1 : 0;
        }
    }
}