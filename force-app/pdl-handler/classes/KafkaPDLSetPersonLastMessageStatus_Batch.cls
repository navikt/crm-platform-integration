public inherited sharing class KafkaPDLSetPersonLastMessageStatus_Batch implements Database.Batchable<sObject>, Database.Stateful {
    private String personQuery;
    private String topic;
    private String newStatus;

    public KafkaPDLSetPersonLastMessageStatus_Batch(String personQuery, String topic, String newStatus) {
        this.personQuery = personQuery;
        this.topic = topic;
        this.newStatus = newStatus;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.personQuery);
    }

    public void execute(Database.BatchableContext bc, List<Person__c> scope) {
        Set<String> keySet = new Set<String>();
        for (Person__c p : scope) {
            keySet.add(
                EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"' + p.INT_ActorId__c + '","tombstone":false}'))
            );
            keySet.add(
                EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"' + p.INT_ActorId__c + '","tombstone":true}'))
            );
        }

        Map<String, KafkaMessage__c> messageMap = new Map<String, KafkaMessage__c>();

        for (KafkaMessage__c msg : [
            SELECT Id, CRM_Key__c, CRM_Status__c
            FROM KafkaMessage__c
            WHERE CRM_Topic__c = :this.topic AND CRM_Key__c IN :keySet
            ORDER BY CreatedDate DESC, Name DESC
        ]) {
            if (messageMap.containsKey(msg.CRM_Key__c)) {
                continue;
            }

            msg.CRM_Status__c = newStatus;
            messageMap.put(msg.CRM_Key__c, msg);
        }

        update messageMap.values();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('KafkaPDLSetPersonLastMessageStatus_Batch END');
    }
}
