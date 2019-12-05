public inherited sharing class KafkaMessageInsertHandler extends MyTriggers {
    public override void onBeforeInsert() {
        new KafkaMessageService(records).handleMessages();
    }
}