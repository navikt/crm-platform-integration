public without sharing class TestSMSCallout {
    @InvocableMethod(label='Send SMS' description='Sends SMS')
    public static void sendSMS(List<String> RCV_TXT) {
        RCV_TXT = RCV_TXT[0].split(' _ ');
        SMSCalloutQueueable queueable = new SMSCalloutQueueable(
            RCV_TXT[0],
            RCV_TXT[1],
            CRM_ApplicationDomain.Domain.HOT
        );
        System.enqueueJob(queueable);
    }
}
