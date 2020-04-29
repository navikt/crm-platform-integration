public inherited sharing class KafkaMessageHandler extends MyTriggers {

    /**
     * Finds and executes and filter class bound to the topic through KafkaMessageFilterBinding__mdt
     */
    public override void onAfterInsert() {
        Map<String, IKafkaMessageFilter> filterBindings = new Map<String, IKafkaMessageFilter>();
        for (KafkaMessageFilterBinding__mdt binding : [SELECT Id, Topic__c, ApexClass__c FROM KafkaMessageFilterBinding__mdt]) {
            filterBindings.put(binding.Topic__c, (IKafkaMessageFilter) Type.forName(binding.ApexClass__c).newInstance());
        }

        Map<String, List<KafkaMessage__c>> messagesByTopic = new Map<String, List<KafkaMessage__c>>();
        for (KafkaMessage__c msg : (List<KafkaMessage__c>) records) {
            // Build map of messages by topic
            if (messagesByTopic.containsKey(msg.CRM_Topic__c)) {
                messagesByTopic.get(msg.CRM_Topic__c).add(msg);
            } else {
                messagesByTopic.put(msg.CRM_Topic__c, new List<KafkaMessage__c>{
                        msg
                });
            }
        }

        Set<Id> recordIdsToProcess = new Set<Id>();
        for (String topic : messagesByTopic.keySet()) {
            if (filterBindings.containsKey(topic) && !KafkaEnhetFilter.bypassFilter) {
                recordIdsToProcess.addAll(filterBindings.get(topic).filterMessages(messagesByTopic.get(topic)));
            } else {
                recordIdsToProcess.addAll(new Map<Id, SObject>(messagesByTopic.get(topic)).keySet());
            }
        }

        if (!KafkaIntegrationCustomSetting.processingEnabled || recordIdsToProcess.size() == 0) return;
        insert new KafkaMessageAsyncJob().createRequests(recordIdsToProcess, 'Kafka Message');
    }


    /**
     * Enqueues new async request for processing if the reprocesing field is checked
     * @param triggerOldMap
     */
    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        Set<Id> recordsToReprocess = new Set<Id>();
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_ReprocessMessage__c && !messageOldMap.get(msg.Id).CRM_ReprocessMessage__c) {
                recordsToReprocess.add(msg.Id);
            }
        }

        if (recordsToReprocess.size() > 0) {
            insert new KafkaMessageAsyncJob().createRequests(recordsToReprocess, 'Kafka Message');
        }
    }

    /**
     * Deletes processed records if enabled through custom setting
     * @param triggerOldMap old versions of the sObject records.
     */
    public override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
        if (!KafkaIntegrationCustomSetting.deleteProcessedRecords) return;
        List<Id> recordsToDelete = new List<Id>();
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_IsProcessed__c && !messageOldMap.get(msg.Id).CRM_IsProcessed__c) {
                recordsToDelete.add(msg.Id);
            }
        }
        if (recordsToDelete.size() > 0) {
            Database.delete(recordsToDelete);
            Database.emptyRecycleBin(recordsToDelete);
        }
    }
}