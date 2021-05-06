public with sharing class SMSCalloutService {

    public static SMSSendResponse sendSMS(String recipient, String message, CRM_ApplicationDomain.Domain domain){
        SMSSendResponse resp = new SMSSendResponse();

        checkRecipient(recipient);
        checkMessage(message);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('SMS_API', 'SEND_SMS');
        apiCtrl.setBody(formatJSONBody(recipient, message));
        apiCtrl.addHeader('Content-Type', 'application/json');

        try {
            apiCtrl.doCallout();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, domain);
            logger.publishSynch();
        }

        if(apiCtrl.getResponse().getStatusCode() != 200){
            LoggerUtility logger = new LoggerUtility();
            logger.error(apiCtrl.getResponse().getStatusCode() + ': ' + apiCtrl.getResponse().getStatus(), null, domain);
            logger.publishSynch();
        }

        resp.status = apiCtrl.getResponse().getStatus();
        resp.statusCode = apiCtrl.getResponse().getStatusCode();
        return resp;
    }

    private static String formatJSONBody(String RCV, String TXT){
        Map<String,String> mappy = new Map<String,String>();
        mappy.put('source', '20216'); //20216
        mappy.put('destination', RCV);
        mappy.put('userData', TXT);
        mappy.put('platformId', 'COMMON_API');
        mappy.put('platformPartnerId', '20216');

        return JSON.serialize(mappy);
    }

    private static void checkRecipient(String recipient){
        //Check length
        if(recipient.length() < 8 || recipient.length()> 12){
            throw new SMSCalloutServiceException('Recipient: ' + recipient + ' of length ' + String.valueOf(recipient.length()) + ' is not valid.');
        }

        //replace 00 --> +
        if(recipient.left(2) == '00'){
            recipient.replace('00', '+');
        }
        //add +47
        if(recipient.length() == 8){
            recipient = '+47' + recipient;
        }

        //Checks numeric
        if(!recipient.right(recipient.length()-1).IsNumeric()){
            throw new SMSCalloutServiceException('Recipient: ' + recipient + ' is not valid. Recipient can only contain numbers, and \'+\' before the country-code and number.');
        }
    }
    private static void checkMessage(String message){
        //check Number of Bytes
        if(getBytes(message) > 140){
            throw new SMSCalloutServiceException('Message: ' + message + ' of bytes ' + getBytes(message) + ' exeeds max byte length of 140.');
        }

    }
    private static Integer getBytes(String message){
        return Blob.valueOf(message).size();
    }

    
    // RESPONSE WRAPPERS
    public class SMSSendResponse {
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Integer statusCode;

        public SMSSendResponse() {
            this.status = null;
            this.statusCode = null;
        }
    }

}
