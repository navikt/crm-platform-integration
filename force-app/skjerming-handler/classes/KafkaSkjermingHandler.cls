public with sharing class KafkaSkjermingHandler implements IKafkaMessageConsumer {
    public void processMessages(List<KafkaMessage__c> messages) {
        List<Person__c> personsToUpsert=new List<Person__c>();
        for(KafkaMessage__c msg:messages){
            try{
                KafkaSkjerming skjerming=convertKafkaToSkjerming( msg );
                personsToUpsert.add(convertKafkaSkjermingToPersonSobject(skjerming)); 
           } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }
        
        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        upsert personsToUpsert INT_ActorId__c;
    }

    @TestVisible
    private KafkaSkjerming convertKafkaToSkjerming(KafkaMessage__c message){

             String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c ).toString();
             return KafkaSkjerming.parse(message.CRM_Key__c,decodedValue);
   }

   @TestVisible
   private Person__c convertKafkaSkjermingToPersonSobject(KafkaSkjerming kafkaSkjerming){
      Person__c person=new Person__c();
      person.INT_ActorId__c=kafkaSkjerming.aktoerId;
      person.INT_NavEmployeeFromDate__c=kafkaSkjerming.skjermetFraDate;
      person.INT_NavEmployeeToDate__c=kafkaSkjerming.skjermetTilDate;
      return person;

   }
}
