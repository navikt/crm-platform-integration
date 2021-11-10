@RestResource(urlMapping='/receiveSMS/*')
global without sharing class SMSReceiverService {
    @HttpPost
    global static void receiveSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String source = (String)requestBody.get('source');
        Map<String, Object> requestUserData = (Map<String, Object>)requestBody.get('content'); 
        String userData = (String)requestUserData.get('userData');

        System.debug('requestUserData JSON\n' + userData);
        System.debug('source JSON\n' + source);
        SMS__c newSMS = new SMS__c();
        newSMS.Message__c =  userData;

        List<Account> userAccount = [SELECT id, Name]  

        smsList.add(newSMS);
        insert smsList;
    }
}
