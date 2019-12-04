public inherited sharing class ConsumeKafkaMessageHandler extends MyTriggers {

    public override void onBeforeInsert() {
        new KafkaMessageService(records).handleMessages();
    }

}