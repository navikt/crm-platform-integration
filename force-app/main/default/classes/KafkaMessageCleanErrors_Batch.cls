/**
 * Batch class for cleaning the Kafka error messages within a topic.
 * 1. Collect all error messages of a topic within a specific time frame in an ordered list
 * 2. It will check for duplicate errors (just within the execution).
 * 3. Based on the unique keys it will query for processed messages with the same keys and topic
 * 4. Compare the processed and error message created dates. If the procesad message is newer it will set the error to Processed
 * 5. Update the messages set to Processed.
 */
public with sharing class KafkaMessageCleanErrors_Batch implements Database.Batchable<sObject>, Database.Stateful {
    private String topic;
    private DateTime fromDateTime;
    private DateTime toDateTime;

    public KafkaMessageCleanErrors_Batch(
        String topic,
        Datetime fromDateTime,
        Datetime toDateTime
    ) {
        this.topic = topic;
        this.fromDateTime = fromDateTime;
        this.toDateTime = toDateTime;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, Name, CRM_Key__c, CreatedDate
                FROM KafkaMessage__c
                WHERE
                    CreatedDate >= :fromDateTime
                    AND CreatedDate <= :toDateTime
                    AND CRM_Status__c = :KafkaMessageService.STATUS_ERROR
                    AND CRM_Topic__c = :topic
                ORDER BY CreatedDate DESC, Name DESC
            ]
        );
    }

    public void execute(
        Database.BatchableContext bc,
        List<KafkaMessage__c> scope
    ) {
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

            if (messageMap.get(crmKey).CreatedDate < createdDate) {
                messageMap.get(crmKey)
                    .CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
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

    private List<AggregateResult> getProcessedMessages(Set<String> keySet) {
        return [
            SELECT CRM_KEY__c, MAX(CreatedDate) CreatedDate
            FROM KafkaMessage__c
            WHERE
                CRM_Key__c IN :keySet
                AND CRM_Topic__c = :topic
                AND CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED
            GROUP BY CRM_KEY__c
        ];
    }
}
