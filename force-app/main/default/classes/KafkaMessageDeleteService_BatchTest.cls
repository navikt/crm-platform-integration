@IsTest
public with sharing class KafkaMessageDeleteService_BatchTest {
    @IsTest
    public static void deleteKafkaMessagePositiveTest() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        for (Integer i = 0; i < 200; i++) {
            KafkaMessage__c msg = new KafkaMessage__c();
            msg.CRM_Key__c = String.valueOf(i);
            msg.CRM_Topic__c = 'not-a-registered-topic';
            msg.CRM_Value__c = 'some value';
            kafkaMessages.add(msg);
        }
        insert kafkaMessages;

        Integer messageCount = [SELECT COUNT() FROM KafkaMessage__c];
        System.assertEquals(200, messageCount);

        Test.startTest();
        Database.executeBatch(
            new KafkaMessageDeleteService_Batch(
                'SELECT Id FROM KafkaMessage__c'
            ),
            2000
        );
        Test.stopTest();

        messageCount = [SELECT COUNT() FROM KafkaMessage__c];
        System.assertEquals(0, messageCount);
    }

    @IsTest
    public static void dontDeleteAccountsPositiveTest() {
        insert BaseTestFactory.getAccount('Test Account 1');

        Integer messageCount = [SELECT COUNT() FROM Account];
        System.assertEquals(1, messageCount);

        Test.startTest();
        Database.executeBatch(
            new KafkaMessageDeleteService_Batch('SELECT Id FROM Account'),
            2000
        );
        Test.stopTest();

        messageCount = [SELECT COUNT() FROM Account];
        System.assertEquals(1, messageCount);
    }
}
