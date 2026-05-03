public with sharing class RetailStoreInfoService {

    @InvocableMethod(
        label='Get Retail Stores By City'
        description='Returns retail store addresses for a given city'
        category='Retail Execution'
    )
    public static List<Response> getRetailStoresByCity(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null) {
            requests = new List<Request>();
        }

        for (Request req : requests) {
            Response res = new Response();
            RetailStoreResult out = new RetailStoreResult();
            out.retailStores = new List<RetailStoreAddress>();

            String city = req.city;
            out.citySearched = city;

            if (String.isBlank(city)) {
                out.storeCount = 0;
                out.found = false;
                out.message = 'City is required to find retail stores.';
            } else {
                List<RetailStore> stores = [
                    SELECT Id, Name, Street, City, State, Country, PostalCode
                    FROM RetailStore
                    WHERE City = :city
                    ORDER BY Name
                    LIMIT 50
                ];

                out.storeCount = stores.size();
                out.found = !stores.isEmpty();
                out.message = stores.isEmpty()
                    ? 'No retail stores found in ' + city + '.'
                    : 'Found ' + stores.size() + ' retail store(s) in ' + city + '.';

                for (RetailStore store : stores) {
                    RetailStoreAddress storeAddress = new RetailStoreAddress();
                    storeAddress.storeId = store.Id;
                    storeAddress.name = store.Name;
                    storeAddress.street = store.Street;
                    storeAddress.city = store.City;
                    storeAddress.state = store.State;
                    storeAddress.country = store.Country;
                    storeAddress.postalCode = store.PostalCode;
                    storeAddress.formattedAddress = formatAddress(
                        store.Street,
                        store.City,
                        store.State,
                        store.PostalCode,
                        store.Country
                    );
                    out.retailStores.add(storeAddress);
                }
            }

            res.results = out;
            responses.add(res);
        }

        return responses;
    }

    public class Request {
        @InvocableVariable(label='City' description='City to search retail stores' required=true)
        public String city;
    }

    public class Response {
        @InvocableVariable(label='Results' description='Container for retail store search results')
        public RetailStoreResult results;
    }

    public class RetailStoreResult {
        @InvocableVariable(label='Retail Store Addresses' description='Retail stores found in the searched city')
        public List<RetailStoreAddress> retailStores;

        @InvocableVariable(label='City Searched' description='City used to find retail stores')
        public String citySearched;

        @InvocableVariable(label='Retail Store Count' description='Number of retail stores found in the city')
        public Integer storeCount;

        @InvocableVariable(label='Found' description='True if retail stores were found')
        public Boolean found;

        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }

    public class RetailStoreAddress {
        @InvocableVariable(label='Store ID' description='Salesforce ID of RetailStore record')
        public Id storeId;

        @InvocableVariable(label='Store Name' description='Retail store name')
        public String name;

        @InvocableVariable(label='Street' description='Street address')
        public String street;

        @InvocableVariable(label='City' description='City')
        public String city;

        @InvocableVariable(label='State' description='State or province')
        public String state;

        @InvocableVariable(label='Postal Code' description='ZIP or postal code')
        public String postalCode;

        @InvocableVariable(label='Country' description='Country')
        public String country;

        @InvocableVariable(label='Formatted Address' description='Single-line formatted store address')
        public String formattedAddress;
    }

    private static String formatAddress(String street, String city, String state, String postalCode, String country) {
        List<String> firstLine = new List<String>();
        List<String> secondLine = new List<String>();

        if (String.isNotBlank(street)) {
            firstLine.add(street);
        }
        if (String.isNotBlank(city)) {
            secondLine.add(city);
        }
        if (String.isNotBlank(state)) {
            secondLine.add(state);
        }
        if (String.isNotBlank(postalCode)) {
            secondLine.add(postalCode);
        }

        String address = '';
        if (!firstLine.isEmpty()) {
            address += String.join(firstLine, ', ');
        }
        if (!secondLine.isEmpty()) {
            if (String.isNotBlank(address)) {
                address += ', ';
            }
            address += String.join(secondLine, ', ');
        }
        if (String.isNotBlank(country)) {
            if (String.isNotBlank(address)) {
                address += ', ';
            }
            address += country;
        }
        return address;
    }
}
