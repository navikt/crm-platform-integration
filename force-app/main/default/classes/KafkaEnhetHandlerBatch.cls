public without sharing class KafkaEnhetHandlerBatch implements Database.Batchable<SObject> {
    private final String query;

    public KafkaEnhetHandlerBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<AsyncRequest__c> scope) {
        for (AsyncRequest__c asyncRequest : scope) {
            new KafkaMessageAsyncJob().execute(asyncRequest);
        }

    }

    public void finish(Database.BatchableContext BC) {}

}