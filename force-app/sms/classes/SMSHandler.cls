public without sharing class SMSHandler extends MyTriggers {
    public override void onAfterInsert() {
        List<SMS__c> smsList = (List<SMS__c>) records;

        Integer maxNumberOfRecords = 10;
        List<SMS__c> smsList_temp = new List<SMS__c>();
        for (Integer i = 0; i < smsList.size(); i++) {
            if (smsList_temp.size() < maxNumberOfRecords && smsList[i].Type__c != 'Incoming SMS' && smsList[i].Status__c == 'Pending') {
                smsList_temp.add(smsList[i]);
            }
            if (smsList_temp.size() == maxNumberOfRecords || i == smsList.size() - 1) {
                SMSCalloutQueueable smsCalloutQueued = new SMSCalloutQueueable(
                    smsList_temp,
                    CRM_ApplicationDomain.Domain.HOT
                );
                System.enqueueJob(smsCalloutQueued);
                smsList_temp = getEmptySMSList();
            }
        }
    }
 
    public static List<SMS__c> getEmptySMSList() {
        return new List<SMS__c>();
    }
}
