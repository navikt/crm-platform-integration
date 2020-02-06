@IsTest
public with sharing class KafkaMessageServiceTest {

    @IsTest private static void handleMessagesPositiveTest() {
        // Disable Sandbox-specific filter in order to test production functionality
        KafkaEnhetFilter.bypassFilter = true;

        KafkaMessage__c msg = new KafkaMessage__c();
        msg.CRM_Key__c = '920165591#ENHET#2222321630';
        msg.CRM_Topic__c = 'public-ereg-cache-org-json';
        msg.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU1OTEiLAogICJuYXZuIiA6ICJBU0sgSEFVR0VSVUQgSE9WSUsgUFJPRFVLU0pPTkVSIE5FVyBOQU1FIiwKICAib3JnYW5pc2Fzam9uc2Zvcm0iIDogewogICAgImtvZGUiIDogIkVOSyIsCiAgICAiYmVza3JpdmVsc2UiIDogIkVua2VsdHBlcnNvbmZvcmV0YWsiLAogICAgImxpbmtzIiA6IFsgXQogIH0sCiAgInJlZ2lzdHJlcmluZ3NkYXRvRW5oZXRzcmVnaXN0ZXJldCIgOiAiMjAxNy0xMi0yMiIsCiAgInJlZ2lzdHJlcnRJTXZhcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAibmFlcmluZ3Nrb2RlMSIgOiB7CiAgICAiYmVza3JpdmVsc2UiIDogIlNlbHZzdGVuZGlnIGt1bnN0bmVyaXNrIHZpcmtzb21oZXQgaW5uZW4gdmlzdWVsbCBrdW5zdCIsCiAgICAia29kZSIgOiAiOTAuMDMxIgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwMTc3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJBa2Vyc3ZlaWVuIDI0RiIgXSwKICAgICJrb21tdW5lIiA6ICJPU0xPIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiAgImluc3RpdHVzam9uZWxsU2VrdG9ya29kZSIgOiB7CiAgICAia29kZSIgOiAiODIwMCIsCiAgICAiYmVza3JpdmVsc2UiIDogIlBlcnNvbmxpZyBuw6ZyaW5nc2RyaXZlbmRlIgogIH0sCiAgInJlZ2lzdHJlcnRJRm9yZXRha3NyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SVN0aWZ0ZWxzZXNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SUZyaXZpbGxpZ2hldHNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJrb25rdXJzIiA6IGZhbHNlLAogICJ1bmRlckF2dmlrbGluZyIgOiBmYWxzZSwKICAidW5kZXJUdmFuZ3NhdnZpa2xpbmdFbGxlclR2YW5nc29wcGxvc25pbmciIDogZmFsc2UsCiAgIm1hYWxmb3JtIiA6ICJCb2ttw6VsIiwKICAibGlua3MiIDogWyBdCn0=';
        insert msg;

        System.assertEquals(false, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);

        Test.startTest();
        new KafkaMessageService(new List<KafkaMessage__c>{msg}).handleMessages();
        Test.stopTest();

        System.assertEquals(true, [SELECT Id, CRM_IsProcessed__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_IsProcessed__c);
    }

    @IsTest private static void handleMessagesNegativeTest() {
        // Disable Sandbox-specific filter in order to test production functionality
        KafkaEnhetFilter.bypassFilter = true;

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