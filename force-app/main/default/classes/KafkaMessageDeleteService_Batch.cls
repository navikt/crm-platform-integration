public inherited sharing class KafkaMessageDeleteService_Batch implements Database.Batchable<sObject> {
    public final String query;

    public KafkaMessageDeleteService_Batch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    // Specifying KafkaMessage__c as scope prevents deletion of other types of sObjects
    // even if specified by query. This class should only be used to delete KafkaMessages.
    public void execute(
        Database.BatchableContext BC,
        List<KafkaMessage__c> scope
    ) {
        delete scope;
        Database.emptyRecycleBin(scope);
    }

    public void finish(Database.BatchableContext BC) {
    }
}
