public inherited sharing class KafkaMessageInsertHandler extends MyTriggers {

    public override void onAfterInsert() {
        insert new KafkaMessageAsyncJob().createRequests(Trigger.newMap.keySet(), 'Kafka Message');
    }

    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        Set<Id> recordsToReprocess = new Set<Id>();


        for (SObject msg : records) {
            if (MyTriggers.hasChangedFields(new String[]{
                    'CRM_ReprocessMessage__c'
            }, msg, triggerOldMap.get(msg.Id))
                    && msg.get('CRM_ReprocessMessage__c') == true) {
                recordsToReprocess.add(msg.Id);
            }
        }

        if (recordsToReprocess.size() > 0) {
            insert new KafkaMessageAsyncJob().createRequests(recordsToReprocess, 'Kafka Message');
        }
    }
}