public inherited sharing class KafkaMessageInsertHandler extends MyTriggers {
    public override void onBeforeInsert() {
        new KafkaMessageService(records).handleMessages();
    }

    public override void onBeforeUpdate(Map<Id, SObject> triggerOldMap) {
        List<SObject> recordsToReprocess = new List<SObject>();
        for (SObject msg : records) {
            if (MyTriggers.hasChangedFields(new String[]{
                    'ReprocessMessage__c'
            }, msg, triggerOldMap.get(msg.Id))) {
                recordsToReprocess.add(msg);
            }
        }

        if (recordsToReprocess.size() > 0) {
            new KafkaMessageService(recordsToReprocess).handleMessages();
        }
    }
}