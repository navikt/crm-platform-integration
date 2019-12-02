public interface IKafkaMessageHandler {

    void processMessage(List<KafkaMessage__c> messages);

}