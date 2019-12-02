public interface IKafkaMessageHandler {

    void processMessages(List<KafkaMessage__c> messages);

}