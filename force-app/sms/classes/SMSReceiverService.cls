@RestResource(urlMapping='/receiveSMS/*')
global without sharing class SMSReceiverService {
    @HttpPost
    global static void receiveSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String source = (String)requestBody.get('source');
       // String userData = (String)requestBody.get('content');

        SMS__c newSMS = new SMS__c();
        newSMS.Message__c =  source;

        smsList.add(newSMS);
        insert smsList;
    }
}
