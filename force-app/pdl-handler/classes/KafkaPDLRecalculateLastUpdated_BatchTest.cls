@IsTest
private with sharing class KafkaPDLRecalculateLastUpdated_BatchTest {
    @TestSetup
    static void makeData() {
        List<Person__c> personList = new List<Person__c>();
        personList.add(
            new Person__c(
                Name = '16022801450',
                INT_ActorId__c = '2499286497340',
                INT_LastName__c = 'Test0',
                INT_LastUpdatedFromPDL__c = DateTime.Now()
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801451',
                INT_ActorId__c = '2499286497341',
                INT_LastName__c = 'Test1',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801452',
                INT_ActorId__c = '2499286497342',
                INT_LastName__c = 'Test2',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801453',
                INT_ActorId__c = '2499286497343',
                INT_LastName__c = 'Test3',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801454',
                INT_ActorId__c = '2499286497344',
                INT_LastName__c = 'Test4',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801455',
                INT_ActorId__c = '2499286497345',
                INT_LastName__c = 'Test5',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        personList.add(
            new Person__c(
                Name = '16022801456',
                INT_ActorId__c = '2499286497346',
                INT_LastName__c = 'Test6',
                INT_LastUpdatedFromPDL__c = null
            )
        );
        insert personList;
    }
    @IsTest
    static void testRecalculate() {
        List<KafkaMessage__c> kafkaMessageList = new List<KafkaMessage__c>();

        //Scenario: Two processed messages that matches one Person__c without INT_LastUpdatedFromPDL__c. The person should have a created date matching the first processed message
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497341","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //0
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497341","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //1

        //Scenario: Two messages, one processed and one error, that matches one Person__c without INT_LastUpdatedFromPDL__c. The person should have a created date matching the processed message even if the error is newer
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497342","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //2
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497342","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //3

        //Scenario: Two processed messages that matches one Person__c without INT_LastUpdatedFromPDL__c. One have a tombstone. The first should be set.
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497345","tombstone":true}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //4
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497345","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //5

        //Scenario: On processed created today that matches one that already has an update.
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"2499286497340","tombstone":false}')),
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //6
        insert kafkaMessageList;

        for (Integer i = 0; i < kafkaMessageList.size(); i++) {
            Test.setCreatedDate(kafkaMessageList[i].Id, Datetime.now().addDays(0 - i));
        }

        Test.startTest();
        KafkaPDLRecalculateLastUpdated_Batch batch = new KafkaPDLRecalculateLastUpdated_Batch(
            'TestTopic',
            DateTime.now().addDays(-100),
            DateTime.now()
        );
        Database.executeBatch(batch);
        Test.stopTest();

        List<Person__c> persons = [SELECT Id FROM Person__c];

        System.assertEquals(
            3,
            [SELECT COUNT() FROM Person__c WHERE INT_LastUpdatedFromPDL__c = NULL],
            'Did not expect any persons where the last updated data is not set'
        );
        System.assertEquals(
            4,
            [SELECT COUNT() FROM Person__c WHERE INT_LastUpdatedFromPDL__c != NULL],
            'Expect 10 persons where the last updated data is set'
        );
        System.assertEquals(
            [SELECT CreatedDate FROM KafkaMessage__c WHERE Id = :kafkaMessageList[0].Id]
            .CreatedDate,
            [SELECT INT_LastUpdatedFromPDL__c FROM Person__c WHERE INT_ActorId__c = :'2499286497341']
            .INT_LastUpdatedFromPDL__c,
            'Expected CreatedDate to match INT_LastUpdatedFromPDL__c'
        );
        System.assertEquals(
            [SELECT CreatedDate FROM KafkaMessage__c WHERE Id = :kafkaMessageList[3].Id]
            .CreatedDate,
            [SELECT INT_LastUpdatedFromPDL__c FROM Person__c WHERE INT_ActorId__c = :'2499286497342']
            .INT_LastUpdatedFromPDL__c,
            'Expected CreatedDate to match INT_LastUpdatedFromPDL__c'
        );
        System.assertEquals(
            [SELECT CreatedDate FROM KafkaMessage__c WHERE Id = :kafkaMessageList[4].Id]
            .CreatedDate,
            [SELECT INT_LastUpdatedFromPDL__c FROM Person__c WHERE INT_ActorId__c = :'2499286497345']
            .INT_LastUpdatedFromPDL__c,
            'Expected CreatedDate to match INT_LastUpdatedFromPDL__c'
        );
    }
}
