public class SMSCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private List<SMS__c> smsList;
    private CRM_ApplicationDomain.Domain domain;

    public void execute(QueueableContext context) {
        for (SMS__c sms : smsList) {
            try {
                HTTPResponse resp = SMSCalloutService.sendSMS(sms, domain);
                if (resp?.getStatusCode() == 200) {
                    sms.Status__c = 'Sent';
                } else {
                    sms.Status__c = 'Could not send';
                }
            } catch (Exception e) { 
                LoggerUtility logger = new LoggerUtility();
                logger.exception(e, sms, domain);
                logger.publishSynch();

                sms.Status__c = 'Could not send';
            }
        }
        try {
            update smsList;
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
