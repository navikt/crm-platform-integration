public with sharing class SMSCalloutService {
    
    private final String API_CONFIG_NAME = 'SMS_API'; //API Config name to set when using the ApiController
    

    public static void sendSMS(Map<String, String> messageByRecipient){
        //for(String recipient:messageByRecipient.keySet()){

            String username = '{!$Credential.Password}';
            String password;
            String senderId;

            String body = 'USER=Username&PW=Password&RCV=4799887766&SND=SenderID&TXT=Message';

            ApiController apiCtrl = new ApiController();
            apiCtrl.initRequest('SMS_API', 'SEND_SMS');
            //apiCtrl.addHeader('POST', 'http://simple.pswin.com HTTP/1.1');
            //apiCtrl.addHeader('Content-type', 'application/x-www-form-urlencoded');
            //apiCtrl.addHeader('Host', 'simple.pswin.com');
            apiCtrl.setBody(body);
            //apiCtrl.setUrlParams(urlParamMap);

            try {
                apiCtrl.doCallout();
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            } 
            System.debug(apiCtrl.getResponse());

        //}


    }
}
