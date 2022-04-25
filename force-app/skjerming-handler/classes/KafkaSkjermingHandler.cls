public with sharing class KafkaSkjermingHandler implements IKafkaMessageConsumer {
    public void processMessages(List<KafkaMessage__c> messages) {
        Set<String> personIdents = new Set<String>();
        for (KafkaMessage__c msg : messages) {
            personIdents.add(msg.CRM_Key__c);
        }
        Map<String, Person__c> personByIdent = getPersonByIdent(personIdents);

        Map<String, Person__c> personsToUpdate = new Map<String, Person__c>();
        for (KafkaMessage__c msg : messages) {
            try {
                //check if this person already is processed in this transaction
                Person__c processedPerson = personsToUpdate.get(msg.CRM_Key__c);

                KafkaSkjerming skjerming = convertKafkaToSkjerming(msg);
                Person__c person = convertKafkaSkjermingToPersonSobject(skjerming, personByIdent, processedPerson);

                //check if person ident from kafka message exist on a person
                if (msg.CRM_Key__c == person.Name) {
                    msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;

                    //only update person if to date is in the future - or person already is employee
                    if (
                        person.INT_NavEmployeeToDatetime__c == null ||
                        person.INT_NavEmployeeToDatetime__c >= Datetime.now() ||
                        person.INT_IsNavEmployee__c
                    ) {
                        personsToUpdate.put(person.Name, person);
                    }
                } else {
                    //unknown person ident
                    msg.CRM_ErrorMessage__c = 'Unknown Person Ident';
                    msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
                }
            } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }

        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        update personsToUpdate.values();
    }

    @TestVisible
    private KafkaSkjerming convertKafkaToSkjerming(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        return KafkaSkjerming.parse(message.CRM_Key__c, decodedValue);
    }

    @TestVisible
    private Person__c convertKafkaSkjermingToPersonSobject(
        KafkaSkjerming kafkaSkjerming,
        Map<String, Person__c> personByIdent,
        Person__c processedPerson
    ) {
        Person__c person = personByIdent.get(kafkaSkjerming.personIdent);
        if (person == null)
            return new Person__c();

        person.INT_NavEmployeeToDatetime__c = kafkaSkjerming.skjermetTilDatetime;

        //check if person already is processed in this transaction
        if (processedPerson != null) {
            //use first from date
            if (processedPerson.INT_NavEmployeeFromDatetime__c < kafkaSkjerming.skjermetFraDatetime) {
                person.INT_NavEmployeeFromDatetime__c = processedPerson.INT_NavEmployeeFromDatetime__c;
            } else {
                person.INT_NavEmployeeFromDatetime__c = kafkaSkjerming.skjermetFraDatetime;
            }

            //use last to date
            if (
                person.INT_NavEmployeeToDatetime__c != null &&
                processedPerson.INT_NavEmployeeToDatetime__c > person.INT_NavEmployeeToDatetime__c
            ) {
                person.INT_NavEmployeeToDatetime__c = processedPerson.INT_NavEmployeeToDatetime__c;
            } else if (processedPerson.INT_NavEmployeeToDatetime__c == null) {
                //use null
                person.INT_NavEmployeeToDatetime__c = null;
            } else {
                person.INT_NavEmployeeToDatetime__c = kafkaSkjerming.skjermetTilDatetime;
            }
        } else {
            //processedPerson is null
            person.INT_NavEmployeeFromDatetime__c = kafkaSkjerming.skjermetFraDatetime;
            person.INT_NavEmployeeToDatetime__c = kafkaSkjerming.skjermetTilDatetime;
        }

        //check if Nav Employee is active
        if (
            kafkaSkjerming.skjermetFraDatetime <= Datetime.now() &&
            (kafkaSkjerming.skjermetTilDatetime > Datetime.now() ||
            kafkaSkjerming.skjermetTilDatetime == null)
        ) {
            person.INT_IsNavEmployee__c = true;
        }
        return person;
    }

    @TestVisible
    private Map<String, Person__c> getPersonByIdent(Set<String> personIdents) {
        Map<String, Person__c> personByIdent = new Map<String, Person__c>();
        for (Person__c person : [
            SELECT Id, Name, INT_NavEmployeeFromDatetime__c, INT_NavEmployeeToDatetime__c, INT_IsNavEmployee__c
            FROM Person__c
            WHERE Name IN :personIdents
        ]) {
            personByIdent.put(person.Name, person);
        }
        return personByIdent;
    }
}
