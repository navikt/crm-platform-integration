@IsTest
public with sharing class KafkaEnhetHandlerTest {
    @IsTest private static void processMessagesTest() {
        // Assert that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Account]);

        // Load 200 KafkaMessage records from static resource CSV. Use start/stoptest to ensure handling through queuable framework.
        Test.startTest();
        Test.loadData(KafkaMessage__c.sObjectType, 'KafkaMessage_Test_Data_Enhetsregisteret');
        Test.stopTest();

        // Assert that 200 Accounts have been inserted
        System.assertEquals(200, [SELECT COUNT() FROM Account]);
        // Asert that all Kafka Message records have been marked as processed
        System.assertEquals(200, [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_IsProcessed__c = TRUE]);
        // Assert that one AsyncRequest record has been completed
        System.assertEquals(1, [SELECT COUNT() FROM AsyncRequest__c WHERE CRM_Completed__c = TRUE]);
        // Assert that one known KafkaMessage where the parent org number maps to another accounts org number has been assigned the correct parent
        System.assertEquals([SELECT Id FROM Account WHERE INT_OrganizationNumber__c = '920177174'].Id, [SELECT ParentId FROM Account WHERE INT_ParentOrganizationNumber__c = '920177174' LIMIT 1].ParentId);

        // Assign an Account name for later comparison after updating the account
        String orgNameBeforeUpdate = [SELECT Name FROM Account WHERE INT_OrganizationNumber__c = '920165591' LIMIT 1].Name;

        // Insert a new Kafka Message. The value corresponds to the account with org number 920165591. The name value has been updated in the encoded JSON value.
        KafkaMessage__c messageUpdate = new KafkaMessage__c();
        messageUpdate.CRM_Key__c = '920165591#ENHET#2222321630';
        messageUpdate.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageUpdate.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU1OTEiLAogICJuYXZuIiA6ICJBU0sgSEFVR0VSVUQgSE9WSUsgUFJPRFVLU0pPTkVSIE5FVyBOQU1FIiwKICAib3JnYW5pc2Fzam9uc2Zvcm0iIDogewogICAgImtvZGUiIDogIkVOSyIsCiAgICAiYmVza3JpdmVsc2UiIDogIkVua2VsdHBlcnNvbmZvcmV0YWsiLAogICAgImxpbmtzIiA6IFsgXQogIH0sCiAgInJlZ2lzdHJlcmluZ3NkYXRvRW5oZXRzcmVnaXN0ZXJldCIgOiAiMjAxNy0xMi0yMiIsCiAgInJlZ2lzdHJlcnRJTXZhcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAibmFlcmluZ3Nrb2RlMSIgOiB7CiAgICAiYmVza3JpdmVsc2UiIDogIlNlbHZzdGVuZGlnIGt1bnN0bmVyaXNrIHZpcmtzb21oZXQgaW5uZW4gdmlzdWVsbCBrdW5zdCIsCiAgICAia29kZSIgOiAiOTAuMDMxIgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwMTc3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJBa2Vyc3ZlaWVuIDI0RiIgXSwKICAgICJrb21tdW5lIiA6ICJPU0xPIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiAgImluc3RpdHVzam9uZWxsU2VrdG9ya29kZSIgOiB7CiAgICAia29kZSIgOiAiODIwMCIsCiAgICAiYmVza3JpdmVsc2UiIDogIlBlcnNvbmxpZyBuw6ZyaW5nc2RyaXZlbmRlIgogIH0sCiAgInJlZ2lzdHJlcnRJRm9yZXRha3NyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SVN0aWZ0ZWxzZXNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SUZyaXZpbGxpZ2hldHNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJrb25rdXJzIiA6IGZhbHNlLAogICJ1bmRlckF2dmlrbGluZyIgOiBmYWxzZSwKICAidW5kZXJUdmFuZ3NhdnZpa2xpbmdFbGxlclR2YW5nc29wcGxvc25pbmciIDogZmFsc2UsCiAgIm1hYWxmb3JtIiA6ICJCb2ttw6VsIiwKICAibGlua3MiIDogWyBdCn0=';
        insert messageUpdate;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{
                messageUpdate
        });

        // Assert that the account name has been updated
        String orgNameAfterUpdate = [SELECT Name FROM Account WHERE INT_OrganizationNumber__c = '920165591' LIMIT 1].Name;
        System.assertNotEquals(orgNameBeforeUpdate, orgNameAfterUpdate);
    }
}