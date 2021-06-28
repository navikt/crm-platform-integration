public with sharing class MonitorFssIntegration_Schedule implements Schedulable {
 
    public void execute(SchedulableContext sc) {
        getUnitFromNorg2();
     }
 
     @Future(callout=true)
     public static void getUnitFromNorg2(){
        string API_CONFIG_NAME = 'NORG2_UNIT_API'; //API Config name to set when using the ApiController
        string SERVICE_AUTH_HEADER = 'SaasToNavApiGw';
        
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('enhetsnummer', '0104');

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNIT_CONTACT_INFORMATION', paramMap);
        String serviceToken=getServiceToken(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Authorization', 'Bearer ' + serviceToken);
        apiCtrl.doCallout();

        String bodyString = apiCtrl.getResponse().getBody();

        if (String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }

        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if (statusCode == 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.info('Integrasjon ok', null);
            logger.publishSynch();
        }
        else{

        //something went wrong. Log error
        LoggerUtility logger = new LoggerUtility();
        logger.error('Integrasjon feilet', null);
        logger.publishSynch();
        }
        
    }

    private static String getServiceToken(String serviceName){
        //get access token from refresh token in database
        String refreshToken = CachedTokensHandler.getRefreshTokenFromDatabase();
        if (refreshToken == null)
            return null;
        Map<String, String> tokenByType = new Map<String, String>();            
        tokenByType = AzureAccessTokenService.getTokensFromRefreshToken(refreshToken);
        String accessToken=CryptoService.encryptString(tokenByType.get('access'));
        //get service token
        return AzureAccessTokenService.getTokenForOtherService(accessToken, serviceName);
    }
}
