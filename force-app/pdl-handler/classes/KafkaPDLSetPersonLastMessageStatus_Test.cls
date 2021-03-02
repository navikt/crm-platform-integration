@IsTest
private inherited sharing class KafkaPDLSetPersonLastMessageStatus_Test {
    @IsTest
    static void KafkaPDLSetPersonLastMessageStatusTest() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now().addDays(-1);
        person1.INT_MunicipalityNumber__c = '123';

        Person__c person2 = new Person__c();
        person2.INT_ActorId__c = '1000012345600';
        person2.Name = '20000000001';
        person2.INT_LastUpdatedFromPDL__c = Datetime.now().addDays(-1);
        person2.INT_MunicipalityNumber__c = '1234';

        insert new List<Person__c>{ person1, person2 };

        List<KafkaMessage__c> kafkaMessageList = new List<KafkaMessage__c>();

        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //0
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //1
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //2
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //3
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345600","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //4

        insert kafkaMessageList;

        Test.setCreatedDate(kafkaMessageList[0].Id, Datetime.now().addDays(-4));
        Test.setCreatedDate(kafkaMessageList[1].Id, Datetime.now().addDays(-3));
        Test.setCreatedDate(kafkaMessageList[2].Id, Datetime.now().addDays(-2));
        Test.setCreatedDate(kafkaMessageList[3].Id, Datetime.now().addDays(-1));
        Test.setCreatedDate(kafkaMessageList[4].Id, Datetime.now().addDays(-1));

        Test.startTest();
        KafkaPDLSetPersonLastMessageStatus_Batch batch = new KafkaPDLSetPersonLastMessageStatus_Batch(
            'SELECT Id, INT_ActorId__c FROM Person__c WHERE INT_MunicipalityNumber__c Like \'___\'',
            'TestTopic',
            KafkaMessageService.STATUS_ERROR
        );
        Database.executeBatch(batch);
        Test.stopTest();

        System.AssertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            [SELECT Id, CRM_Status__c FROM KafkaMessage__c WHERE Id = :kafkaMessageList[4].Id]
            .CRM_Status__c,
            'Expected that the message status was not changed.'
        );
        System.AssertEquals(
            KafkaMessageService.STATUS_ERROR,
            [SELECT Id, CRM_Status__c FROM KafkaMessage__c WHERE Id = :kafkaMessageList[3].Id]
            .CRM_Status__c,
            'Expected that the message had been set to Error.'
        );
    }
}
