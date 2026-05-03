public with sharing class ProductInfoService {
    
    @InvocableMethod(
        label='Get Product Information'
        description='Returns product details for ABC Foods products'
        category='Retail Execution'
    )
    public static List<Response> getProductInfo(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null) {
            requests = new List<Request>();
        }

        for (Request req : requests) {
            Response res = new Response();
            ProductInfoResult out = new ProductInfoResult();
            out.productDetails = new List<ProductDetail>();

            String searchTerm = req.searchTerm;

            // Build query
            String query = 'SELECT Id, Name, Description, Family, ProductCode, ' +
                          'Expected_Facings__c, Planogram_Position__c ' +
                          'FROM Product2 ' +
                          'WHERE IsActive = true ';

            if (String.isNotBlank(searchTerm)) {
                query += 'AND (Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' ' +
                        'OR Description LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' ' +
                        'OR Family LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\') ';
            }

            query += 'ORDER BY Name LIMIT 50';

            List<Product2> products = Database.query(query);
            out.productCount = products.size();
            out.found = !products.isEmpty();

            if (products.isEmpty()) {
                out.message = 'No products found matching your criteria. Try searching for product categories like Cookies, Confectionery, Health Bars, Premium Range, Kids Range, Salty Snacks, or Sweet Snacks.';
            } else {
                out.message = 'Found ' + products.size() + ' ABC Foods product(s):';

                for (Product2 prod : products) {
                    ProductDetail detail = new ProductDetail();
                    detail.productId = prod.Id;
                    detail.name = prod.Name;
                    detail.category = prod.Family;
                    detail.description = prod.Description;
                    detail.sku = prod.ProductCode;
                    detail.expectedFacings = prod.Expected_Facings__c;
                    detail.planogramPosition = prod.Planogram_Position__c;
                    out.productDetails.add(detail);
                }
            }

            res.results = out;
            responses.add(res);
        }

        return responses;
    }
    
    public class Request {
        @InvocableVariable(label='Search Term' description='General search term' required=true)
        public String searchTerm;
    }

    public class Response {
        @InvocableVariable(label='Results' description='Container for product search results')
        public ProductInfoResult results;
    }
    
    public class ProductInfoResult {
        @InvocableVariable(label='Product Details' description='Structured list of products')
        public List<ProductDetail> productDetails;
        
        @InvocableVariable(label='Product Count' description='Number of products found')
        public Integer productCount;

        @InvocableVariable(label='Found' description='True if products were found')
        public Boolean found;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }

    public class ProductDetail {
        @InvocableVariable(label='Product ID' description='Salesforce ID of Product2 record')
        public Id productId;

        @InvocableVariable(label='Name' description='Product name')
        public String name;

        @InvocableVariable(label='Category' description='Product category/family')
        public String category;

        @InvocableVariable(label='Description' description='Product description')
        public String description;

        @InvocableVariable(label='SKU' description='Product code / SKU')
        public String sku;

        @InvocableVariable(label='Expected Facings' description='Expected facings for planogram')
        public Decimal expectedFacings;

        @InvocableVariable(label='Planogram Position' description='Planned shelf position')
        public String planogramPosition;
    }

}