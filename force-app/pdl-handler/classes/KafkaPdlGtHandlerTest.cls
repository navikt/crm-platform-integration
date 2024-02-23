@IsTest
private with sharing class KafkaPdlGtHandlerTest {

    @isTest
    static void testCreatePersonFromGt() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.geografisktilknytning-v1',
                CRM_Key__c = '1017419408436',
                //{
                //  "identer": [
                //    "1017419408436",
                //    "74194084361"
                //  ],
                //  "geografiskTilknytning": {
                //    "gtType": "KOMMUNE",
                //    "gtKommune": "1337",
                //    "gtBydel": null,
                //    "gtLand": null,
                //    "regel": "2"
                //  }
                //}
                CRM_Value__c = 'eyJpZGVudGVyIjpbIjEwMTc0MTk0MDg0MzYiLCI3NDE5NDA4NDM2MSJdLCJnZW9ncmFmaXNrVGlsa255dG5pbmciOnsiZ3RUeXBlIjoiS09NTVVORSIsImd0S29tbXVuZSI6IjEzMzciLCJndEJ5ZGVsIjpudWxsLCJndExhbmQiOm51bGwsInJlZ2VsIjoiMiJ9fQo=',
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(kafkaMessages);
        Test.stopTest();
        List<Person__c> pl = [SELECT Id from Person__c where INT_ActorId__c = '1017419408436'];
        Assert.areEqual(1, pl.size(), 'Expected one person inserted.');
    }
}
