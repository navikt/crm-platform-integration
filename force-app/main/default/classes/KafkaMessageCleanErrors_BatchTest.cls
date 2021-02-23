@IsTest
private with sharing class KafkaMessageCleanErrors_BatchTest {
    /**
     * Note that in this test we insert the kafka messages and then add the created dates. The CreatedDate and the auto number in tha name will not match and go in opposite directions
     * The first line will have created date today and a Name like KM-00001
     * The second line will have created date yesterday and a Name like KM-00002
     */
    @IsTest
    static void testCleanErrors() {
        List<KafkaMessage__c> kafkaMessageList = new List<KafkaMessage__c>();
        // Scenario: Two processed, should be skipped entirely
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'AAA',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //0
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'AAA',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //1

        // Scenario: One error, but no matcing pending, will remain as an error
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'BBB',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //2

        // Scenario: The newest is an error and the oldest is processed. The new error will remain as an error
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'CCC',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //3
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'CCC',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //4

        // Scenario: First is processed, second is error and third is processed. The error should be set to processed as a newer is handled
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'DDD',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //5
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'DDD',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //6
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'DDD',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //7

        // Scenario: The first is error and the second is procesed. The error will be set to processed
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'EEE',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //8
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'EEE',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //9

        // Scenario: Two error messages. The oldest error will be set to processed
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'FFF',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //10
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'FFF',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //11

        // Scenario: The first is error and the second is procesed. The processed has another topic so the error will remain as an error
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'GGG',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic2',
                CRM_Value__c = ''
            )
        ); //12
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'GGG',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //13

        // Scenario: The first is processed and the second is error, both have the same created date, but different auto number. The oldest error will be set to processed
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'HHH',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //14
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'HHH',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //15

        // Scenario: The first is error and the second is processes, both have the same created date, but different auto number. The new error will remains as an error
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'III',
                CRM_Status__c = KafkaMessageService.STATUS_PROCESSED,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //16
        kafkaMessageList.add(
            new KafkaMessage__c(
                CRM_Key__c = 'III',
                CRM_Status__c = KafkaMessageService.STATUS_ERROR,
                CRM_Topic__c = 'TestTopic',
                CRM_Value__c = ''
            )
        ); //17

        insert kafkaMessageList;

        for (Integer i = 0; i < kafkaMessageList.size(); i++) {
            Test.setCreatedDate(kafkaMessageList[i].Id, Datetime.now().addDays(0 - i));
        }

        Test.setCreatedDate(
            kafkaMessageList[15].Id,
            [SELECT CreatedDate FROM KafkaMessage__c WHERE Id = :kafkaMessageList[14].Id]
            .CreatedDate
        );

        Test.setCreatedDate(
            kafkaMessageList[17].Id,
            [SELECT CreatedDate FROM KafkaMessage__c WHERE Id = :kafkaMessageList[16].Id]
            .CreatedDate
        );

        System.assertEquals(
            9,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_ERROR],
            'Got the number of Error messages wrong'
        );
        System.assertEquals(
            9,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED],
            'Got the number of processed messages wrong'
        );

        Test.startTest();
        KafkaMessageCleanErrors_Batch batch = new KafkaMessageCleanErrors_Batch('TestTopic');
        Database.executeBatch(batch);
        Test.stopTest();

        System.assertEquals(
            5,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_ERROR],
            'Got the number of Error messages wrong'
        );
        System.assertEquals(
            13,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED],
            'Got the number of processed messages wrong'
        );
    }
}
