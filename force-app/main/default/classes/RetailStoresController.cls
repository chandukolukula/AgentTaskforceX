/**
 * RetailStoresController
 * Utility Apex class to invoke a GenAI Prompt Template by name.
 * Note: This implementation assumes your org exposes an Apex-invocable
 * API or custom action to call the Prompt Builder/GenAI templates.
 *
 * If your org uses a specific API for Prompt Builder, replace the body
 * of invokePromptTemplate with the appropriate call. This implementation
 * provides a safe placeholder that returns a consistent message if no
 * server-side integration is present.
 */
public with sharing class RetailStoresController {
    @AuraEnabled
    public static String invokePromptTemplate(String promptName) {
        System.debug('[RetailStoresController] invokePromptTemplate called with promptName: ' + promptName);
        System.debug('[RetailStoresController] Running as user: ' + UserInfo.getUserId() + ' | ' + UserInfo.getUserName());

        // Try direct call via ConnectApi if available (preferred), otherwise fall back
        try {
            System.debug('[RetailStoresController] Building EinsteinPromptTemplateGenerationsInput...');
            ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            executeTemplateInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
            executeTemplateInput.isPreview = false;
            executeTemplateInput.inputParams = new Map<String, ConnectApi.WrappedValue>(); // no params
            System.debug('[RetailStoresController] Input built. Calling generateMessagesForPromptTemplate...');

            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(promptName, executeTemplateInput);

            System.debug('[RetailStoresController] Response received: ' + response);

            if (response != null && response.generations != null && !response.generations.isEmpty()) {
                String resultText = response.generations[0].text;
                System.debug('[RetailStoresController] Returning generation text (first 500 chars): ' + resultText.left(500));
                return resultText;
            }

            System.debug('[RetailStoresController] Response was null or had no generations');
        } catch (Exception ex) {
            System.debug('[RetailStoresController] Exception type: ' + ex.getTypeName());
            System.debug('[RetailStoresController] Exception message: ' + ex.getMessage());
            System.debug('[RetailStoresController] Exception stack trace: ' + ex.getStackTraceString());
            return '{"error":"' + ex.getMessage().replace('"', '\\"').replace('\n', ' ') + '"}';
        }

        System.debug('[RetailStoresController] No response generated for: ' + promptName);
        return '{"error":"No response from prompt template: ' + promptName + '"}';
    }

    @AuraEnabled
    public static void createStoreVisits(List<String> storeNames) {
        System.debug('[RetailStoresController] createStoreVisits called for ' + storeNames.size() + ' stores: ' + storeNames);

        // Look up RetailStore records by name
        List<RetailStore> stores = [
            SELECT Id, Name
            FROM RetailStore
            WHERE Name IN :storeNames
        ];

        if (stores.isEmpty()) {
            throw new AuraHandledException('No matching RetailStore records found for the selected stores.');
        }

        Datetime plannedStart = Datetime.now().addHours(1);
        Datetime plannedEnd   = plannedStart.addHours(1);

        List<Visit> visits = new List<Visit>();
        for (RetailStore store : stores) {
            Visit v = new Visit();
            v.PlaceId               = store.Id;
            v.PlannedVisitStartTime = plannedStart;
            v.PlannedVisitEndTime   = plannedEnd;
            v.Status                = 'Planned';
            v.VisitorId             = UserInfo.getUserId();
            v.InstructionDescription = 'Retail store inspection for ' + store.Name;
            visits.add(v);
        }

        insert visits;
        System.debug('[RetailStoresController] Created ' + visits.size() + ' Visit records.');
    }

}
