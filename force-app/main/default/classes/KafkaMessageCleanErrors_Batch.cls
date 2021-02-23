/**
 * Batch class for cleaning the Kafka messages within a topic.
 * 1. Collect all messages of a topic and status in an ordered list
 * 2. It will check for duplicate messages (just within the execution).
 * 3. Based on the unique keys it will query for processed messages with the same keys and topic
 * 4. Compare the processed and message created dates and auto numbers. If the processed message is newer it will set the message to Processed
 * 5. Update the messages set to Processed.
 */
public with sharing class KafkaMessageCleanErrors_Batch implements Database.Batchable<sObject>, Database.Stateful {
    private String topic;
    private String status;

    public KafkaMessageCleanErrors_Batch(String topic) {
        this(topic, KafkaMessageService.STATUS_ERROR);
    }

    public KafkaMessageCleanErrors_Batch(String topic, String status) {
        this.topic = topic;
        this.status = status;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Name, CRM_Key__c, CreatedDate
                FROM KafkaMessage__c
                WHERE CRM_Status__c = :status AND CRM_Topic__c = :topic
                ORDER BY CreatedDate DESC, Name DESC
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<KafkaMessage__c> scope) {
        List<KafkaMessage__c> messagesToClose = new List<KafkaMessage__c>();
        Map<String, KafkaMessage__c> messageMap = new Map<String, KafkaMessage__c>();

        for (KafkaMessage__c message : scope) {
            if (messageMap.containsKey(message.CRM_Key__c)) {
                message.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                messagesToClose.add(message);
                continue;
            }

            messageMap.put(message.CRM_Key__c, message);
        }

        for (AggregateResult ar : getProcessedMessages(messageMap.keySet())) {
            Datetime createdDate = (DateTime) ar.get('CreatedDate');
            String crmKey = (String) ar.get('CRM_Key__c');
            Integer autoNumber = getAutoNumber((String) ar.get('Name'));

            if (
                (messageMap.get(crmKey).CreatedDate < createdDate) ||
                (messageMap.get(crmKey).CreatedDate == createdDate &&
                getAutoNumber(messageMap.get(crmKey).Name) < autoNumber)
            ) {
                messageMap.get(crmKey).CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                messagesToClose.add(messageMap.get(crmKey));
            }
        }

        if (0 < messagesToClose.size()) {
            update messagesToClose;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('KafkaMessageCleanErrors_Batch END');
    }

    private Integer getAutoNumber(string autoNumber) {
        return Integer.valueOf(autoNumber.split('-')[1]);
    }

    private List<AggregateResult> getProcessedMessages(Set<String> keySet) {
        return [
            SELECT CRM_KEY__c, MAX(CreatedDate) CreatedDate, MAX(Name) Name
            FROM KafkaMessage__c
            WHERE
                CRM_Key__c IN :keySet
                AND CRM_Topic__c = :topic
                AND CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED
            GROUP BY CRM_KEY__c
        ];
    }
}
