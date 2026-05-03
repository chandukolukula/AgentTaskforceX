public with sharing class StoreLocatorService {
    
    @InvocableMethod(label='Find Nearby Stores' description='Finds retail stores near user location')
    public static List<StoreResult> findNearbyStores(List<StoreRequest> requests) {
        List<StoreResult> results = new List<StoreResult>();
        
        if (requests.isEmpty()) {
            StoreResult emptyResult = new StoreResult();
            emptyResult.stores = new List<Account>();
            emptyResult.distances = new List<Decimal>();
            emptyResult.count = 0;
            emptyResult.message = 'No request provided.';
            results.add(emptyResult);
            return results;
        }
        
        StoreRequest req = requests[0];
        
        // Validate coordinates
        if (req.latitude == null || req.longitude == null) {
            StoreResult errorResult = new StoreResult();
            errorResult.stores = new List<Account>();
            errorResult.distances = new List<Decimal>();
            errorResult.count = 0;
            errorResult.message = 'Location coordinates are required.';
            results.add(errorResult);
            return results;
        }
        
        Integer searchRadius = req.radius != null ? req.radius : 25;
        
        // Query retail stores
        // Adjust the query based on your data model
        List<Account> stores = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, 
                   BillingPostalCode, Phone,
                   BillingLatitude, BillingLongitude
            FROM Account
            WHERE BillingLatitude != null
            AND BillingLongitude != null
            LIMIT 50
        ];
        
        // Calculate distances and filter
        List<StoreDistance> storeDistances = new List<StoreDistance>();
        
        for (Account store : stores) {
            Decimal distance = calculateDistance(
                req.latitude, req.longitude,
                store.BillingLatitude, store.BillingLongitude
            );
            
            if (distance <= searchRadius) {
                StoreDistance sd = new StoreDistance();
                sd.store = store;
                sd.distance = distance;
                storeDistances.add(sd);
            }
        }
        
        // Sort by distance
        storeDistances.sort();
        
        StoreResult result = new StoreResult();
        result.stores = new List<Account>();
        result.distances = new List<Decimal>();
        
        // Return top 10 closest stores
        Integer maxResults = Math.min(10, storeDistances.size());
        for (Integer i = 0; i < maxResults; i++) {
            result.stores.add(storeDistances[i].store);
            result.distances.add(storeDistances[i].distance);
        }
        
        result.count = result.stores.size();
        result.message = result.count == 0 ? 
            'No stores found within ' + searchRadius + ' miles.' :
            'Found ' + result.count + ' store(s) nearby.';
        
        results.add(result);
        
        return results;
    }
    
    // Haversine formula to calculate distance between two coordinates
    private static Decimal calculateDistance(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2) {
        Decimal R = 3959; // Earth radius in miles
        Decimal dLat = toRadians(lat2 - lat1);
        Decimal dLon = toRadians(lon2 - lon1);
        
        Decimal a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                   Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
                   Math.sin(dLon/2) * Math.sin(dLon/2);
        
        Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        Decimal distance = R * c;
        
        return distance.setScale(2);
    }
    
    private static Decimal toRadians(Decimal degrees) {
        return degrees * Math.PI / 180;
    }
    
    public class StoreRequest {
        @InvocableVariable(label='Latitude' description='User latitude coordinate' required=true)
        public Decimal latitude;
        
        @InvocableVariable(label='Longitude' description='User longitude coordinate' required=true)
        public Decimal longitude;
        
        @InvocableVariable(label='Search Radius' description='Search radius in miles (default: 25)')
        public Integer radius;
        
        @InvocableVariable(label='Product Name' description='Filter stores by product availability')
        public String productName;
    }
    
    public class StoreResult {
        @InvocableVariable(label='Stores' description='List of nearby stores')
        public List<Account> stores;
        
        @InvocableVariable(label='Distances' description='Distance to each store in miles')
        public List<Decimal> distances;
        
        @InvocableVariable(label='Count' description='Number of stores found')
        public Integer count;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }
    
    private class StoreDistance implements Comparable {
        public Account store;
        public Decimal distance;
        
        public Integer compareTo(Object compareTo) {
            StoreDistance compareToSD = (StoreDistance)compareTo;
            if (distance == compareToSD.distance) return 0;
            if (distance > compareToSD.distance) return 1;
            return -1;
        }
    }
}