public without sharing class KafkaPDLHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<Person__c> personsToUpsert = new List<Person__c>();
        // Errors are caught and saved on each KafkaMessage record
        for (KafkaMessage__c msg : messages) {
            try {
                msg.CRM_IsProcessed__c = true;
                personsToUpsert.add(createPersonRecords(msg));
            } catch (Exception e) {
                System.debug(e.getMessage() + ' ' + e.getLineNumber());
                msg.CRM_Error__c = e.getMessage() + ' (' + e.getLineNumber() + ')';
            }
        }

        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        upsert personsToUpsert INT_ActorId__c;
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for each KafkaMessage
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    private Person__c createPersonRecords(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPerson kafkaPerson = KafkaPerson.parse(decodedValue);
        Person__c person = new Person__c();
        person = mapFieldValues(person, kafkaPerson);
        return person;
    }

    /**
     * Transform and map fields from PDL data structure to Person__c SObject
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a person from PDL
     * @return Person Account with initialized fields
     */
    private Person__c mapFieldValues(Person__c person, KafkaPerson kafkaPerson) {
        person.Name = kafkaPerson.identifikasjonsnummer;
        person.INT_ActorId__c = kafkaPerson.aktoerId;
        person.INT_FirstName__c = kafkaPerson.fornavn;
        person.INT_MiddleName__c = kafkaPerson.mellomnavn;
        person.INT_LastName__c = kafkaPerson.etternavn;
        person.INT_MunicipalityNumber__c = kafkaPerson.kommunenummer;
        person.INT_RegionNumber__c = kafkaPerson.region;
        person.INT_IsDeceased__c = kafkaPerson.doed;
        person.INT_Confidential__c = kafkaPerson.adressebeskyttelse;
        person.INT_SecurityMeasures__c = safelyJoinMultiPicklistString(kafkaPerson.sikkerhetstiltak);
        // Ensure that a System User is set as Owner if even if message processing is manually retried by an administrator user
        if(KafkaIntegrationCustomSetting.integrationUserId != null) {
            person.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
        }
        return person;
    }

    /**
     * Safely transform collection into string compatible with multipicklist-fields.
     * @param stringsToJoin Collection of strings to join
     * @return Null or strings joined with ';'
     */
    private String safelyJoinMultiPicklistString(List<String> stringsToJoin) {
        if(stringsToJoin == null || stringsToJoin.size() == 0) {
            return null;
        } else {
            return String.join(stringsToJoin, ';');
        }
    }

}