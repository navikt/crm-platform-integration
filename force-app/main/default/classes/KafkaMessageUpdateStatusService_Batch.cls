public inherited sharing class KafkaMessageUpdateStatusService_Batch implements Database.Batchable<sObject> {

    public final String query;
    public final String status;

    public KafkaMessageUpdateStatusService_Batch(String query, String status) {
        this.query = query;
        this.status = status;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<KafkaMessage__c> scope) {
        for(KafkaMessage__c msg : scope) {
            msg.CRM_Status__c = status;
        }
        update scope;
    }

    public void finish(Database.BatchableContext BC) {
    }

}