/**
 * ! DEPRECATED
 */
public without sharing class KafkaPDLHandler implements IKafkaMessageConsumer {
    public void processMessages(List<KafkaMessage__c> messages) {
        for (KafkaMessage__c msg : messages) {
            msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            msg.CRM_ErrorMessage__c = 'KafkaPDLHandler IS DEPRECATED';
        }
    }
}
