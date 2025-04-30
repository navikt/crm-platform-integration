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

    public override void onAfterUpdate(Map<Id, sObject> triggerOldMap) {
        List<SMS__c> smsToUpdate = new List<SMS__c>();
        List<SMS__c> smsList_temp = new List<SMS__c>();

        for (SMS__c sms : (List<SMS__c>) records) {
            SMS__c oldSMS = (SMS__c) triggerOldMap.get(sms.Id);

            if (
                sms.Status__c == 'Pending' &&
                sms.Type__c != 'Incoming SMS' &&
                oldSMS.Status__c == 'Could not send' &&
                sms.Recipient__c != null &&
                sms.AttemptsToSendAfterFirstFail__c <= 3
            ) {
                smsList_temp.add(sms);
                SMS__c smsToChange = new SMS__c(
                Id = sms.Id,
                AttemptsToSendAfterFirstFail__c = sms.AttemptsToSendAfterFirstFail__c + 1
            );
                smsToUpdate.add(smsToChange);
            }
            if (smsList_temp.size() == MAX_BATCH_SIZE) {
                System.enqueueJob(new SMSCalloutQueueable(new List<SMS__c>(smsList_temp)));
                smsList_temp.clear();
            }
        }
        if (!smsList_temp.isEmpty()) {
            System.enqueueJob(new SMSCalloutQueueable(smsList_temp));
        }
        if (!smsToUpdate.isEmpty()) {
            update smsToUpdate;
        }
    }
}
