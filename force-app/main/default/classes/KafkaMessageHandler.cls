public inherited sharing class KafkaMessageHandler extends MyTriggers {

    public override void onAfterInsert() {
        if (!KafkaIntegrationCustomSetting.processingEnabled) return;
        insert new KafkaMessageAsyncJob().createRequests(Trigger.newMap.keySet(), 'Kafka Message');
    }

    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        Set<Id> recordsToReprocess = new Set<Id>();
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;
        for (KafkaMessage__c msg : messages) {
            if(msg.CRM_ReprocessMessage__c && !messageOldMap.get(msg.Id).CRM_ReprocessMessage__c) {
                recordsToReprocess.add(msg.Id);
            }
        }

        if (recordsToReprocess.size() > 0) {
            insert new KafkaMessageAsyncJob().createRequests(recordsToReprocess, 'Kafka Message');
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
        if (!KafkaIntegrationCustomSetting.deleteProcessedRecords) return;
        List<Id> recordsToDelete = new List<Id>();
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;
        for (KafkaMessage__c msg : messages) {
            if(msg.CRM_IsProcessed__c && !messageOldMap.get(msg.Id).CRM_IsProcessed__c) {
                recordsToDelete.add(msg.Id);
            }
        }
        if(recordsToDelete.size() > 0) {
            Database.delete(recordsToDelete);
            Database.emptyRecycleBin(recordsToDelete);
        }
    }
}