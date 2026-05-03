/**
 * Service class to retrieve Retail Stores based on User's city
 * Used by GenAI Prompt Template: Get_Retail_Stores_By_User_City
 */
public with sharing class RetailStoreByUserCityService {
    
    /**
     * Get retail stores for a user based on their city
     * @param requests List of UserCityRequest containing user information
     * @return List of RetailStore records in the user's city
     */
    @InvocableMethod(label='Get Retail Stores by User City' 
                     description='Retrieves retail stores based on the user\'s city')
    public static List<RetailStoreResult> getRetailStoresByUserCity(List<UserCityRequest> requests) {
        List<RetailStoreResult> results = new List<RetailStoreResult>();
        
        if (requests == null || requests.isEmpty()) {
            return results;
        }
        
        UserCityRequest request = requests[0];
        String userId = request.userId;
        String userCity = request.userCity;
        
        try {
            // Use provided userCity or query User record if not provided
            String cityToSearch = userCity;
            
            if (String.isBlank(cityToSearch) && String.isNotBlank(userId)) {
                // Query the User record to get the City
                User userRecord = [
                    SELECT Id, City, State, Country
                    FROM User
                    WHERE Id = :userId
                    LIMIT 1
                ];
                cityToSearch = userRecord.City;
            }
            
            if (String.isBlank(cityToSearch)) {
                RetailStoreResult emptyResult = new RetailStoreResult();
                emptyResult.storeDetails = '';
                emptyResult.userCity = 'Not specified';
                emptyResult.storeCount = 0;
                emptyResult.message = 'User city is not specified';
                results.add(emptyResult);
                return results;
            }
            
            // Query RetailStore records matching the user's city
            List<RetailStore> storeRecords = [
                SELECT Id, Name, 
                       Street,
                       City,
                       State, 
                       Country,
                       PostalCode
                FROM RetailStore
                WHERE City = :cityToSearch
                ORDER BY Name
            ];
            
            RetailStoreResult result = new RetailStoreResult();
            result.userCity = cityToSearch;
            result.storeCount = storeRecords.size();
            
            if (storeRecords.isEmpty()) {
                result.storeDetails = '';
                result.message = 'No retail stores found in ' + cityToSearch + '. Please check nearby cities or contact customer service.';
            } else {
                result.message = 'Found ' + storeRecords.size() + ' retail store(s) in ' + cityToSearch + ':';
                
                // Format store details as text (similar to ProductInfoService)
                List<String> storeLines = new List<String>();
                for (RetailStore store : storeRecords) {
                    String storeLine = '🏪 **' + store.Name + '**';
                    
                    if (String.isNotBlank(store.Street)) {
                        storeLine += '\n   📍 Address: ' + store.Street;
                    }
                    
                    if (String.isNotBlank(store.City) || String.isNotBlank(store.State)) {
                        String location = '';
                        if (String.isNotBlank(store.City)) location += store.City;
                        if (String.isNotBlank(store.State)) {
                            location += (String.isNotBlank(location) ? ', ' : '') + store.State;
                        }
                        if (String.isNotBlank(location)) {
                            storeLine += '\n   🌍 Location: ' + location;
                        }
                    }
                    
                    if (String.isNotBlank(store.PostalCode)) {
                        storeLine += '\n   📮 Postal Code: ' + store.PostalCode;
                    }
                    
                    if (String.isNotBlank(store.Country)) {
                        storeLine += '\n   🌎 Country: ' + store.Country;
                    }
                    
                    storeLines.add(storeLine);
                }
                
                result.storeDetails = String.join(storeLines, '\n\n');
            }
            
            results.add(result);
            
        } catch (Exception e) {
            RetailStoreResult errorResult = new RetailStoreResult();
            errorResult.storeDetails = '';
            errorResult.userCity = 'Error';
            errorResult.storeCount = 0;
            errorResult.message = 'Error retrieving stores: ' + e.getMessage();
            results.add(errorResult);
        }
        
        return results;
    }
    
    /**
     * Input class (deprecated) - kept for backward compatibility but ignored.
     * The service now uses the current running user's Id and does not require inputs.
     */
    public class UserCityRequest {
        @InvocableVariable(label='User ID' description='Salesforce User ID (ignored)')
        public String userId;
        
        @InvocableVariable(label='User City' description='City name to search stores in (ignored)')
        public String userCity;
    }
    
    /**
     * Result class with formatted store details
     */
    public class RetailStoreResult {
        @InvocableVariable(label='Store Details' description='Formatted list of retail stores')
        public String storeDetails;
        
        @InvocableVariable(label='User City' description='The city searched')
        public String userCity;
        
        @InvocableVariable(label='Store Count' description='Number of stores found')
        public Integer storeCount;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
    }
}