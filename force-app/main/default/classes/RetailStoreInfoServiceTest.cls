@isTest
private class RetailStoreInfoServiceTest {

    @isTest
    static void testMissingCityReturnsValidationMessage() {
        RetailStoreInfoService.Request req = new RetailStoreInfoService.Request();
        req.city = '';

        Test.startTest();
        List<RetailStoreInfoService.Response> results = RetailStoreInfoService.getRetailStoresByCity(
            new List<RetailStoreInfoService.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].results.found, 'Found should be false when city is blank');
        System.assertEquals(0, results[0].results.storeCount, 'Store count should be zero when city is blank');
        System.assert(results[0].results.message.contains('City is required'), 'Should return required city message');
        System.assertEquals(0, results[0].results.retailStores.size(), 'Retail stores should be empty when city is blank');
    }

    @isTest
    static void testNoStoreMatchByCity() {
        RetailStoreInfoService.Request req = new RetailStoreInfoService.Request();
        req.city = 'MissingCity';

        Test.startTest();
        List<RetailStoreInfoService.Response> results = RetailStoreInfoService.getRetailStoresByCity(
            new List<RetailStoreInfoService.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('MissingCity', results[0].results.citySearched, 'Should track city input');
        System.assertEquals(false, results[0].results.found, 'Found should be false when no stores match');
        System.assertEquals(0, results[0].results.storeCount, 'Store count should be zero when no stores match');
        System.assert(results[0].results.message.contains('No retail stores found'), 'Should return no stores message');
    }
}
