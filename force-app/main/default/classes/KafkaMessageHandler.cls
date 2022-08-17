public inherited sharing class KafkaMessageHandler extends MyTriggers {
    /**
     * Finds and executes and filter class bound to the topic through KafkaMessageFilterBinding__mdt
     */
    public override void onAfterInsert() {
        Map<String, IKafkaMessageFilter> filterBindings = getfilterBindings(KafkaMessageHandler.filterTypes.PROCESS);

        Map<String, List<KafkaMessage__c>> messagesByTopic = sortMessagesByTopic((List<KafkaMessage__c>) records);

        Map<String, Set<Id>> recordIdsToProcessByTopic = new Map<String, Set<Id>>();
        for (String topic : messagesByTopic.keySet()) {
            if (filterBindings.containsKey(topic) && !KafkaEnhetFilter.bypassFilter) {
                recordIdsToProcessByTopic.put(
                    topic,
                    filterBindings.get(topic).filterMessages(messagesByTopic.get(topic))
                );
            } else {
                recordIdsToProcessByTopic.put(topic, new Map<Id, SObject>(messagesByTopic.get(topic)).keySet());
            }
        }

        insert createAsyncRequests(recordIdsToProcessByTopic);
    }

    /**
     * Enqueues new async request for processing if the reprocessing field is checked
     * @param triggerOldMap
     */
    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;

        Map<String, Set<Id>> recordIdsToProcessByTopic = new Map<String, Set<Id>>();
        for (KafkaMessage__c msg : messages) {
            if (
                msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING &&
                messageOldMap.get(msg.Id).CRM_Status__c != KafkaMessageService.STATUS_PENDING
            ) {
                if (recordIdsToProcessByTopic.containsKey(msg.CRM_Topic__c)) {
                    recordIdsToProcessByTopic.get(msg.CRM_Topic__c).add(msg.Id);
                } else {
                    recordIdsToProcessByTopic.put(msg.CRM_Topic__c, new Set<Id>{ msg.Id });
                }
            }
        }

        insert createAsyncRequests(recordIdsToProcessByTopic);
    }

    /**
     * Deletes processed records if enabled through custom setting
     * @param triggerOldMap old versions of the sObject records.
     */
    public override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {

        Map<String, IKafkaMessageFilter> filterBindings = getfilterBindings(KafkaMessageHandler.filterTypes.DELETE_AFTER);

        List<Id> recordsToDelete = new List<Id>();
        List<KafkaMessage__c> messages = (List<KafkaMessage__c>) records;
        Map<Id, KafkaMessage__c> messageOldMap = (Map<Id, KafkaMessage__c>) triggerOldMap;
        for (KafkaMessage__c msg : messages) {
            if (
                msg.CRM_Status__c == KafkaMessageService.STATUS_PROCESSED &&
                messageOldMap.get(msg.Id).CRM_Status__c != KafkaMessageService.STATUS_PROCESSED &&
                filterBindings.containsKey(msg.CRM_Topic__c)
            ) {
                recordsToDelete.add(msg.Id);
            }
        }
        if (recordsToDelete.size() > 0) {
            Database.delete(recordsToDelete);
            Database.emptyRecycleBin(recordsToDelete);
        }
    }

    /**
     * Instantiates AsyncRequest__c records, including setting values for the CRM_Priority__c field based on
     * priority associated with the related Kafka Message Handler Binding record for a given messages CRM_Topic__c value
     * @param recordIdsToProcessByTopic KafkaMessage record ids by their CRM_Topic__c value
     * @return List of AsyncRequest__c records to be inserted
     */
    private static List<AsyncRequest__c> createAsyncRequests(Map<String, Set<Id>> recordIdsToProcessByTopic) {
        List<AsyncRequest__c> asyncRequests = new List<AsyncRequest__c>();
        if (recordIdsToProcessByTopic.size() == 0)
            return asyncRequests;

        Map<String, KafkaMessageHandlerBinding__mdt> handlerBindingByTopic = new Map<String, KafkaMessageHandlerBinding__mdt>();
        for (KafkaMessageHandlerBinding__mdt binding : [
            SELECT Id, Topic__c, Priority__c, ApexJobType__c
            FROM KafkaMessageHandlerBinding__mdt
            WHERE Topic__c = :recordIdsToProcessByTopic.keySet()
        ]) {
            handlerBindingByTopic.put(binding.Topic__c, binding);
        }

        for (String topic : recordIdsToProcessByTopic.keySet()) {
            if (!handlerBindingByTopic.containsKey(topic)) {
                asyncRequests.addAll(
                    new KafkaMessageAsyncJob().createRequests(recordIdsToProcessByTopic.get(topic), 'Kafka Message')
                );
            } else {
                asyncRequests.addAll(
                    new KafkaMessageAsyncJob()
                        .createRequests(
                            recordIdsToProcessByTopic.get(topic),
                            'Kafka Message',
                            handlerBindingByTopic.get(topic).ApexJobType__c,
                            Integer.valueOf(handlerBindingByTopic.get(topic).Priority__c)
                        )
                );
            }
        }
        return asyncRequests;
    }

    // retrieves the current filter bindings where processing is enabled
    private Map<String, IKafkaMessageFilter> getfilterBindings(KafkaMessageHandler.filterTypes filterType){
        String query = 'SELECT Id, Topic__c, ApexClass__c FROM KafkaMessageFilterBinding__mdt';
        switch on filterType {
            when PROCESS {
                query += ' WHERE Processing_Enabled__c = true';
            }
            when DELETE_AFTER {
                query += ' WHERE Delete_Processed_Records__c = true';
            }
        }
        Map<String, IKafkaMessageFilter> filterBindings = new Map<String, IKafkaMessageFilter>();
        for (KafkaMessageFilterBinding__mdt binding : Database.query(query)) {
            filterBindings.put(
                binding.Topic__c,
                (IKafkaMessageFilter) Type.forName(binding.ApexClass__c).newInstance()
            );
        }
        return filterBindings;
    }

    private Map<String, List<KafkaMessage__c>> sortMessagesByTopic(List<KafkaMessage__c> records){
        Map<String, List<KafkaMessage__c>> messagesByTopic = new Map<String, List<KafkaMessage__c>>();
        for (KafkaMessage__c msg : records) {
            // Build map of messages by topic
            if (messagesByTopic.containsKey(msg.CRM_Topic__c)) {
                messagesByTopic.get(msg.CRM_Topic__c).add(msg);
            } else {
                messagesByTopic.put(msg.CRM_Topic__c, new List<KafkaMessage__c>{ msg });
            }
        }
        return messagesByTopic;
    }

    public enum filterTypes {
        PROCESS, DELETE_AFTER
    }
}