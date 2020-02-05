public interface IKafkaMessageFilter {
    Set<Id> filterMessages(List<KafkaMessage__c> messages);
}