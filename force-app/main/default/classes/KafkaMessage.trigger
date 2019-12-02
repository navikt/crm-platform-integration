trigger KafkaMessage on KafkaMessage__c (after insert) {
    fflib_SObjectDomain.triggerHandler(KafkaMessages.class);
}
