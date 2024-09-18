/**
 * Tests methods specific to KafkaMessageHandler. See KafkaMessageServiceTest
 * for similar tests.
 */
@IsTest
public with sharing class KafkaMessageHandlerTest {
    /**
     * Tests that the topic given in SandboxOverrideTopic__c is picked up by the
     * handler. KafkaMessageHandlerBinding__mdt can not be modified in tests, so
     * we assume the values are set correctly; CRM_Priority__c is set to 20 by
     * default, but to 19 where the SandboxOverrideTopic__c matches the topic
     * given here.
     */
    @IsTest
    private static void handleSandboxOverrideTopicPriority() {
        // These topics will only be picked up in sandboxes, so only run there.
        if ([SELECT IsSandbox FROM Organization][0].IsSandbox) {
            KafkaMessage__c msg = new KafkaMessage__c(
                CRM_Key__c = '1792160394037',
                CRM_Topic__c = 'pdl.pdl-persondokument-tagged-v1',
                CRM_Value__c = null
            );
            insert msg;
            Test.startTest();
            new KafkaMessageService(new List<KafkaMessage__c>{ msg }).handleMessages();
            Test.stopTest();
            System.assertEquals(
                KafkaMessageService.STATUS_PROCESSED,
                [SELECT Id, CRM_Status__c FROM KafkaMessage__c WHERE Id = :msg.Id LIMIT 1].CRM_Status__c
            );
            System.assertEquals(19, [SELECT CRM_Priority__c FROM AsyncRequest__c LIMIT 1].CRM_Priority__c);
        }
    }
}
