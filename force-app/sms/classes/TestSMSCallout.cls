public without sharing class TestSMSCallout {
    
    @InvocableMethod(label='Send SMS' description='Sends SMS')
    public static void sendSMS(List<String> RCV_TXT){
        RCV_TXT = RCV_TXT[0].split(' _ ');
        Map<String,String> message = new Map<String,String>();
        message.put(RCV_TXT[0], RCV_TXT[1]);
        SMSCalloutQueueable queueable = new SMSCalloutQueueable(message);
        System.enqueueJob(queueable);
    }
}
