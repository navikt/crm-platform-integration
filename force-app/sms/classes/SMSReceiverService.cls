@RestResource(urlMapping='/receiveSMS/*')

global without sharing class SMSReceiverService {

    @HttpPost
    global static void receiveSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String source = (String)requestBody.get('source');

        Map<String, Object> content = (Map<String, Object>)requestBody.get('content');
        String message = (String)content.get('userData');

        SMS__c newSMS = new SMS__c();

        newSMS.Message__c =  message;
        newSMS.Sender__c = source;
        newSMS.Status__c = 'Received';        
        
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
