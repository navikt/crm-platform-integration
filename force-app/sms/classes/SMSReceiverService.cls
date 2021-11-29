@RestResource(urlMapping='/receiveSMS/*')

global without sharing class SMSReceiverService {

    @HttpPost
    global static void receiveSMS() {
        String countryCode;

        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String source = (String)requestBody.get('source');
        if(source.length() == 11 && source.contains('+')) {
            countryCode = source.substring(0,3);
            source = source.substring(3,source.length());
        }

        Map<String, Object> content = (Map<String, Object>)requestBody.get('content');
        String message = (String)content.get('userData');

        Map<String, Object> route = (Map<String, Object>)requestBody.get('content');
        String recipient = (String)route.get('number');

        SMS__c newSMS = new SMS__c();

        List<Person__c> personList = FindAccountBasedOnPhone.findPersonAccount(source);
        if(personList.size() == 1) {
            newSMS.Account__c = personList[0].CRM_Account__c;
        }

        newSMS.Message__c =  message;
        newSMS.Sender__c = countryCode + source;
        newSMS.Status__c = 'Received';   
        newSMS.Recipient__c = recipient;
        if (recipient.contains('41716090')) { 
            newSMS.Domain__c = 'HOT';
        } else {
            newSMS.Domain__c = 'CRM';
        }
        newSMS.Type__c = 'Incoming SMS';
        
        try {
            insert newSMS;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, newSMS, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
}
