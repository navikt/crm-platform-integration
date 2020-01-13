@IsTest
public with sharing class KafkaMessageServiceTest {

    @IsTest private static void handleMessagesPositiveTest() {
        KafkaMessage__c msg = new KafkaMessage__c();
        msg.CRM_Topic__c = 'BRREG';
        msg.CRM_Key__c = '12345';
        msg.CRM_Value__c = 'Hello';
        insert msg;

        System.assertEquals(false, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);

        Test.startTest();
        new KafkaMessageService(new List<KafkaMessage__c>{msg}).handleMessages();
        Test.stopTest();

        System.assertEquals(true, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);
    }

    @IsTest private static void handleMessagesNegativeTest() {
        KafkaMessage__c msg = new KafkaMessage__c();
        msg.CRM_Topic__c = 'NOT A VALID TOPIC';
        msg.CRM_Key__c = '12345';
        msg.CRM_Value__c = 'Hello';
        insert msg;

        KafkaMessage__c insertedMsg = [SELECT Id, CRM_IsProcessed__c, CRM_Error__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1];
        System.assertEquals(insertedMsg.CRM_IsProcessed__c, false);
        System.assert(String.isBlank(insertedMsg.CRM_Error__c));

        Test.startTest();
        new KafkaMessageService(new List<KafkaMessage__c>{msg}).handleMessages();
        Test.stopTest();

        insertedMsg = [SELECT Id, CRM_IsProcessed__c, CRM_Error__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1];
        System.assertEquals(insertedMsg.CRM_IsProcessed__c, false);
        System.assert(!String.isBlank(insertedMsg.CRM_Error__c));
    }
}