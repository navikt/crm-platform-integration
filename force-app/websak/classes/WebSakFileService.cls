public with sharing class WebSakFileService {
   
    private final string API_CONFIG_NAME = 'WEBSAK_API'; //API Config name to set when using the ApiController
    private final string SERVICE_AUTH_HEADER = 'SaasToNavApiGw';

    public WebSakFileResponse postFile(String fileName, Blob fileContent){

        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('fileName', fileName);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_FILE', paramMap);
        apiCtrl.addBlob(fileContent);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.doCallout();


        WebSakFileResponse response=new WebSakFileResponse();
        response.success=true;
        return response;
    }


    public class WebSakFileResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMessage;
    }
}
