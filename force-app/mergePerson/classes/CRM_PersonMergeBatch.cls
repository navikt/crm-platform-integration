public with sharing class CRM_PersonMergeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    public String query = 'SELECT Id FROM Account WHERE IsPersonAccount= true AND CRM_Person__c = null';
    public Integer batchSize = 1;

    public CRM_PersonMergeBatch setQuery(String query) {
        this.query = query;
        return this;
    }

    public CRM_PersonMergeBatch setBatchSize(Integer batchSize) {
        this.batchSize = batchSize;
        return this;
    }

    public Id startBatch() {
        return Database.executeBatch(this, this.batchSize);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        for (Account acc : [SELECT Id, INT_PersonIdent__c FROM Account WHERE Id IN :scope AND IsDeleted = FALSE]) {
            if (String.isNotBlank(acc.INT_PersonIdent__c)) {
                CRM_PersonMerge.mergeIdent(acc.INT_PersonIdent__c);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}
