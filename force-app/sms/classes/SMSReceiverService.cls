@RestResource(urlMapping='/receiveSMS/*')

global without sharing class SMSReceiverService {

    @HttpPost
    global static void receiveSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        String countryCode;

        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String source = (String)requestBody.get('source');
        if(source.length() == 11 && source.contains('+')) {
            countryCode = source.substring(0,3);
            source = source.substring(3,source.length());
        }

        Map<String, Object> content = (Map<String, Object>)requestBody.get('content');
        String message = (String)content.get('userData');

        SMS__c newSMS = new SMS__c();

        // source = '%' + source;
        // List<Person__c> personList = [SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c FROM Person__c WHERE INT_KrrMobilePhone__c LIKE :source];
        List<Person__c> personList = FindAccountBasedOnPhone.findPersonAccount(source);
        if(personList.size() == 1) {
            newSMS.Account__c = personList[0].CRM_Account__c;
        }
        source = source.substring(1);
        newSMS.Message__c =  message;
        newSMS.Sender__c = countryCode + source;
        newSMS.Status__c = 'Received';   
        newSMS.Recipient__c = '+4741716090';  
        newSMS.Domain__c = 'HOT';
        newSMS.Type__c = 'Incoming SMS';
        
        smsList.add(newSMS);
        try {
            insert smsList;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }
}
