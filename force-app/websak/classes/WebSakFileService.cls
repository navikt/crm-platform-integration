public with sharing class WebSakFileService {
    private final string API_CONFIG_NAME = 'WEBSAK_API'; //API Config name to set when using the ApiController
    private final string SERVICE_AUTH_HEADER = 'Websak';

    public WebSakFileResponse postFile(String fileName, Blob fileContent) {
        Map<String, String> paramMap = new Map<String, String>();
        String encodedFileName = UrlEncodingUtility.encodeUrl(fileName);
        paramMap.put('fileName', encodedFileName);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_FILE_TO_WEBSAK', paramMap);
        apiCtrl.setSystemContext();
        apiCtrl.addBlob(fileContent);

        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        WebSakFileResponse resp = new WebSakFileResponse();
        if (statusCode == 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.info(encodedFileName + ' er overført til Websak', null);
            logger.publish();
            resp.success = true;
        } else {
            String errorRef = logError(apiCtrl.getResponse(), 'Error from WebSakFileService.postFile');
            resp.errorMessage = 'Publisering av fil til WebSak feilet. Referanse til feil: ' + errorRef;
            resp.success = false;
        }
        return resp;
    }

    public WebSakFileResponse postFile(String fileName, Blob fileContent, String ftpsCatalogue) {
        Map<String, String> paramMap = new Map<String, String>();
        String encodedFileName = UrlEncodingUtility.encodeUrl(fileName);
        paramMap.put('fileName', encodedFileName);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_FILE_TO_WEBSAK', paramMap);
        apiCtrl.setSystemContext();
        apiCtrl.addBlob(fileContent);

        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('ftpsCatalogue', ftpsCatalogue);
        apiCtrl.setUrlParams(urlParamMap);

        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        WebSakFileResponse resp = new WebSakFileResponse();
        if (statusCode == 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.info(encodedFileName + ' er overført til Websak', null);
            logger.publish();
            resp.success = true;
        } else {
            String errorRef = logError(apiCtrl.getResponse(), 'Error from WebSakFileService.postFile');
            resp.errorMessage = 'Publisering av fil til WebSak feilet. Referanse til feil: ' + errorRef;
            resp.success = false;
        }
        return resp;
    }

    private String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message + '\n ' + 'Status: ' + resp.getStatus() + '\n' + 'Body: ' + resp.getBody(), null);
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();

        return errorRef;
    }

    public class WebSakFileResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public String errorMessage;
    }
}
