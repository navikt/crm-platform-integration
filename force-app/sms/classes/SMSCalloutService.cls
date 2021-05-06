public with sharing class SMSCalloutService {
    public static void sendSMS(Map<String, String> messageByRecipient){
        for(String recipient:messageByRecipient.keySet()){

            String body = jsonBody(recipient, messageByRecipient.get(recipient));

            ApiController apiCtrl = new ApiController();
            apiCtrl.initRequest('SMS_API', 'SEND_SMS');
            apiCtrl.setBody(body);
            apiCtrl.addHeader('Content-Type', 'application/json');

            System.debug(apiCtrl);

            try {
                apiCtrl.doCallout();
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
                logger.publishSynch();
            } 
            System.debug(apiCtrl.getResponse());
        }
    }


    private static String formatBody(String RCV, String TXT){
        Map<String,String> mappy = new Map<String,String>();
        //USER=Username&PW=Password&RCV=4799887766&SND=SenderID&TXT=Message
        mappy.put('USER', '{!$Credential.Username}');
        mappy.put('PW', '{!$Credential.Password}');
        mappy.put('RCV', RCV);
        mappy.put('SND', '20216');
        mappy.put('TXT', TXT);

        return urlEncode(mappy);
    }
    
    private static String jsonBody(String RCV, String TXT){
        Map<String,String> mappy = new Map<String,String>();
        mappy.put('source', '20216'); //20216
        mappy.put('destination', RCV);
        mappy.put('userData', TXT);
        mappy.put('platformId', 'COMMON_API');
        mappy.put('platformPartnerId', '20216');

        return JSON.serialize(mappy);
    }

    private static String urlEncode(Map<String, String> vals) {
        String result = '';
        for(String thisKey : vals.keySet()) {
            result += EncodingUtil.urlEncode(thisKey, 'UTF-8') + '=' + EncodingUtil.urlEncode(vals.get(thisKey), 'UTF-8') + '&';
        }
        return result.removeEnd('&');    
    }
}
