public without sharing class SMSHandler extends MyTriggers {
    private static final Integer MAX_BATCH_SIZE = 10;
    public override void onAfterInsert() {
        List<SMS__c> smsList = (List<SMS__c>) records;

        List<SMS__c> smsList_temp = new List<SMS__c>();

        for (SMS__c sms : smsList) {
            if (sms.Type__c != 'Incoming SMS' && sms.Status__c == 'Pending') {
                smsList_temp.add(sms);
            }

            if (smsList_temp.size() == MAX_BATCH_SIZE) {
                System.enqueueJob(new SMSCalloutQueueable(new List<SMS__c>(smsList_temp)));
                smsList_temp.clear();
            }
        }

        if (!smsList_temp.isEmpty()) {
            System.enqueueJob(new SMSCalloutQueueable(smsList_temp));
        }
    }
}
