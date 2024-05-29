/**
 * Tests methods specific to KafkaMessageHandler. See KafkaMessageServiceTest
 * for similar tests.
 */
@IsTest
public with sharing class KafkaMessageHandlerTest {

    /**
     * Tests that the topic given in SandboxOverrideTopic__c is picked up by the
     * handler.
     */
    @IsTest
    private static void handleSandboxOverrideTopicPriority() {
        // Disable Sandbox-specific filter in order to test production functionality
        KafkaEnhetFilter.bypassFilter = true;
        KafkaMessage__c msg = new KafkaMessage__c();
        msg.CRM_Key__c = '1792160394037';
        msg.CRM_Topic__c = 'pdl.pdl-persondokument-tagged-v1';
        msg.CRM_Value__c = null;
        insert msg;
        Test.startTest();
        new KafkaMessageService(new List<KafkaMessage__c>{ msg }).handleMessages();
        Test.stopTest();
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            [SELECT Id, CRM_Status__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1]
            .CRM_Status__c
        );
        System.assertEquals(19, [SELECT CRM_Priority__c FROM AsyncRequest__c LIMIT 1].CRM_Priority__c);
    }
}
