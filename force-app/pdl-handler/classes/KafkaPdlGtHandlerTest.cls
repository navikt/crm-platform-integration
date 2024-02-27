@IsTest
private with sharing class KafkaPdlGtHandlerTest {

    @isTest
    static void testCreatePersonFromGt() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.geografisktilknytning-v1',
                CRM_Key__c = '1017419408436',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["1017419408436","74194084361"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"1337","gtBydel":null,"gtLand":null,"regel":"2"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(kafkaMessages);
        Test.stopTest();
        List<Person__c> pl = [SELECT Id from Person__c where INT_ActorId__c = '1017419408436'];
        Assert.areEqual(1, pl.size(), 'Expected one person inserted.');
    }

    /*
    @IsTest
    static void setGTFromKommunenummer() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.kommunenummerFraGt = '0301';
        kafkaPerson.bydelsnummerFraGt = '030101';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(
            '0301',
            person.INT_GTMunicipalityNumber__c,
            'Expected INT_GTMunicipalityNumber__c to be set'
        );
        System.assertEquals('030101', person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('03', person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('0301', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('030101', person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    @IsTest
    static void setGTFromKommunenummerNoDistrict() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.kommunenummerFraGt = '0301';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(
            '0301',
            person.INT_GTMunicipalityNumber__c,
            'Expected INT_GTMunicipalityNumber__c to be set'
        );
        System.assertEquals(null, person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('03', person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('0301', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    @IsTest
    static void setGTFromKommunenummerFromAddressOnly() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.bostedsadresse.vegadresse.add(new KafkaPerson2.Vegadresse());
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = 'Testveien';
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = '1';
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = 'A';
        kafkaPerson.bostedsadresse.vegadresse[0].postnummer = '0001';
        kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer = '4321';
        kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer = '030110';
        kafkaPerson.bostedsadresse.vegadresse[0].koordinater = 'x=354424, y=6862099, z=0';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setAddress(person, kafkaPerson);
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(null, person.INT_GTMunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('4321', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('030110', person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }
    */
}
