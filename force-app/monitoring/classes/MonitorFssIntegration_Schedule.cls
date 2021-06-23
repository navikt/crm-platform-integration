public with sharing class MonitorFssIntegration_Schedule implements Queueable, Database.AllowsCallouts  {

   
    public void execute(QueueableContext context){
        string API_CONFIG_NAME = 'NORG2_UNIT_API'; //API Config name to set when using the ApiController
        string SERVICE_AUTH_HEADER = 'SaasToNavApiGw';
        Map<String, String> paramMap = new Map<String, String>();
        paramMap.put('enhetsnummer', '0104');

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNIT_CONTACT_INFORMATION', paramMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.doCallout();

        String bodyString = apiCtrl.getResponse().getBody();

        if (String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }

        Integer statusCode = apiCtrl.getResponse().getStatusCode();

        if (statusCode == 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.info('Integrasjon ok', null);
            logger.publish();
        }
        else{

        //something went wrong. Log error
        LoggerUtility logger = new LoggerUtility();
        logger.error('Integrasjon feilet', null);
        logger.publish();
        }
        
    }
}
