public inherited sharing class KafkaMessageDeletionBatch implements Database.Batchable<sObject> {
    private Map<String, Decimal> topicToStorageTime = new Map<String, Decimal>();
    private Set<Id> messagesToDelete = new Set<Id>();
    private Map<Id, String> idToTopic = new Map<Id, String>();
    private CRM_DatabaseOperations cdo = new CRM_DatabaseOperations();

    public Database.QueryLocator start(Database.BatchableContext BC) { 
        Decimal maxStorageTime = getMaxStorageTime();  
        String query = 'SELECT ParentId, CreatedDate FROM KafkaMessage__History WHERE Field=\'CRM_Status__c\' AND NewValue=\'Processed\' AND OldValue!=\'Processed\' AND CreatedDate > ' + maxStorageTime  + ' ORDER BY CreatedDate';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<KafkaMessage__History> scope) {
        for(KafkaMessage__History kmh : scope){
            Datetime currentStorageTime = Datetime.now() - topicToStorageTime.get(idToTopic.get(kmh.ParentId));
            if(kmh.CreatedDate < currentStorageTime) messagesToDelete.add(kmh.ParentId);
        }
    }

    public void finish(Database.BatchableContext BC) {
        cdo.deleteRecords(messagesToDelete); //depending on how many records there are to delete, it might make sense to move this into the execute method. But hopefully with daily execution of the batch, we should be fine. Especially as some projects are migrating away from Kafka Messages.
    }


    // Get the maximum storage timeand populate the topic to storage time map as well as the id to topic map
    //!! If there is a massive amount of unhandled messages, this method might still break Salesforce Limits
    private Decimal getMaxStorageTime(){
        List<KafkaMessageHandlerBinding__mdt> handlerBindings = [SELECT Id, Topic__c, ApexClass__c, Storage_Time__c FROM KafkaMessageHandlerBinding__mdt WHERE Delete_Processed_Records__c = true AND Storage_Time__c > 0];
        Set<String> topics = new Set<String>();
        Decimal maxStorageTime = 0;
        for(KafkaMessageHandlerBinding__mdt khb : handlerBindings){
            maxStorageTime = maxStorageTime < khb.Storage_Time__c ? khb.Storage_Time__c : maxStorageTime;
            topicToStorageTime.put(khb.Topic__c, khb.Storage_Time__c);
            topics.add(khb.Topic__c);
        }
        Datetime maxStorageTimeDate = Datetime.now() - maxStorageTime;
        List<KafkaMessage__c> deletionCandidates = [SELECT Id, CRM_Topic__c FROM KafkaMessage__c WHERE CreatedDate >= :maxStorageTimeDate AND CRM_Topic__c IN :topics];
        for(KafkaMessage__c kfm : deletionCandidates){
            idToTopic.put(kfm.Id, kfm.CRM_Topic__c);
        }
        return maxStorageTime;
    }
}
