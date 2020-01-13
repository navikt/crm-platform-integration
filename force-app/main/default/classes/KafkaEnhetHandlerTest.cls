@IsTest
public with sharing class KafkaEnhetHandlerTest {
    @IsTest private static void processMessagesTest() {
        // Query for JSON payload uploaded as static resource
        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'BRREG_Test_Data_1'];
        // Create and insert a Kafka Message record with the JSON payload as value
        KafkaMessage__c msg = new KafkaMessage__c();
        msg.CRM_Topic__c = 'BRREG';
        msg.CRM_Key__c = '12345';
        msg.CRM_Value__c = sr.Body.toString();
        insert msg;

        System.assertEquals(0, [SELECT COUNT() FROM Account]);
        System.assertEquals(false, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);

        // Process message
        Test.startTest();
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{
                msg
        });
        Test.stopTest();

        System.assertEquals(100, [SELECT COUNT() FROM Account]);
        System.assertEquals(true, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);
    }
}