public with sharing class KafkaMessageAsyncJob extends AsyncJob {

    public override void execute(AsyncRequest__c ar) {
        List<Id> idList = (List<Id>) ar.CRM_Params__c.split(';');
        List<KafkaMessage__c> kafkaMessages = [SELECT Id, CRM_Topic__c, CRM_Key__c, CRM_Value__c FROM KafkaMessage__c WHERE Id IN :idList];
        new KafkaMessageService(kafkaMessages).handleMessages();
    }
    
}