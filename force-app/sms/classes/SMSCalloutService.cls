public with sharing class SMSCalloutService extends CRM_ApplicationDomain{
    public static HttpResponse sendSMS(SMS__c sms, CRM_ApplicationDomain.Domain domain, SMS_Config__mdt smsConfig) {
        String recipient = checkRecipient(sms.Recipient__c);
        
        /* added 19082022, could be a problem if there is several configurations with the same domain, so the field domain is set to unique */
        String baseDevName = [SELECT developerName FROM API_Base_Configuration__mdt WHERE domain__c =:String.valueOf(domain)].developerName;
		String serviceDevName = [SELECT developerName from API_Service_Configuration__mdt WHERE API_Base_Configuration__r.DeveloperName =:baseDevName].developerName;


        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(baseDevName, serviceDevName);
        apiCtrl.setBody(formatJSONBody(recipient, sms.Message__c, smsConfig));
        apiCtrl.addHeader('Content-Type', 'application/json');


        try {
            apiCtrl.doCallout();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, sms, domain);
            logger.publish();
        }

        if (apiCtrl.getResponse()?.getStatusCode() != 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                apiCtrl.getResponse()?.getStatusCode() +
                ': ' +
                apiCtrl.getResponse()?.getStatus(),
                sms,
                domain
            );
            logger.publish();
        }

        return apiCtrl.getResponse();
    }

    private static String formatJSONBody(String RCV, String TXT, SMS_Config__mdt smsConfig) {
        Map<String, String> mappy = new Map<String, String>();
        mappy.put('source', smsConfig.Source__c); //20216
        mappy.put('destination', RCV);
        mappy.put('userData', TXT);
        mappy.put('platformId', smsConfig.PlatformId__c);
        mappy.put('platformPartnerId', smsConfig.PlatformPartnerId__c);

        return JSON.serialize(mappy);
    }

    public static String checkRecipient(String recipient) {
        if (recipient == null) {
            throw new SMSCalloutServiceException('Recipient can not be blank.');
        }

        recipient = recipient.deleteWhitespace();
       
        //"abc xyz" should be "xyz"
        //"abc xyz." should be "xyz"
        if (!recipient.startsWith('+') && !recipient.isNumeric()) {
            recipient = recipient.replaceAll('\\D','');
        }

        if (recipient.length() < 8 || recipient.length() == 9 || recipient.length() > 14) {
            throw new SMSCalloutServiceException(
                'Recipient: ' +
                recipient +
                ' of length ' +
                String.valueOf(recipient.length()) +
                ' is not valid.'
            );
        }

        //replace 0 --> +
        if (recipient.left(3) == '047') {
            recipient = recipient.replaceFirst('0', '+');
        }

        //replace 00 --> +
        if (recipient.left(2) == '00') {
            recipient = recipient.replaceFirst('00', '+');
        }

        //add +47
        if (recipient.length() == 8) {
            recipient = '+47' + recipient;
        }

        //add + if starts with 47
        if (recipient.length() == 10 && recipient.left(2) == '47') {
            recipient = '+' + recipient;
        }

        //Checks numeric
        if (!recipient.right(recipient.length() - 1).IsNumeric()) {
            throw new SMSCalloutServiceException(
                'Recipient: ' +
                recipient +
                ' is not valid. Recipient can only contain numbers, and \'+\' before the country-code and number.'
            );
        }
        return recipient;
    }

    public class SMSCalloutServiceException extends Exception {
    }
}
