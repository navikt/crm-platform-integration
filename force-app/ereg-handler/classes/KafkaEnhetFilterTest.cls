@IsTest
public with sharing class KafkaEnhetFilterTest {
    @IsTest
    private static void kafkaEnhetFilterPositiveTest() {
        KafkaEnhetFilter.maxOrganizationsAllowed = 100;

        // Assert that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        // Load 200 KafkaMessage records from static resource CSV. Use start/stoptest to ensure handling through queuable framework.
        Test.startTest();
        Test.loadData(KafkaMessage__c.sObjectType, 'KafkaMessage_Test_Data_Enhetsregisteret');
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        // Assert that 200 Accounts have been inserted
        System.assertEquals(100, [SELECT COUNT() FROM Account]);
        // Assert that all Kafka Message records have been marked as processed
        System.assertEquals(
            100,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]
        );
    }

    @IsTest
    private static void kafkaEnhetFilterNegativeTest() {
        KafkaEnhetFilter.maxOrganizationsAllowed = 50;

        // Assert that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        // Load 200 KafkaMessage records from static resource CSV. Use start/stoptest to ensure handling through queuable framework.
        Test.startTest();
        Test.loadData(KafkaMessage__c.sObjectType, 'KafkaMessage_Test_Data_Enhetsregisteret');
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        // Assert that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Account]);
        // Assert that no records have been marked as processed
        System.assertEquals(
            0,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]
        );
    }
}
