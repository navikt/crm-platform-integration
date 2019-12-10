public interface IKafkaMessageConsumer {
    void processMessages(List<KafkaMessage__c> messages);
}