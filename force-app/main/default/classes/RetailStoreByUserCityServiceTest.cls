/**
 * Test class for RetailStoreByUserCityService (updated to use current user City)
 */
@isTest
private class RetailStoreByUserCityServiceTest {
    
    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        // Create a test user with City = 'TestCity'
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser+' + Math.random() + '@example.com',
            Username = 'testuser+' + Math.random() + '@example.com.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            City = 'TestCity',
            State = 'CA',
            Country = 'USA'
        );
        insert u;
        
        // Insert RetailStore records in TestCity and another city
        List<RetailStore> stores = new List<RetailStore>();
        stores.add(new RetailStore(Name='Store A', Street='123 Main St', City='TestCity', State='CA', Country='USA', PostalCode='94105'));
        stores.add(new RetailStore(Name='Store B', Street='456 Oak Ave', City='OtherCity', State='CA', Country='USA', PostalCode='94107'));
        insert stores;
    }

    @isTest
    static void testGetRetailStoresByUserCity_usesCurrentUserCity() {
        // Get the test user created in testSetup
        User testUser = [SELECT Id, City FROM User WHERE City = 'TestCity' LIMIT 1];
        System.runAs(testUser) {
            // Call the invocable method - inputs are ignored by implementation but we pass a placeholder
            List<RetailStoreByUserCityService.UserCityRequest> inputs = new List<RetailStoreByUserCityService.UserCityRequest>();
            inputs.add(new RetailStoreByUserCityService.UserCityRequest());
            Test.startTest();
            List<RetailStoreByUserCityService.RetailStoreResult> results = RetailStoreByUserCityService.getRetailStoresByUserCity(inputs);
            Test.stopTest();

            System.assertNotEquals(null, results, 'Result list should not be null');
            System.assertEquals(1, results.size(), 'Expect one result wrapper');
            RetailStoreByUserCityService.RetailStoreResult res = results[0];
            System.assertEquals('TestCity', res.userCity, 'Service should use current user city');
            System.assertEquals(1, res.storeCount, 'Should find 1 store in TestCity');
            System.assert(res.storeDetails.contains('Store A'), 'Store details should include Store A');
        }
    }
}