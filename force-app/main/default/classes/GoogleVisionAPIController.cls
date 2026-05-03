public with sharing class GoogleVisionAPIController {

    private static final String API_KEY = 'AIzaSyC5YLmBhlyCh3-SP7M8vwYje000znnNtDM';
    private static final String ENDPOINT = 'callout:Google_Vision/v1/images:annotate?key=' + API_KEY;

    @AuraEnabled
    public static String analyzeImage(String base64Image) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30000);
            req.setBody(JSON.serialize(new Map<String, Object>{
                'requests' => new List<Object>{
                    new Map<String, Object>{
                        'image'    => new Map<String, Object>{ 'content' => base64Image },
                        'features' => new List<Object>{
                            new Map<String, Object>{ 'type' => 'LABEL_DETECTION',     'maxResults' => 20 },
                            new Map<String, Object>{ 'type' => 'OBJECT_LOCALIZATION', 'maxResults' => 10 },
                            new Map<String, Object>{ 'type' => 'TEXT_DETECTION' }
                        }
                    }
                }
            }));

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                AuraHandledException ex = new AuraHandledException(
                    'Google Vision error ' + res.getStatusCode() + ': ' + res.getBody());
                ex.setMessage('Google Vision error ' + res.getStatusCode() + ': ' + res.getBody());
                throw ex;
            }
            return res.getBody();
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }
}