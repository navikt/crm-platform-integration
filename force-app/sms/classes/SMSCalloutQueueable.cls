public class SMSCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private List<SMS__c> SMSs;
    private CRM_ApplicationDomain.Domain domain;

    public void execute(QueueableContext context) {
        for(SMS__c sms:SMSs){
            SMSCalloutService.sendSMS(sms, domain);
        }
    }
    public SMSCalloutQueueable(List<SMS__c> SMSs, CRM_ApplicationDomain.Domain domain){
        this.SMSs = SMSs;
        this.domain = domain;
    }
    
}
