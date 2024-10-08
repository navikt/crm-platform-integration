@RestResource(urlMapping='/receiveSMS/*')
global without sharing class SMSReceiverService {
    @HttpPost
    global static void receiveSMS() {
        String countryCode;

        Map<String, SMS_Config__mdt> smsConfigByPlatformPartnerId = getSMSConfigByPlatformPartnerId();

        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(
            RestContext.request.requestBody.toString()
        );
        String source = (String) requestBody.get('source');
        if (source.contains('+')) {
            countryCode = source.substring(0, 3);
            source = source.substring(3, source.length());
        }

        Map<String, Object> content = (Map<String, Object>) requestBody.get('content');
        String message = (String) content.get('userData');

        Map<String, Object> route = (Map<String, Object>) requestBody.get('route');
        String recipient = (String) route.get('number');
        String platformPartnerId = (String) route.get('platformPartnerId');

        SMS__c newSMS = new SMS__c();

        Person__c person = FindAccountBasedOnPhone.findPersonAccount(source);
        newSMS.Account__c = person?.CRM_Account__c;

        newSMS.Message__c = message;
        newSMS.Sender__c = countryCode != null ? countryCode + source : source;
        newSMS.Status__c = 'Received';
        newSMS.Recipient__c = recipient;
        newSMS.Type__c = 'Incoming SMS';
        newSMS.Domain__c = smsConfigByPlatformPartnerId.get(platformPartnerId).Domain__c;

        try {
            insert newSMS;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, newSMS, CRM_ApplicationDomain.Domain.HOT);
            logger.publishSynch();
        }
    }

    private static Map<String, SMS_Config__mdt> getSMSConfigByPlatformPartnerId() {
        Map<String, SMS_Config__mdt> smsConfigByPlatformPartnerId = new Map<String, SMS_Config__mdt>();
        for (SMS_Config__mdt config : [
            SELECT Id, MasterLabel, DeveloperName, Domain__c, Source__c, PlatformId__c, PlatformPartnerId__c
            FROM SMS_Config__mdt
        ]) {
            smsConfigByPlatformPartnerId.put(config.PlatformPartnerId__c, config);
        }
        return smsConfigByPlatformPartnerId;
    }
}
