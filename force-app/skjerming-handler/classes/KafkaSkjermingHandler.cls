public with sharing class KafkaSkjermingHandler implements IKafkaMessageConsumer {
    public void processMessages(List<KafkaMessage__c> messages) {
        List<String> personIdents=new List<String>();
        for(KafkaMessage__c msg:messages){
            personIdents.add(msg.CRM_Key__c);
        }
        Map<String,Person__c> personByIdent=getPersonByIdent(personIdents);
        
        List<Person__c> personsToUpdate=new List<Person__c>();
        for(KafkaMessage__c msg:messages){
            try{
                KafkaSkjerming skjerming=convertKafkaToSkjerming( msg );
                personsToUpdate.add(convertKafkaSkjermingToPersonSobject(skjerming, personByIdent)); 
           } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }
        
        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        update personsToUpdate;
    }

    @TestVisible
    private KafkaSkjerming convertKafkaToSkjerming(KafkaMessage__c message){
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c ).toString();
        return KafkaSkjerming.parse(message.CRM_Key__c,decodedValue);
   }

   @TestVisible
   private Person__c convertKafkaSkjermingToPersonSobject(KafkaSkjerming kafkaSkjerming, Map<String,Person__c> personByIdent){
      Person__c person=personByIdent.get(kafkaSkjerming.personIdent);
      if(person==null) return new Person__c();
      person.INT_NavEmployeeFromDate__c=kafkaSkjerming.skjermetFraDate;
      person.INT_NavEmployeeToDate__c=kafkaSkjerming.skjermetTilDate;
      return person;
   }

   @TestVisible
   private Map<String,Person__c> getPersonByIdent(List<String> personIdents){
        Map<String,Person__c> personByIdent=new Map<String,Person__c>();
        for(Person__c person:[SELECT Id, Name, INT_NavEMployeeFromDate__c, INT_NavEMployeeToDate__c FROM Person__c WHERE Name in:personIdents]){
            personByIdent.put(person.Name, person);
        }
        return personByIdent;
   }
}
