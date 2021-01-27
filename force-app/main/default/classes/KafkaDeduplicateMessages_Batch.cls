/**
 * Batch class for deduplicating Kafka messages with the same key, topic and status
 * The batch is stateful and keeps keys in a set
 * 
 * SCOPE:
 * All KafkaMessage__c records of the specified CRM_Status__c and CRM_Topic__c ordered by Name
 * By ordering the scope by Name (Autonumber) and Ascending we are sure to iterate over them in the order they were entered into Salesforce
 * 
 * EXECUTION:
 * Iterate over the messages in the scope and compare them to the messages in the stateful set keySet
 * If the message key does not exist in keySet add the message to the set
 * If the message key does exist in keySet set it to Processed
 * At the end of the execution, if any, update the messages set to Processed
 * 
 */
public with sharing class KafkaDeduplicateMessages_Batch implements Database.Batchable<sObject>, Database.Stateful {
    private String status;
    private String topic;
    @TestVisible private Set<String> keySet;

    /**
     * Constructor for setting the status and topic and the stateful params
     * @param status the Kafka message status
     * @param topic the Kafka topic
     */
    public KafkaDeduplicateMessages_Batch(String status, String topic) {
        this.status = status;
        this.topic = topic;
        keySet = new Set<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,
                                                CRM_Key__c
                                            FROM KafkaMessage__c
                                            WHERE CRM_Status__c = :status
                                                AND CRM_Topic__c = :topic
                                                ORDER BY Name ASC]);
    }

    public void execute(Database.BatchableContext bc, List<KafkaMessage__c> scope) {
        List<KafkaMessage__c> messagesToClose = new List<KafkaMessage__c>();

        for(KafkaMessage__c message : scope) {
            if(keySet.contains(message.CRM_Key__c)) {
                message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                messagesToClose.add(message);
            } else {
                keySet.add(message.CRM_Key__c);
            }
        }

        if(messagesToClose.size() > 0) {
            update messagesToClose;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('KafkaDeduplicateMessages_Batch END');
    }
}
