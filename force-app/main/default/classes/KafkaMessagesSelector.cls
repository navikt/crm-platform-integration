public inherited sharing class KafkaMessagesSelector extends fflib_SObjectSelector {

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                KafkaMessage__c.Id,
                KafkaMessage__c.Topic__c,
                KafkaMessage__c.Message__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return KafkaMessage__c.sObjectType;
    }

    public List<KafkaMessage__c> selectById(Set<Id> ids) {
        return (List<KafkaMessage__c>)
                Database.query(
                        newQueryFactory().
                                setCondition('Id in :ids').
                                toSOQL());
    }
}


