/**
 * ! KafkaPDLHandler is DEPRECATED
 */
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
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person2.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person2)))
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person3.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person3)))
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person4.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person4)))
            )
        );
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v1',
                CRM_Key__c = person5.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person5)))
            )
        );

        // Verify that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert kafkaMessages;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        System.assertEquals(
            5,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_ERROR]
        );
    }
}
