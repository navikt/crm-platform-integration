public class SMSCalloutQueueable extends CRM_ApplicationDomain implements Queueable, Database.AllowsCallouts {
    private List<SMS__c> smsList;

    public void execute(QueueableContext context) {
        List<SMS__c> copiedRecords = new List<SMS__c>();
        Map<String, SMS_Config__mdt> domainToMetadata = new Map<String, SMS_Config__mdt>();

        List<SMS_Config__mdt> smsConfigs = [
            SELECT Domain__c, PlatformId__c, PlatformPartnerId__c, Source__c
            FROM SMS_Config__mdt
        ];
        for (SMS_Config__mdt smsConfig : smsConfigs) {
            domainToMetadata.put(smsConfig.Domain__c, smsConfig);
        }
        System.debug(smsList);

        CRM_ApplicationDomain.Domain domain = domainNameMap.get(smsList[0].Domain__c);

        for (SMS__c sms : smsList) {
            domain = domainNameMap.get(sms.Domain__c);
            SMS__c smsCopy = new SMS__c(Id = sms.Id);
            try {
                HTTPResponse resp = SMSCalloutService.sendSMS(sms, domain, domainToMetadata.get(sms.Domain__c));
                if (resp?.getStatusCode() == 200) {
                    smsCopy.Status__c = 'Sent';
                    smsCopy.RecipientFormatted__c = SMSCalloutService.checkRecipient(sms.Recipient__c);
                } else {
                    smsCopy.Status__c = 'Could not send';
                }
            } catch (Exception e) {
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, sms, domain);
                logger.publish();

                smsCopy.Status__c = 'Could not send';
            }
            copiedRecords.add(smsCopy);
        }
        try {
            update copiedRecords;
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, null, domain);
            logger.publishSynch();
        }
    }
    public SMSCalloutQueueable(List<SMS__c> smsList) {
        this.smsList = smsList;
        System.debug(smsList);
    }
}
