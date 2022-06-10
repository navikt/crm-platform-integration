public with sharing class SMSCalloutService {
    public static HttpResponse sendSMS(SMS__c sms, CRM_ApplicationDomain.Domain domain) {
        String recipient = checkRecipient(sms.Recipient__c);
        String baseDevName = [SELECT developerName FROM API_Base_Configuration__mdt WHERE domain__c =:String.valueOf(domain)].developerName;
		String serviceDevName = [SELECT developerName from API_Service_Configuration__mdt WHERE API_Base_Configuration__r.DeveloperName =:baseDevName].developerName;

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(baseDevName, serviceDevName);
        apiCtrl.setBody(formatJSONBody(recipient, sms.Message__c));
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

    private static String formatJSONBody(String RCV, String TXT) {
        Map<String, String> mappy = new Map<String, String>();
        mappy.put('source', '20216'); //20216
        mappy.put('destination', RCV);
        mappy.put('userData', TXT);
        mappy.put('platformId', 'COMMON_API');
        mappy.put('platformPartnerId', '20216');

        return JSON.serialize(mappy);
    }

    public static String checkRecipient(String recipientPhone) {
        String recipient = recipientPhone.deleteWhitespace();
        //Check if null
        if (recipient == null) {
            throw new SMSCalloutServiceException('Recipient can not be blank.');
        }

        //Check length
        if (recipient.length() < 8 || recipient.length() > 14) {
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
