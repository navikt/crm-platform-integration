@RestResource(urlMapping='/receiveSMS/*')
global without sharing class SMSReceiverService {
    @HttpPost
    global static void receiveSMS() {
        String countryCode;

        Map<String, SMS_Config__mdt> smsConfigBySource = getSMSConfigBySource();

        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.request.requestBody.toString()
        );
        String source = (String) requestBody.get('source');
        if (source.length() == 11 && source.contains('+')) {
            countryCode = source.substring(0, 3);
            source = source.substring(3, source.length());
        }

        Map<String, Object> content = (Map<String, Object>) requestBody.get('content');
        String message = (String) content.get('userData');

        Map<String, Object> route = (Map<String, Object>) requestBody.get('route');
        String recipient = (String) route.get('number');

        SMS__c newSMS = new SMS__c();

        Map<String, Person__c> personByPhoneNumber = FindAccountBasedOnPhone.findPersonAccount(new List<String>{source});
        if (personByPhoneNumber.size() == 1) {
            newSMS.Account__c = personByPhoneNumber.get(source).CRM_Account__c;
        }

        newSMS.Message__c = message;
        newSMS.Sender__c = countryCode != null ? countryCode + source : source;
        newSMS.Status__c = 'Received';
        newSMS.Recipient__c = recipient;
        newSMS.Type__c = 'Incoming SMS';
        newSMS.Domain__c = smsConfigBySource.get(recipient).Domain__c;

        try {
            insert newSMS;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, newSMS, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static Map<String, SMS_Config__mdt> getSMSConfigBySource() {
        Map<String, SMS_Config__mdt> smsConfigBySource = new Map<String, SMS_Config__mdt>();
        for (SMS_Config__mdt config : [
            SELECT Id, MasterLabel, DeveloperName, Domain__c, Source__c, PlatformId__c, PlatformPartnerId__c
            FROM SMS_Config__mdt
        ]) {
            smsConfigBySource.put(config.Source__c, config);
        }
        return smsConfigBySource;
    }
}
