public without sharing class SMSHandler extends MyTriggers {
    
    public override void onBeforeInsert() {
        List<SMS__c> SMSs = (List<SMS__c>) records;

        Integer maxNumberOfRecords = 10;
        List<SMS__c> SMSs_temp = new List<SMS__c>();
        for(SMS__c sms : SMSs){
            if(SMSs_temp.size()<maxNumberOfRecords){
                SMSs_temp.add(sms);
            }
            if(SMSs_temp.size() == maxNumberOfRecords || SMSs.get(SMSs.size()-1) == sms){
                SMSCalloutQueueable smsCalloutQueued = new SMSCalloutQueueable(SMSs_temp, CRM_ApplicationDomain.Domain.HOT);
                System.enqueueJob(smsCalloutQueued);
                SMSs_temp = getEmptySMSList();
            }
        }
    }

    public static List<SMS__c> getEmptySMSList(){
        return new List<SMS__c>();
    }
}
