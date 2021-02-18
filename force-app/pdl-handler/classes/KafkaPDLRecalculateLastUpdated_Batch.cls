/**
 * Batch class for setting INT_LastUpdatedFromPDL__c on Person__c based on Processed Messages.
 * 1. Collect all processed kafka messages of a PDL topic within a specific time frame in an ordered list
 * 2. Check for duplicate messages based on aktoer_id (just within the execution).
 * 3. Query all Person__c records based on the aktoer_id that do not have INT_LastUpdatedFromPDL__c
 * 4. Iterate over all returned persons and set INT_LastUpdatedFromPDL__c
 * 5. Update all the persons
 */
public with sharing class KafkaPDLRecalculateLastUpdated_Batch implements Database.Batchable<sObject> {
    private String topic;
    private DateTime fromDateTime;
    private DateTime toDateTime;

    public KafkaPDLRecalculateLastUpdated_Batch(String topic, Datetime fromDateTime, Datetime toDateTime) {
        this.topic = topic;
        this.fromDateTime = fromDateTime;
        this.toDateTime = toDateTime;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT Id, CRM_Key__c, CreatedDate
                FROM KafkaMessage__c
                WHERE
                    CRM_Topic__c = :topic
                    AND CreatedDate >= :fromDateTime
                    AND CreatedDate <= :toDateTime
                    AND CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED
                ORDER BY CreatedDate DESC, Name DESC
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<KafkaMessage__c> scope) {
        Map<String, Datetime> createdDateMap = new Map<String, Datetime>();

        for (KafkaMessage__c msg : scope) {
            String decodedValue = KafkaMessageUtils.base64ULSafeDecode(msg.CRM_Key__c).toString();
            Key key = (Key) System.JSON.deserialize(decodedValue, Key.class);

            if (createdDateMap.containsKey(key.aktoer_id)) {
                continue;
            }

            createdDateMap.put(key.aktoer_id, msg.CreatedDate);
        }

        List<Person__c> persons = getPersons(createdDateMap.keySet());

        if (0 < persons.size()) {
            for (Person__c p : persons) {
                p.INT_LastUpdatedFromPDL__c = createdDateMap.get(p.INT_ActorId__c);
            }

            update persons;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('KafkaPDLRecalculatePersonLastUpdated_Batch END');
    }

    private List<Person__c> getPersons(Set<String> actorIds) {
        return [
            SELECT Id, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :actorIds AND INT_LastUpdatedFromPDL__c = NULL
        ];
    }

    private class Key {
        Boolean tombstone;
        String aktoer_id;
    }
}
