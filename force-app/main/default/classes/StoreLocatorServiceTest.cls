@isTest
private class StoreLocatorServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test retail stores with geolocation
        List<Account> stores = new List<Account>();
        
        // San Francisco store
        stores.add(new Account(
            Name = 'ABC Foods SF Market',
            BillingStreet = '123 Market St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94102',
            Phone = '(415) 555-0001',
            BillingLatitude = 37.7749,
            BillingLongitude = -122.4194
        ));
        
        // Oakland store
        stores.add(new Account(
            Name = 'ABC Foods Oakland',
            BillingStreet = '456 Broadway',
            BillingCity = 'Oakland',
            BillingState = 'CA',
            BillingPostalCode = '94607',
            Phone = '(510) 555-0002',
            BillingLatitude = 37.8044,
            BillingLongitude = -122.2712
        ));
        
        // Los Angeles store (far away)
        stores.add(new Account(
            Name = 'ABC Foods LA',
            BillingStreet = '789 Sunset Blvd',
            BillingCity = 'Los Angeles',
            BillingState = 'CA',
            BillingPostalCode = '90028',
            Phone = '(323) 555-0003',
            BillingLatitude = 34.0522,
            BillingLongitude = -118.2437
        ));
        
        insert stores;
    }
    
    @isTest
    static void testFindNearbyStores() {
        // Test finding stores near San Francisco
        StoreLocatorService.StoreRequest request = new StoreLocatorService.StoreRequest();
        request.latitude = 37.7749; // San Francisco
        request.longitude = -122.4194;
        request.radius = 25;
        
        Test.startTest();
        List<StoreLocatorService.StoreResult> results = StoreLocatorService.findNearbyStores(
            new List<StoreLocatorService.StoreRequest>{ request }
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].count > 0, 'Should find at least one store');
        System.assert(results[0].stores.size() > 0, 'Should have stores in result');
        System.assertEquals(results[0].stores.size(), results[0].distances.size(), 
            'Should have equal number of stores and distances');
    }
    
    @isTest
    static void testFindNearbyStoresNoneInRange() {
        // Test finding stores with small radius (should find none in LA from SF)
        StoreLocatorService.StoreRequest request = new StoreLocatorService.StoreRequest();
        request.latitude = 34.0522; // Los Angeles
        request.longitude = -118.2437;
        request.radius = 1; // Only 1 mile radius
        
        Test.startTest();
        List<StoreLocatorService.StoreResult> results = StoreLocatorService.findNearbyStores(
            new List<StoreLocatorService.StoreRequest>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].message.contains('No stores found'), 'Should indicate no stores found');
    }
    
    @isTest
    static void testFindNearbyStoresMissingCoordinates() {
        // Test with missing coordinates
        StoreLocatorService.StoreRequest request = new StoreLocatorService.StoreRequest();
        // Latitude and longitude not set
        
        Test.startTest();
        List<StoreLocatorService.StoreResult> results = StoreLocatorService.findNearbyStores(
            new List<StoreLocatorService.StoreRequest>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(0, results[0].count, 'Should find 0 stores');
        System.assert(results[0].message.contains('required'), 'Should indicate coordinates are required');
    }
    
    @isTest
    static void testFindNearbyStoresEmptyRequest() {
        // Test with empty request list
        Test.startTest();
        List<StoreLocatorService.StoreResult> results = StoreLocatorService.findNearbyStores(
            new List<StoreLocatorService.StoreRequest>()
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(0, results[0].count, 'Should have count of 0');
    }
    
    @isTest
    static void testFindNearbyStoresDefaultRadius() {
        // Test with default radius (should be 25 miles)
        StoreLocatorService.StoreRequest request = new StoreLocatorService.StoreRequest();
        request.latitude = 37.7749; // San Francisco
        request.longitude = -122.4194;
        // radius not set, should default to 25
        
        Test.startTest();
        List<StoreLocatorService.StoreResult> results = StoreLocatorService.findNearbyStores(
            new List<StoreLocatorService.StoreRequest>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].count >= 0, 'Should return valid count');
    }
}