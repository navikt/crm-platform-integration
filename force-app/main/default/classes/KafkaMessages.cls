public with sharing class KafkaMessages extends fflib_SObjectDomain {

    public KafkaMessages(List<KafkaMessage__c> kafkaMessages) {
        super(kafkaMessages);
    }

    public override void onAfterInsert() {
        BrregParser parser = new BrregParser();
        new KafkaMessageParsingService().parseMessage(parser, Records);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new KafkaMessages(sObjectList);
        }
    }


}