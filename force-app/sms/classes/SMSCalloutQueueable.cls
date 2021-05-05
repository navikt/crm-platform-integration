public class SMSCalloutQueueable implements Queueable, Database.AllowsCallouts {
    private Map<String,String> messages;

    public SMSCalloutQueueable(Map<String, String> messages){
        this.messages = messages;
    }

    public void execute(QueueableContext context) {
        SMSCalloutService.sendSMS(this.messages);
    }
    
}
