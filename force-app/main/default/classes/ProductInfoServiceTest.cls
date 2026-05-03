@isTest
private class ProductInfoServiceTest {
    
    @testSetup
    static void setup() {
        // Create test products
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(
            Name = 'ChocoBites Premium',
            Description = 'Premium chocolate cookies',
            Family = 'Cookies & Biscuits',
            ProductCode = 'CB-001',
            IsActive = true
        ));
        
        products.add(new Product2(
            Name = 'HealthBar Energy',
            Description = 'High protein energy bar',
            Family = 'Health Bars',
            ProductCode = 'HB-001',
            IsActive = true
        ));
        
        products.add(new Product2(
            Name = 'CrunchyChips Classic',
            Description = 'Classic salted chips',
            Family = 'Salty Snacks',
            ProductCode = 'CC-001',
            IsActive = true
        ));
        
        insert products;
    }
    
    @isTest
    static void testSearchByName() {
        ProductInfoService.Request req = new ProductInfoService.Request();
        req.searchTerm = 'Choco';
        
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].results, 'Response wrapper should contain results');
        System.assertEquals(1, results[0].results.productCount, 'Should find 1 product');
        System.assertEquals(1, results[0].results.productDetails.size(), 'Should return one product detail row');
        System.assertEquals('ChocoBites Premium', results[0].results.productDetails[0].name, 'Should contain product name');
        System.assert(results[0].results.message.contains('Found'), 'Message should indicate success');
    }
    
    @isTest
    static void testSearchByDescription() {
        ProductInfoService.Request req = new ProductInfoService.Request();
        req.searchTerm = 'protein';
        
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(1, results[0].results.productCount, 'Should find 1 product');
        System.assertEquals(1, results[0].results.productDetails.size(), 'Should return one product detail row');
        System.assertEquals('HealthBar Energy', results[0].results.productDetails[0].name, 'Should contain product name');
    }
    
    @isTest
    static void testSearchAllProducts() {
        ProductInfoService.Request req = new ProductInfoService.Request();
        req.searchTerm = '';
        
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(3, results[0].results.productCount, 'Should find all 3 products');
        System.assert(results[0].results.message.contains('Found 3'), 'Message should show count');
    }
    
    @isTest
    static void testNoResults() {
        ProductInfoService.Request req = new ProductInfoService.Request();
        req.searchTerm = 'NonExistentProduct';
        
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(0, results[0].results.productCount, 'Should find 0 products');
        System.assert(results[0].results.message.contains('No products found'), 'Message should indicate no results');
        System.assertEquals(0, results[0].results.productDetails.size(), 'Product details should be empty');
    }
    
    @isTest
    static void testEmptyRequest() {
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>()
        );
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for empty request');
    }
    
    @isTest
    static void testSearchByFamilyInSearchTerm() {
        ProductInfoService.Request req = new ProductInfoService.Request();
        req.searchTerm = 'Salty';
        
        Test.startTest();
        List<ProductInfoService.Response> results = ProductInfoService.getProductInfo(
            new List<ProductInfoService.Request>{ req }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(1, results[0].results.productCount, 'Should find 1 product');
        System.assertEquals(1, results[0].results.productDetails.size(), 'Should return one product detail row');
        System.assertEquals('CrunchyChips Classic', results[0].results.productDetails[0].name, 'Should find product by family name');
    }

}