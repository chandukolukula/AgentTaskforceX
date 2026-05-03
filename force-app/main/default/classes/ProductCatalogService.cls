/**
 * Service class to retrieve all active Products from the catalog
 * Used by GenAI Prompt Template: Get_Product_Catalog
 */
public with sharing class ProductCatalogService {

    /**
     * Get all active products in the system
     * @return List of ProductCatalogResult containing formatted product details
     */
    @InvocableMethod(label='Get Products'
                     description='Retrieves all active products available in the system')
    public static List<ProductCatalogResult> getProducts(List<ProductCatalogRequest> requests) {
        List<ProductCatalogResult> results = new List<ProductCatalogResult>();
        System.debug('### ProductCatalogService.getProducts requests=' + requests);

        String contentDocumentId;
        if (requests != null && !requests.isEmpty()) {
            contentDocumentId = requests[0].contentDocumentId;
            if (String.isBlank(contentDocumentId)) {
                contentDocumentId = requests[0].placeholder;
            }
        }

        Id linkedVisitId;
        String retailStoreId;
        if (String.isNotBlank(contentDocumentId)) {
            String visitPrefix = Visit.SObjectType.getDescribe().getKeyPrefix();
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId = :contentDocumentId
            ];

            for (ContentDocumentLink l : links) {
                if (String.valueOf(l.LinkedEntityId).startsWith(visitPrefix)) {
                    linkedVisitId = l.LinkedEntityId;
                    break;
                }
            }

            if (linkedVisitId != null) {
                Visit v = [SELECT Id, PlaceId FROM Visit WHERE Id = :linkedVisitId LIMIT 1];
                retailStoreId = v.PlaceId;
            }
        }

        System.debug('### ProductCatalogService.getProducts contentDocumentId=' + contentDocumentId);
        System.debug('### ProductCatalogService.getProducts linkedVisitId=' + linkedVisitId);
        System.debug('### ProductCatalogService.getProducts retailStoreId=' + retailStoreId);

        try {
            List<StoreProduct> storeProducts;
            if (String.isNotBlank(retailStoreId)) {
                storeProducts = [
                    SELECT ProductId,
                           Quantity__c,
                                                     Product.Name,
                                                     Product.Category__c,
                                                     Product.Description,
                                                     Product.Family,
                                                     Product.About_the_Product__c,
                                                     Product.Placement__c
                    FROM StoreProduct
                    WHERE RetailStoreId = :retailStoreId
                                            AND Product.IsActive = true
                                        ORDER BY Product.Family, Product.Name
                ];
            } else {
                storeProducts = new List<StoreProduct>();
            }

            ProductCatalogResult result = new ProductCatalogResult();
            result.productCount = storeProducts.size();

            if (storeProducts.isEmpty()) {
                result.productDetails = '';
                result.message = 'No active products found in the system.';
            } else {
                result.message = 'Found ' + storeProducts.size() + ' product(s) in the catalog:';

                List<String> productLines = new List<String>();
                for (StoreProduct sp : storeProducts) {
                    String productLine = '**' + sp.Product.Name + '**';

                    if (sp.Quantity__c != null) {
                        productLine += '\n   Threshold: ' + Integer.valueOf(sp.Quantity__c);
                    }

                    if (String.isNotBlank(sp.Product.Family)) {
                        productLine += '\n   Category: ' + sp.Product.Family;
                    }

                    if (String.isNotBlank(sp.Product.Description)) {
                        productLine += '\n   Description: ' + sp.Product.Description;
                    }

                    if (String.isNotBlank(sp.Product.About_the_Product__c)) {
                        productLine += '\n   About: ' + sp.Product.About_the_Product__c;
                    }

                    if (String.isNotBlank(sp.Product.Placement__c)) {
                        productLine += '\n   Placement: ' + sp.Product.Placement__c;
                    }

                    productLines.add(productLine);
                }

                result.productDetails = String.join(productLines, '\n\n');
            }

            results.add(result);

        } catch (Exception e) {
            ProductCatalogResult errorResult = new ProductCatalogResult();
            errorResult.productDetails = '';
            errorResult.productCount   = 0;
            errorResult.message        = 'Error retrieving products: ' + e.getMessage();
            results.add(errorResult);
        }

        System.debug('### ProductCatalogService.getProducts results=' + results);
        return results;
    }

    /**
     * Input class - no fields required, exists to satisfy Invocable method signature
     */
    public class ProductCatalogRequest {
        @InvocableVariable(label='Placeholder' description='Not used')
        public String placeholder;

        @InvocableVariable(label='Content Document ID' description='Uploaded shelf image ContentDocumentId')
        public String contentDocumentId;
    }

    /**
     * Result class with formatted product catalog details
     */
    public class ProductCatalogResult {
        @InvocableVariable(label='Product Details' description='Formatted list of all products')
        public String productDetails;

        @InvocableVariable(label='Product Count' description='Total number of active products found')
        public Integer productCount;

        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }
}