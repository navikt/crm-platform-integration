@IsTest
public with sharing class KafkaPDLHandlerTest {
    @IsTest
    private static void processMessagesTest() {
        // Initialize test data
        KafkaPerson person1 = new KafkaPerson();
        person1.aktoerId = '2499286497341';
        person1.fornavn = 'PETTR';
        person1.mellomnavn = 'ØÅS';
        person1.etternavn = 'FJÆLL';
        person1.identifikasjonsnummer = '16022801454';
        person1.adressebeskyttelse = 'UGRADERT';
        person1.sikkerhetstiltak = new List<String>{ 'FTUS', 'FYUS' };
        person1.kommunenummer = '5401';
        person1.region = '54';
        person1.doed = false;

        KafkaPerson person2 = new KafkaPerson();
        person2.aktoerId = '2078000855486';
        person2.fornavn = 'ROBUSTSKJØNN';
        person2.etternavn = 'BJELKE';
        person2.identifikasjonsnummer = '10064100136';
        person2.adressebeskyttelse = 'UGRADERT';
        person2.kommunenummer = '4204';
        person2.region = '42';
        person2.doed = false;

        KafkaPerson person3 = new KafkaPerson();
        person3.aktoerId = '2517286997743';
        person3.fornavn = 'PATRICK';
        person3.etternavn = 'BERGER';
        person3.identifikasjonsnummer = '14016801322';
        person3.adressebeskyttelse = 'UGRADERT';
        person3.sikkerhetstiltak = new List<String>();
        person3.kommunenummer = '3029';
        person3.region = '30';
        person3.doed = false;

        KafkaPerson person4 = new KafkaPerson();
        person4.aktoerId = '2517286887752';
        person4.fornavn = 'CARL';
        person4.etternavn = 'KRISTIANSEN';
        person4.identifikasjonsnummer = '12016801344';
        person4.adressebeskyttelse = 'STRENGT_FORTROLIG_UTLAND';
        person4.kommunenummer = '3029';
        person4.region = '30';
        person4.doed = false;

        KafkaPerson person5 = new KafkaPerson();
        person5.aktoerId = '2517277887752';
        person5.fornavn = 'NILS';
        person5.etternavn = 'JOHANSEN';
        person5.identifikasjonsnummer = '12017701344';
        person5.adressebeskyttelse = 'STRENGT_FORTROLIG';
        person5.kommunenummer = '3029';
        person5.region = '30';
        person5.doed = false;

        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person1.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(
                    Blob.valueOf(JSON.serialize(person1))
                )
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person2.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(
                    Blob.valueOf(JSON.serialize(person2))
                )
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person3.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(
                    Blob.valueOf(JSON.serialize(person3))
                )
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person4.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(
                    Blob.valueOf(JSON.serialize(person4))
                )
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person5.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(
                    Blob.valueOf(JSON.serialize(person5))
                )
            )
        );

        // Verify that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert kafkaMessages;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        // Assert that 4 Person Accounts have been inserted
        System.assertEquals(5, [SELECT COUNT() FROM Person__c]);
        // Assert that all Kafka Message records have been marked as processed
        System.assertEquals(
            5,
            [
                SELECT COUNT()
                FROM KafkaMessage__c
                WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED
            ]
        );

        Map<String, Person__c> personByPersonIdent = getPersonAccountByPersonIdent();

        // Assert that Person Account records have been created with the correct field transformation and mapping
        assertTransformation(
            person1,
            personByPersonIdent.get(person1.identifikasjonsnummer)
        );
        assertTransformation(
            person2,
            personByPersonIdent.get(person2.identifikasjonsnummer)
        );
        assertTransformation(
            person3,
            personByPersonIdent.get(person3.identifikasjonsnummer)
        );
        assertTransformationSTRENGFORTROLIG(
            person4,
            personByPersonIdent.get(person4.identifikasjonsnummer)
        );
        assertTransformationSTRENGFORTROLIG(
            person5,
            personByPersonIdent.get(person5.identifikasjonsnummer)
        );

        // Update person1 values
        person1.fornavn = 'Not Petter';
        person1.mellomnavn = null;
        person1.etternavn = 'Updated';
        person1.kommunenummer = '5150';
        person1.kommunenummer = '51';
        person1.sikkerhetstiltak = new List<String>();
        person1.adressebeskyttelse = 'FORTROLIG';

        // Insert a new Kafka Message with updated person 1 values
        KafkaMessage__c kafkaMessageUpdate = new KafkaMessage__c(
            CRM_Topic__c = 'privat-sf-person-v1',
            CRM_Key__c = person1.aktoerId,
            CRM_Value__c = EncodingUtil.base64Encode(
                Blob.valueOf(JSON.serialize(person1))
            )
        );
        insert kafkaMessageUpdate;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaPDLHandler()
            .processMessages(new List<KafkaMessage__c>{ kafkaMessageUpdate });

        // Query for the latest field values
        personByPersonIdent = getPersonAccountByPersonIdent();

        // Assert that the account name has been updated and that Gradert information is removed.
        assertTransformation(
            person1,
            personByPersonIdent.get(person1.identifikasjonsnummer)
        );
    }

    private static void assertTransformation(
        KafkaPerson kafkaPerson,
        Person__c person
    ) {
        System.assertEquals(kafkaPerson.aktoerId, person.INT_ActorId__c);
        System.assertEquals(kafkaPerson.fornavn, person.INT_FirstName__c);
        System.assertEquals(kafkaPerson.mellomnavn, person.INT_MiddleName__c);
        System.assertEquals(kafkaPerson.etternavn, person.INT_LastName__c);
        System.assertEquals(
            kafkaPerson.adressebeskyttelse,
            person.INT_Confidential__c
        );
        System.assertEquals(
            kafkaPerson.kommunenummer,
            person.INT_MunicipalityNumber__c
        );
        System.assertEquals(kafkaPerson.region, person.INT_RegionNumber__c);
        System.assertEquals(kafkaPerson.doed, person.INT_IsDeceased__c);
        System.assertEquals(
            kafkaPerson.sikkerhetstiltak != null &&
                kafkaPerson.sikkerhetstiltak.size() > 0
                ? String.join(kafkaPerson.sikkerhetstiltak, ';')
                : null,
            person.INT_SecurityMeasures__c
        );
    }

    private static void assertTransformationSTRENGFORTROLIG(
        KafkaPerson kafkaPerson,
        Person__c person
    ) {
        System.assertEquals(kafkaPerson.aktoerId, person.INT_ActorId__c);
        System.assertEquals(kafkaPerson.fornavn, person.INT_FirstName__c);
        System.assertEquals(kafkaPerson.mellomnavn, person.INT_MiddleName__c);
        System.assertEquals(kafkaPerson.etternavn, person.INT_LastName__c);
        System.assertEquals(
            kafkaPerson.adressebeskyttelse,
            person.INT_Confidential__c
        );
        System.assertEquals(null, person.INT_MunicipalityNumber__c);
        System.assertEquals(null, person.INT_RegionNumber__c);
        System.assertEquals(kafkaPerson.doed, person.INT_IsDeceased__c);
        System.assertEquals(
            kafkaPerson.sikkerhetstiltak != null &&
                kafkaPerson.sikkerhetstiltak.size() > 0
                ? String.join(kafkaPerson.sikkerhetstiltak, ';')
                : null,
            person.INT_SecurityMeasures__c
        );
    }

    private static Map<String, Person__c> getPersonAccountByPersonIdent() {
        Map<String, Person__c> personByPersonIdent = new Map<String, Person__c>();
        for (Person__c person : [
            SELECT
                Id,
                Name,
                INT_ActorId__c,
                INT_FirstName__c,
                INT_MiddleName__c,
                INT_LastName__c,
                INT_MunicipalityNumber__c,
                INT_IsDeceased__c,
                INT_SecurityMeasures__c,
                INT_Confidential__c,
                INT_RegionNumber__c
            FROM Person__c
        ]) {
            personByPersonIdent.put(person.Name, person);
        }
        return personByPersonIdent;
    }
}
