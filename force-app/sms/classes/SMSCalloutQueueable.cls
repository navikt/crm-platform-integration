public class SMSCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private List<SMS__c> smsList;
    private CRM_ApplicationDomain.Domain domain;

    public void execute(QueueableContext context) {
        List<SMS__c> copiedRecords = new List<SMS__c>();
        for (SMS__c sms : smsList) {
            SMS__c smsCopy = new SMS__c(Id = sms.Id);
            try {
                HTTPResponse resp = SMSCalloutService.sendSMS(sms, domain);
                if (resp?.getStatusCode() == 200) {
                    smsCopy.Status__c = 'Sent';
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
    public SMSCalloutQueueable(List<SMS__c> smsList, CRM_ApplicationDomain.Domain domain) {
        this.smsList = smsList;
        this.domain = domain;
    }
}
