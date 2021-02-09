@IsTest
private with sharing class KafkaDeduplicateMessages_BatchTest {
    @IsTest static void testExecute() {
        
        List<KafkaMessage__c> messages = new List<KafkaMessage__c>();

        //Messages to test
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1231', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1232', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1233', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1234', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1235', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1231', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1232', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1233', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1234', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1235', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1231', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1232', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1233', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1234', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        messages.add(new KafkaMessage__c(CRM_Key__c = 'Test1235', CRM_Topic__c = 'TestTopic', CRM_Status__c = KafkaMessageService.STATUS_ERROR));
        
        insert messages;
        
        Test.startTest();
        KafkaDeduplicateMessages_Batch batch = new KafkaDeduplicateMessages_Batch(KafkaMessageService.STATUS_ERROR,'TestTopic');
        
        //Add one to test the statefull message
        batch.keySet.add('Test1231');
        
        //Run the batch
        Database.executeBatch(batch, messages.size());
        Test.stopTest();

        System.assertEquals(4, [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Topic__c = 'TestTopic' AND CRM_Status__c = :KafkaMessageService.STATUS_ERROR], 'Expected 4 messages left on error');
        System.assertEquals(11, [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Topic__c = 'TestTopic' AND CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED], 'Expected 11 messages set to processed');

        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[0].Id].CRM_Status__c, 'Expected the 1st message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[1].Id].CRM_Status__c, 'Expected the 2nd message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[2].Id].CRM_Status__c, 'Expected the 3rd message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[3].Id].CRM_Status__c, 'Expected the 4th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[4].Id].CRM_Status__c, 'Expected the 5th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[5].Id].CRM_Status__c, 'Expected the 6th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[6].Id].CRM_Status__c, 'Expected the 7th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[7].Id].CRM_Status__c, 'Expected the 8th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[8].Id].CRM_Status__c, 'Expected the 9th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[9].Id].CRM_Status__c, 'Expected the 10th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_PROCESSED, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[10].Id].CRM_Status__c, 'Expected the 11th message to have the processed status');
        System.assertEquals(KafkaMessageService.STATUS_ERROR, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[11].Id].CRM_Status__c, 'Expected the 12th message to still have the error status');
        System.assertEquals(KafkaMessageService.STATUS_ERROR, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[12].Id].CRM_Status__c, 'Expected the 13th message to still have the error status');
        System.assertEquals(KafkaMessageService.STATUS_ERROR, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[13].Id].CRM_Status__c, 'Expected the 14th message to still have the error status');
        System.assertEquals(KafkaMessageService.STATUS_ERROR, [SELECT Id, CRM_Key__c, CRM_Topic__c, CRM_Status__c, CreatedDate FROM KafkaMessage__c WHERE Id = :messages[14].Id].CRM_Status__c, 'Expected the 15th message to still have the error status');
    }
}
