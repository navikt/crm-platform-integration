@IsTest
public with sharing class KafkaEnhetHandlerTest {
    @IsTest
    private static void processMessagesTest() {
        // Disable Sandbox-specific filter in order to test production functionality
        KafkaEnhetFilter.bypassFilter = true;

        System.assertEquals(0, [SELECT COUNT() FROM Account], 'Assert that no Accounts have been inserted');

        // Load 200 KafkaMessage records from static resource CSV. Use start/stoptest to ensure handling through queuable framework.
        Test.startTest();
        Test.loadData(KafkaMessage__c.sObjectType, 'KafkaMessage_Test_Data_Enhetsregisteret');
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Account], 'Assert that 200 Accounts have been inserted');

        System.assertEquals(
            200,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED],
            'Assert that all Kafka Message records have been marked as processed'
        );

        System.assertEquals(
            [SELECT Id FROM Account WHERE INT_OrganizationNumber__c = '920177174'].Id,
            [SELECT ParentId FROM Account WHERE INT_ParentOrganizationNumber__c = '920177174' LIMIT 1].ParentId,
            'Assert that one known KafkaMessage where the parent org number maps to another accounts org number has been assigned the correct parent'
        );

        // Assign an Account name for later comparison after updating the account
        String orgNameBeforeUpdate = [SELECT Name FROM Account WHERE INT_OrganizationNumber__c = '920165591' LIMIT 1]
        .Name;

        // Insert a new Kafka Message. The value corresponds to the account with org number 920165591. The name value has been updated in the encoded JSON value.
        KafkaMessage__c messageUpdate = new KafkaMessage__c();
        messageUpdate.CRM_Key__c = '920165591#ENHET#2222321630';
        messageUpdate.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageUpdate.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU1OTEiLAogICJuYXZuIiA6ICJBU0sgSEFVR0VSVUQgSE9WSUsgUFJPRFVLU0pPTkVSIE5FVyBOQU1FIiwKICAib3JnYW5pc2Fzam9uc2Zvcm0iIDogewogICAgImtvZGUiIDogIkVOSyIsCiAgICAiYmVza3JpdmVsc2UiIDogIkVua2VsdHBlcnNvbmZvcmV0YWsiLAogICAgImxpbmtzIiA6IFsgXQogIH0sCiAgInJlZ2lzdHJlcmluZ3NkYXRvRW5oZXRzcmVnaXN0ZXJldCIgOiAiMjAxNy0xMi0yMiIsCiAgInJlZ2lzdHJlcnRJTXZhcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAibmFlcmluZ3Nrb2RlMSIgOiB7CiAgICAiYmVza3JpdmVsc2UiIDogIlNlbHZzdGVuZGlnIGt1bnN0bmVyaXNrIHZpcmtzb21oZXQgaW5uZW4gdmlzdWVsbCBrdW5zdCIsCiAgICAia29kZSIgOiAiOTAuMDMxIgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwMTc3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJBa2Vyc3ZlaWVuIDI0RiIgXSwKICAgICJrb21tdW5lIiA6ICJPU0xPIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiAgImluc3RpdHVzam9uZWxsU2VrdG9ya29kZSIgOiB7CiAgICAia29kZSIgOiAiODIwMCIsCiAgICAiYmVza3JpdmVsc2UiIDogIlBlcnNvbmxpZyBuw6ZyaW5nc2RyaXZlbmRlIgogIH0sCiAgInJlZ2lzdHJlcnRJRm9yZXRha3NyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SVN0aWZ0ZWxzZXNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SUZyaXZpbGxpZ2hldHNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJrb25rdXJzIiA6IGZhbHNlLAogICJ1bmRlckF2dmlrbGluZyIgOiBmYWxzZSwKICAidW5kZXJUdmFuZ3NhdnZpa2xpbmdFbGxlclR2YW5nc29wcGxvc25pbmciIDogZmFsc2UsCiAgIm1hYWxmb3JtIiA6ICJCb2ttw6VsIiwKICAibGlua3MiIDogWyBdCn0=';
        insert messageUpdate;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageUpdate });

        String orgNameAfterUpdate = [SELECT Name FROM Account WHERE INT_OrganizationNumber__c = '920165591' LIMIT 1]
        .Name;
        System.assertNotEquals(
            orgNameBeforeUpdate,
            orgNameAfterUpdate,
            'Assert that the account name has been updated'
        );

        // Verify that org with "Antall ansatte" 10.0 will parse
        KafkaMessage__c newerMessageFormat = [
            SELECT id, CRM_Key__c, CreatedDate, CRM_Value__c, CRM_Topic__c, CRM_Status__c
            FROM KafkaMessage__c
            WHERE CRM_Key__c = '810034882#ENHET#-1377720839'
            LIMIT 1
        ];
        KafkaEnhet parsedMessage = KafkaEnhet.parse(
            EncodingUtil.base64Decode(newerMessageFormat.CRM_Value__c).toString()
        );
        System.Assert.areEqual(
            10.0,
            parsedMessage.antallAnsatte,
            'Assert that the parsed message contains the expected value for antallAnsatte'
        );
        // Verify that org with harRegistrertAntallAnsatte true will parse
        System.Assert.areEqual(
            true,
            parsedMessage.harRegistrertAntallAnsatte,
            'Assert that the parsed message contains the expected value for harRegistrertAntallAnsatte'
        );

        Account org810034882 = [
            SELECT NumberOfEmployees, INT_HasEmployees__c
            FROM Account
            WHERE INT_OrganizationNumber__c = '810034882'
            LIMIT 1
        ];
        System.Assert.areEqual(10, org810034882.NumberOfEmployees, 'Assert that the number of employees is updated');
        System.Assert.areEqual(true, org810034882.INT_HasEmployees__c, 'Assert that the boolean INT_HasEmployees__c is updated');

        Account org920165842BeforeUpdate = [SELECT Name, ShippingCity, ShippingPostalCode, INT_MunicipalityNumber__c, BillingCity  FROM Account WHERE INT_OrganizationNumber__c = '920165842' LIMIT 1];
        
        // Insert a new Kafka Message. The value corresponds to the account with org number 920165842. Forretningsadresse has been removed.
        KafkaMessage__c messageWOAddress = new KafkaMessage__c();
        messageWOAddress.CRM_Key__c = '920165842#ENHET#190049246';
        messageWOAddress.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageWOAddress.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU4NDIiLAogICJuYXZuIiA6ICJPU1RFT1BBVCBTQUdQTEFEUyIsCiAgIm9yZ2FuaXNhc2pvbnNmb3JtIiA6IHsKICAgICJrb2RlIiA6ICJFTksiLAogICAgImJlc2tyaXZlbHNlIiA6ICJFbmtlbHRwZXJzb25mb3JldGFrIiwKICAgICJsaW5rcyIgOiBbIF0KICB9LAogICJyZWdpc3RyZXJpbmdzZGF0b0VuaGV0c3JlZ2lzdGVyZXQiIDogIjIwMTctMTItMjIiLAogICJyZWdpc3RyZXJ0SU12YXJlZ2lzdGVyZXQiIDogZmFsc2UsCiAgIm5hZXJpbmdza29kZTEiIDogewogICAgImJlc2tyaXZlbHNlIiA6ICJBbmRyZSBoZWxzZXRqZW5lc3RlciIsCiAgICAia29kZSIgOiAiODYuOTA5IgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiaW5zdGl0dXNqb25lbGxTZWt0b3Jrb2RlIiA6IHsKICAgICJrb2RlIiA6ICI4MjAwIiwKICAgICJiZXNrcml2ZWxzZSIgOiAiUGVyc29ubGlnIG7DpnJpbmdzZHJpdmVuZGUiCiAgfSwKICAicmVnaXN0cmVydElGb3JldGFrc3JlZ2lzdGVyZXQiIDogZmFsc2UsCiAgInJlZ2lzdHJlcnRJU3RpZnRlbHNlc3JlZ2lzdGVyZXQiIDogZmFsc2UsCiAgInJlZ2lzdHJlcnRJRnJpdmlsbGlnaGV0c3JlZ2lzdGVyZXQiIDogZmFsc2UsCiAgImtvbmt1cnMiIDogZmFsc2UsCiAgInVuZGVyQXZ2aWtsaW5nIiA6IGZhbHNlLAogICJ1bmRlclR2YW5nc2F2dmlrbGluZ0VsbGVyVHZhbmdzb3BwbG9zbmluZyIgOiBmYWxzZSwKICAibWFhbGZvcm0iIDogIkJva23DpWwiLAogICJsaW5rcyIgOiBbIF0KfQ==';
        insert messageWOAddress;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageWOAddress });

        Account org920165842AfterUpdate = [SELECT Name, ShippingCity, ShippingPostalCode, INT_MunicipalityNumber__c  FROM Account WHERE INT_OrganizationNumber__c = '920165842' LIMIT 1];
        System.assertEquals(
            org920165842AfterUpdate.Name,
            org920165842BeforeUpdate.Name,
            'Assert that the account name has not been updated'
        );
        System.assertEquals(
            org920165842AfterUpdate.INT_MunicipalityNumber__c,
            org920165842BeforeUpdate.INT_MunicipalityNumber__c,
            'Assert that the INT_MunicipalityNumber__c has not been updated'
        );
        System.assertEquals(
            '0857',
            org920165842BeforeUpdate.ShippingPostalCode,
            'Assert that the ShippingCity is 0857 before update'
        );
        System.assertEquals(
            'OSLO',
            org920165842BeforeUpdate.ShippingCity,
            'Assert that the ShippingCity is OSLO before update'
        );
        System.assertEquals(
            null,
            org920165842AfterUpdate.ShippingCity,
            'Assert that the ShippingCity is null after update'
        );
        System.assertEquals(
            null,
            org920165842AfterUpdate.ShippingPostalCode,
            'Assert that the ShippingPostalCode is null after update'
        );

        // Insert a new Kafka Message. The value corresponds to the account with org number 920165842. Forretningsadresse and beliggenhetsadresse has been added and changed.
        KafkaMessage__c messageW2Address = new KafkaMessage__c();
        messageW2Address.CRM_Key__c = '920165842#ENHET#190049246';
        messageW2Address.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageW2Address.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU4NDIiLAogICJuYXZuIiA6ICJPU1RFT1BBVCBTQUdQTEFEUyIsCiAgIm9yZ2FuaXNhc2pvbnNmb3JtIiA6IHsKICAgICJrb2RlIiA6ICJFTksiLAogICAgImJlc2tyaXZlbHNlIiA6ICJFbmtlbHRwZXJzb25mb3JldGFrIiwKICAgICJsaW5rcyIgOiBbIF0KICB9LAogICJyZWdpc3RyZXJpbmdzZGF0b0VuaGV0c3JlZ2lzdGVyZXQiIDogIjIwMTctMTItMjIiLAogICJyZWdpc3RyZXJ0SU12YXJlZ2lzdGVyZXQiIDogZmFsc2UsCiAgIm5hZXJpbmdza29kZTEiIDogewogICAgImJlc2tyaXZlbHNlIiA6ICJBbmRyZSBoZWxzZXRqZW5lc3RlciIsCiAgICAia29kZSIgOiAiODYuOTA5IgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwODU3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJTb2duc3ZlaWVuIDEwMkwiIF0sCiAgICAia29tbXVuZSIgOiAiT1NMTyIsCiAgICAia29tbXVuZW51bW1lciIgOiAiMDMwMSIKICB9LAogICJiZWxpZ2dlbmhldHNhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICI4MDAxIiwKICAgICJwb3N0c3RlZCIgOiAiQk9Ew5giLAogICAgImFkcmVzc2UiIDogWyAiU29nbnN2ZWllbiAxMDJMIiBdLAogICAgImtvbW11bmUiIDogIkJPRMOYIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiAgImluc3RpdHVzam9uZWxsU2VrdG9ya29kZSIgOiB7CiAgICAia29kZSIgOiAiODIwMCIsCiAgICAiYmVza3JpdmVsc2UiIDogIlBlcnNvbmxpZyBuw6ZyaW5nc2RyaXZlbmRlIgogIH0sCiAgInJlZ2lzdHJlcnRJRm9yZXRha3NyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SVN0aWZ0ZWxzZXNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SUZyaXZpbGxpZ2hldHNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJrb25rdXJzIiA6IGZhbHNlLAogICJ1bmRlckF2dmlrbGluZyIgOiBmYWxzZSwKICAidW5kZXJUdmFuZ3NhdnZpa2xpbmdFbGxlclR2YW5nc29wcGxvc25pbmciIDogZmFsc2UsCiAgIm1hYWxmb3JtIiA6ICJCb2ttw6VsIiwKICAibGlua3MiIDogWyBdCn0=';
        insert messageW2Address;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageW2Address });

        Account org920165842AfterUpdate2 = [SELECT Name, ShippingCity, ShippingPostalCode, INT_MunicipalityNumber__c  FROM Account WHERE INT_OrganizationNumber__c = '920165842' LIMIT 1];
        System.assertEquals(
            org920165842AfterUpdate2.Name,
            org920165842BeforeUpdate.Name,
            'Assert that the account name has not been updated'
        );
        System.assertEquals(
            org920165842AfterUpdate2.INT_MunicipalityNumber__c,
            org920165842BeforeUpdate.INT_MunicipalityNumber__c,
            'Assert that the INT_MunicipalityNumber__c has not been updated'
        );
        System.assertEquals(
            '0857',
            org920165842BeforeUpdate.ShippingPostalCode,
            'Assert that the ShippingCity is 0857 before update'
        );
        System.assertEquals(
            'OSLO',
            org920165842BeforeUpdate.ShippingCity,
            'Assert that the ShippingCity is OSLO before update'
        );
        System.assertEquals(
            'BODØ',
            org920165842AfterUpdate2.ShippingCity,
            'Assert that the ShippingCity is BODØ after update'
        );
        System.assertEquals(
            '8001',
            org920165842AfterUpdate2.ShippingPostalCode,
            'Assert that the ShippingPostalCode is 8001 after update'
        );

        // Insert a new Kafka Message. The value corresponds to the account with org number 920165842. Beliggenhetsadresse has been changed and postadresse added.
        KafkaMessage__c messageW3Address = new KafkaMessage__c();
        messageW3Address.CRM_Key__c = '920165842#ENHET#190049246';
        messageW3Address.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageW3Address.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU4NDIiLAogICJuYXZuIiA6ICJPU1RFT1BBVCBTQUdQTEFEUyIsCiAgIm9yZ2FuaXNhc2pvbnNmb3JtIiA6IHsKICAgICJrb2RlIiA6ICJFTksiLAogICAgImJlc2tyaXZlbHNlIiA6ICJFbmtlbHRwZXJzb25mb3JldGFrIiwKICAgICJsaW5rcyIgOiBbIF0KICB9LAogICJyZWdpc3RyZXJpbmdzZGF0b0VuaGV0c3JlZ2lzdGVyZXQiIDogIjIwMTctMTItMjIiLAogICJyZWdpc3RyZXJ0SU12YXJlZ2lzdGVyZXQiIDogZmFsc2UsCiAgIm5hZXJpbmdza29kZTEiIDogewogICAgImJlc2tyaXZlbHNlIiA6ICJBbmRyZSBoZWxzZXRqZW5lc3RlciIsCiAgICAia29kZSIgOiAiODYuOTA5IgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwODU3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJTb2duc3ZlaWVuIDEwMkwiIF0sCiAgICAia29tbXVuZSIgOiAiT1NMTyIsCiAgICAia29tbXVuZW51bW1lciIgOiAiMDMwMiIKICB9LAogICJiZWxpZ2dlbmhldHNhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICI4MDAxIiwKICAgICJwb3N0c3RlZCIgOiAiQk9Ew5giLAogICAgImFkcmVzc2UiIDogWyAiU29nbnN2ZWllbiAxMDJMIiBdLAogICAgImtvbW11bmUiIDogIkJPRMOYIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiJwb3N0YWRyZXNzZSIgOiB7CiAgICAibGFuZCIgOiAiTm9yZ2UiLAogICAgImxhbmRrb2RlIiA6ICJOTyIsCiAgICAicG9zdG51bW1lciIgOiAiMTIyMSIsCiAgICAicG9zdHN0ZWQiIDogIkZSRURSSUtTVEFEIiwKICAgICJhZHJlc3NlIiA6IFsgIlNvZ25zdmVpZW4gMTAyTCIgXSwKICAgICJrb21tdW5lIiA6ICJGUkVEUklLU1RBRCIsCiAgICAia29tbXVuZW51bW1lciIgOiAiMTIyMSIKICB9LAogICJpbnN0aXR1c2pvbmVsbFNla3RvcmtvZGUiIDogewogICAgImtvZGUiIDogIjgyMDAiLAogICAgImJlc2tyaXZlbHNlIiA6ICJQZXJzb25saWcgbsOmcmluZ3Nkcml2ZW5kZSIKICB9LAogICJyZWdpc3RyZXJ0SUZvcmV0YWtzcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAicmVnaXN0cmVydElTdGlmdGVsc2VzcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAicmVnaXN0cmVydElGcml2aWxsaWdoZXRzcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAia29ua3VycyIgOiBmYWxzZSwKICAidW5kZXJBdnZpa2xpbmciIDogZmFsc2UsCiAgInVuZGVyVHZhbmdzYXZ2aWtsaW5nRWxsZXJUdmFuZ3NvcHBsb3NuaW5nIiA6IGZhbHNlLAogICJtYWFsZm9ybSIgOiAiQm9rbcOlbCIsCiAgImxpbmtzIiA6IFsgXQp9';
        insert messageW3Address;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageW3Address });

        Account org920165842AfterUpdate3 = [SELECT Name, ShippingCity, ShippingPostalCode, INT_MunicipalityNumber__c, BillingCity  FROM Account WHERE INT_OrganizationNumber__c = '920165842' LIMIT 1];
        System.assertEquals(
            org920165842AfterUpdate3.Name,
            org920165842AfterUpdate2.Name,
            'Assert that the account name has not been updated'
        );
        System.assertEquals(
            org920165842AfterUpdate3.INT_MunicipalityNumber__c,
            org920165842AfterUpdate2.INT_MunicipalityNumber__c,
            'Assert that the INT_MunicipalityNumber__c has not been updated'
        );
        System.assertEquals(
            '0857',
            org920165842BeforeUpdate.ShippingPostalCode,
            'Assert that the ShippingCity is 0857 before update'
        );
        System.assertEquals(
            'OSLO',
            org920165842BeforeUpdate.ShippingCity,
            'Assert that the ShippingCity is OSLO before update'
        );
        System.assertEquals(
            'BODØ',
            org920165842AfterUpdate3.ShippingCity,
            'Assert that the ShippingCity is BODØ after update'
        );
        System.assertEquals(
            '8001',
            org920165842AfterUpdate3.ShippingPostalCode,
            'Assert that the ShippingPostalCode is 8001 after update'
        );
        System.assertEquals(
            null,
            org920165842BeforeUpdate.BillingCity,
            'Assert that the BillingCity is null before update'
        );
        System.assertEquals(
            'FREDRIKSTAD',
            org920165842AfterUpdate3.BillingCity,
            'Assert that the BillingCity is FREDRIKSTAD after update'
        );
    }

    @IsTest
    private static void processMessageNegativeTest() {
        KafkaEnhetFilter.bypassFilter = true;

        // Insert new Kafka Message with corrupted data to create parsing error
        KafkaMessage__c messageUpdate = new KafkaMessage__c();
        messageUpdate.CRM_Key__c = '920165591#ENHET#2222321630';
        messageUpdate.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageUpdate.CRM_Value__c = 'BAD_DATA';
        insert messageUpdate;

        try {
            new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageUpdate });
        } catch (Exception e) {
            system.assert(false, 'Exceptions should be handled by the method and not the unit test');
        }

        // Create duplicate accounts and insert a new Kafka Message with non-unique org number to cause DML error
        insert new Account(INT_OrganizationNumber__c = '920165591', Name = 'test account');
        insert new Account(INT_OrganizationNumber__c = '920165591', Name = 'duplicate account');
        messageUpdate = new KafkaMessage__c();
        messageUpdate.CRM_Key__c = '920165591#ENHET#2222321630';
        messageUpdate.CRM_Topic__c = 'public-ereg-cache-org-json';
        messageUpdate.CRM_Value__c = 'ewogICJvcmdhbmlzYXNqb25zbnVtbWVyIiA6ICI5MjAxNjU1OTEiLAogICJuYXZuIiA6ICJBU0sgSEFVR0VSVUQgSE9WSUsgUFJPRFVLU0pPTkVSIiwKICAib3JnYW5pc2Fzam9uc2Zvcm0iIDogewogICAgImtvZGUiIDogIkVOSyIsCiAgICAiYmVza3JpdmVsc2UiIDogIkVua2VsdHBlcnNvbmZvcmV0YWsiLAogICAgImxpbmtzIiA6IFsgXQogIH0sCiAgInJlZ2lzdHJlcmluZ3NkYXRvRW5oZXRzcmVnaXN0ZXJldCIgOiAiMjAxNy0xMi0yMiIsCiAgInJlZ2lzdHJlcnRJTXZhcmVnaXN0ZXJldCIgOiBmYWxzZSwKICAibmFlcmluZ3Nrb2RlMSIgOiB7CiAgICAiYmVza3JpdmVsc2UiIDogIlNlbHZzdGVuZGlnIGt1bnN0bmVyaXNrIHZpcmtzb21oZXQgaW5uZW4gdmlzdWVsbCBrdW5zdCIsCiAgICAia29kZSIgOiAiOTAuMDMxIgogIH0sCiAgImFudGFsbEFuc2F0dGUiIDogMCwKICAiZm9ycmV0bmluZ3NhZHJlc3NlIiA6IHsKICAgICJsYW5kIiA6ICJOb3JnZSIsCiAgICAibGFuZGtvZGUiIDogIk5PIiwKICAgICJwb3N0bnVtbWVyIiA6ICIwMTc3IiwKICAgICJwb3N0c3RlZCIgOiAiT1NMTyIsCiAgICAiYWRyZXNzZSIgOiBbICJBa2Vyc3ZlaWVuIDI0RiIgXSwKICAgICJrb21tdW5lIiA6ICJPU0xPIiwKICAgICJrb21tdW5lbnVtbWVyIiA6ICIwMzAxIgogIH0sCiAgImluc3RpdHVzam9uZWxsU2VrdG9ya29kZSIgOiB7CiAgICAia29kZSIgOiAiODIwMCIsCiAgICAiYmVza3JpdmVsc2UiIDogIlBlcnNvbmxpZyBuw6ZyaW5nc2RyaXZlbmRlIgogIH0sCiAgInJlZ2lzdHJlcnRJRm9yZXRha3NyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SVN0aWZ0ZWxzZXNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJyZWdpc3RyZXJ0SUZyaXZpbGxpZ2hldHNyZWdpc3RlcmV0IiA6IGZhbHNlLAogICJrb25rdXJzIiA6IGZhbHNlLAogICJ1bmRlckF2dmlrbGluZyIgOiBmYWxzZSwKICAidW5kZXJUdmFuZ3NhdnZpa2xpbmdFbGxlclR2YW5nc29wcGxvc25pbmciIDogZmFsc2UsCiAgIm1hYWxmb3JtIiA6ICJCb2ttw6VsIiwKICAibGlua3MiIDogWyBdCn0=';
        insert messageUpdate;

        try {
            new KafkaEnhetHandler().processMessages(new List<KafkaMessage__c>{ messageUpdate });
        } catch (Exception e) {
            system.assert(false, 'Exceptions should be handled by the method and not the unit test');
        }
    }

    @isTest
    static void testGetNumberOfEmployeesGroup() {
        System.assertEquals('1-4', KafkaEnhetHandler.getNumberOfEmployeesGroup(4, true));
        System.assertEquals('1-4', KafkaEnhetHandler.getNumberOfEmployeesGroup(null, true));
        System.assertEquals('5-10', KafkaEnhetHandler.getNumberOfEmployeesGroup(5, true));
        System.assertEquals('11-25', KafkaEnhetHandler.getNumberOfEmployeesGroup(11, true));
        System.assertEquals('26-50', KafkaEnhetHandler.getNumberOfEmployeesGroup(26, true));
        System.assertEquals('51-100', KafkaEnhetHandler.getNumberOfEmployeesGroup(51, true));
        System.assertEquals('101-250', KafkaEnhetHandler.getNumberOfEmployeesGroup(101, true));
        System.assertEquals('251-500', KafkaEnhetHandler.getNumberOfEmployeesGroup(251, true));
        System.assertEquals('501-1000', KafkaEnhetHandler.getNumberOfEmployeesGroup(501, true));
        System.assertEquals('1000+', KafkaEnhetHandler.getNumberOfEmployeesGroup(1001, true));
        System.assertEquals('0', KafkaEnhetHandler.getNumberOfEmployeesGroup(4, false));
        System.assertEquals('0', KafkaEnhetHandler.getNumberOfEmployeesGroup(0, false));
    }

    @isTest
    private static void testVerifyEmailFormat() {
        // Valid email addresses
        String validEmail1 = 'test@example.com';
        String validEmail2 = 'user.name+tag+sorting@example.com';
        String validEmail3 = 'user_name@example.co.uk';
        String validEmail4 = 'test@-test.no';

        // Invalid email addresses
        String invalidEmail1 = 'plainaddress';
        String invalidEmail2 = '@missingusername.com';
        String invalidEmail3 = 'username@.com';
        String invalidEmail4 = 'kmrrr@rime.no;mailooo@rime.no';
        String invalidEmail5 = 'test@test..no';
        String invalidEmail6 = 'test@-test.no';
        String invalidEmail7 = 'test@test-.no';
        String invalidEmail8 = 'test@test. no';

        // Assertions for valid emails
        System.assertEquals(true, KafkaEnhetHandler.verifyEmailFormat(validEmail1));
        System.assertEquals(true, KafkaEnhetHandler.verifyEmailFormat(validEmail2));
        System.assertEquals(true, KafkaEnhetHandler.verifyEmailFormat(validEmail3));

        // Assertions for invalid emails
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail1));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail2));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail3));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail4));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail5));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail6));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail7));
        System.assertEquals(false, KafkaEnhetHandler.verifyEmailFormat(invalidEmail8));
    }
}
