public class SMSCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private String recipient;
    private String message;
    private CRM_ApplicationDomain.Domain domain;

    public SMSCalloutQueueable(String recipient, String message, CRM_ApplicationDomain.Domain domain){
        this.recipient = recipient;
        this.message = message;
        this.domain = domain;
    }

    public void execute(QueueableContext context) {
        SMSCalloutService.sendSMS(this.recipient, this.message, this.domain);
    }
    
}
