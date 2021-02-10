@IsTest
private class KafkaSkjermingRerun_ScheduleTest {
    @TestSetup
    static void makeData() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '12345678901',
                CRM_Status__c = 'Error',
                CRM_ErrorMessage__c = 'Unknown Person Ident'
            )
        );

        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '12345678902',
                CRM_Status__c = 'Error',
                CRM_ErrorMessage__c = 'Unknown Person Ident'
            )
        );

        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '1234567893',
                CRM_Status__c = 'Processed'
            )
        );
        insert kafkaMessages;
    }

    @IsTest
    private static void testBatchExecute() {
        Test.startTest();
        KafkaSkjermingRerun_Schedule btch = new KafkaSkjermingRerun_Schedule();
        Database.executeBatch(btch, 2000);
        Test.stopTest();
        System.assertEquals(
            2,
            [
                SELECT COUNT()
                FROM KafkaMessage__c
                WHERE CRM_Status__c = 'Pending'
            ],
            'Failed kafka messages should be set to pening'
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM KafkaMessage__c
                WHERE CRM_Status__c = 'Processed'
            ],
            'Processed messages should not be changed'
        );
    }

    @IsTest
    private static void testScheduleExecute() {
        Test.startTest();
        KafkaSkjermingRerun_Schedule scheduleClass = new KafkaSkjermingRerun_Schedule();
        String chron = '0 0 23 * * ?';
        System.schedule('Populate is Nav employee', chron, scheduleClass);
        Test.stopTest();
        System.assertEquals(
            1,
            [SELECT COUNT() FROM CronTrigger],
            'A job should be scheduled'
        );
    }
}
