trigger KafkaMessage on KafkaMessage__c (before insert) {
    fflib_SObjectDomain.triggerHandler(KafkaMessages.class);
}
