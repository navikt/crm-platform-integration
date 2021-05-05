public class SMSCalloutQueueable implements Queueable {
    private Map<String,String> messages;

    SMSCalloutQueueable(Map<String, String> messages){
        this.messages = messages;
    }

    public void execute(QueueableContext context) {
        SMSCalloutService.sendSMS(this.messages);
    }
    
}
