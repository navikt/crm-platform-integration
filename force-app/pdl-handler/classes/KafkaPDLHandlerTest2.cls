@IsTest
public with sharing class KafkaPDLHandlerTest2 {
    @TestSetup
    static void makeData() {
        // record for setting correct Country from Country ISO code
        List<Common_Code__c> commonCodes = new List<Common_Code__c>();

        Common_Code__c ccIND = new Common_Code__c();
        ccIND.Name = 'India';
        ccIND.CRM_Code_Set__c = 'Landkoder';
        ccIND.CRM_Code__c = 'IND';
        ccIND.CRM_Active__c = true;
        commonCodes.add(ccIND);

        Common_Code__c ccNOR = new Common_Code__c();
        ccNOR.Name = 'Norge';
        ccNOR.CRM_Code_Set__c = 'Landkoder';
        ccNOR.CRM_Code__c = 'NOR';
        ccNOR.CRM_Active__c = true;
        commonCodes.add(ccNOR);

        insert commonCodes;
    }

    /*********************
     * TESTS FOR ISO MAP *
     *********************/

    @IsTest
    static void createIsoMapTest() {
        Test.startTest();
        System.assertEquals(
            2,
            KafkaPDLHandler2.createIsoMap(
                    [
                        SELECT Name, CRM_Code__c
                        FROM Common_Code__c
                        WHERE CRM_Active__c = TRUE AND CRM_Code_Set__c IN ('Landkoder', 'LandkoderISO2')
                    ]
                )
                .size(),
            'Expected two values'
        );
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnNull() {
        Test.startTest();
        System.assertEquals(null, KafkaPDLHandler2.getCountryFromIso(null), 'Expected null in return');
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnCommonCode() {
        Test.startTest();
        System.assertNotEquals(null, KafkaPDLHandler2.getCountryFromIso('NOR'), 'Expected null in return');
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnException() {
        Test.startTest();
        try {
            KafkaPDLHandler2.getCountryFromIso('NON-EXISTING');
            System.assertEquals(true, false, 'Expected an exception to be thrown');
        } catch (KafkaPDLHandler2.IsoCodeNotFoundException e) {
            System.assertEquals(true, true, 'Expected to catch IsoCodeNotFoundException');
        } catch (Exception e) {
            System.assertEquals(true, false, 'Expected to catch IsoCodeNotFoundException not Exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void emptyPersonFieldValues() {
        Person__c p = new Person__c();
        p.INT_IsDeceased__c = true;

        Test.startTest();
        KafkaPDLHandler2.emptyPersonFieldValues(p);
        Test.stopTest();

        System.assertEquals(
            false,
            p.INT_IsDeceased__c,
            'Expected INT_IsDeceased__c to be set to false in order to handle people rising from the dead when updating from PDL.'
        );
    }

    /*******************************************
     * TESTS FOR checkLastUpdatedAndTombStones *
     *******************************************/

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the CreatedDate is older than the Person LastModifiedDate
    // KafkaMessage__c.CRM_Status__c should be set to error
    @IsTest
    static void checkLastUpdatedAndTombStonesOlderMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_ERROR,
            msg.CRM_Status__c,
            'Expected the status to be set to error'
        );
    }

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the persons INT_LastUpdatedFromPDL__c is empty
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessagesNoLastUpdated() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = null;
        insert person1;

        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the CreatedDate is after than the Person INT_LastUpdatedFromPDL__c
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // We try to process a KafkaMessage__c where we don't have any matching person in Salesforce
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessages() {
        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // We try to process several KafkaMessage__c where they all have the same key and matches a Person in Salesforce
    // KafkaMessage__c.CRM_Status__c should be set to processec on only the oldest
    @IsTest
    static void checkLastUpdatedAndTombStonesNewDuplicateMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate1 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(3).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate3 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate4 = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 +
            '"}',
            KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg2.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        KafkaMessage__c msg3 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate3 +
            '"}',
            KafkaMessage__c.class
        );
        msg3.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg3.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg3.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        KafkaMessage__c msg4 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate4 +
            '"}',
            KafkaMessage__c.class
        );
        msg4.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg4.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg4.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2, msg3, msg4 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg1.CRM_Status__c,
            'Expected the status to be processed'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg2.CRM_Status__c,
            'Expected the status to be the same'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg3.CRM_Status__c,
            'Expected the status to be processed'
        );
        System.assertEquals(KafkaMessageService.STATUS_ERROR, msg4.CRM_Status__c, 'Expected the status to be error');
    }

    //SCENARIO:
    // We try to process two several KafkaMessage__c where they all have the same actorId that matches a Person in Salesforce, but one is a tombstone
    // Both KafkaMessage__c should be processed
    @IsTest
    static void checkLastUpdatedAndTombStonesDuplicateMessagesWithTombstone() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 +
            '"}',
            KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg2.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg1.CRM_Status__c,
            'Expected the status to be pending'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg2.CRM_Status__c,
            'Expected the status to be pending'
        );
    }

    //SCENARIO:
    // We try process a KafkaMessage__c where we dont have a match a Person in Salesforce, but one is a tombstone
    // KafkaMessage__c.CRM_Status__c should be set to processed
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessagesWithTombstone() {
        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            msg1.CRM_Status__c,
            'Expected the status to be processed'
        );
    }

    @IsTest
    static void processTombstoneTest() {
        insert new Person__c(
            Name = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );

        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}')),
                CRM_Value__c = null
            )
        );

        // Verify that we have only one Account
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert kafkaMessages;
        System.debug([SELECT Id, CRM_Topic__c, CRM_Key__c, CRM_ErrorMessage__c FROM KafkaMessage__c]);
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();
        System.debug([SELECT Id, CRM_Topic__c, CRM_Key__c, CRM_ErrorMessage__c FROM KafkaMessage__c]);

        // Assert that 1 Person Accounts have been inserted
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);

        // Assert that all Kafka Message records have been marked as processed
        System.assertEquals(
            1,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]
        );

        Person__c p = [SELECT Id, INT_ActorId__c, INT_IsHasTombstone__c FROM Person__c LIMIT 1];

        System.assertEquals('1000012345678', p.INT_ActorId__c);
        System.assertEquals(true, p.INT_IsHasTombstone__c);
    }

    //Tests scenario where a person has registered
    @IsTest
    private static void processGuardianshipAndAttorneyRemovalTest() {
        //Verifies that a person that has previously been registered with either guardianship or Power of attorney
        //will get this data removed when receiving updated information

        Person__c person = new Person__c();
        person.INT_ActorId__c = '1000012345678';
        person.Name = '20000000000';
        person.INT_LastUpdatedFromPDL__c = null;
        person.INT_PowerOfAttorney__c = 'SOME TEST ATTORNEY';
        person.INT_GuardianshipOrFuturePowerOfAttorney__c = 'SOME TEST DATA';
        insert person;

        KafkaPerson2 person1 = new KafkaPerson2();
        person1.aktoerId = '1000012345678';
        person1.folkeregisterId = new List<String>{ '20000000000' };
        person1.foedselsdato = new List<String>{ '1966-08-19' };

        person1.navn = new List<KafkaPerson2.Navn>{ new KafkaPerson2.Navn() };
        person1.navn[0].fornavn = 'TULLENAVN';
        person1.navn[0].mellomnavn = 'TØRRKAT';
        person1.navn[0].etternavn = 'TULLEEFTERNAVN';

        person1.familierelasjoner = new List<KafkaPerson2.ForelderBarnRelasjoner>{
            new KafkaPerson2.ForelderBarnRelasjoner(),
            new KafkaPerson2.ForelderBarnRelasjoner()
        };
        person1.familierelasjoner[0].relatertPersonsIdent = '03056630030';
        person1.familierelasjoner[0].relatertPersonsRolle = 'MOR';
        person1.familierelasjoner[0].minRolleForPerson = 'BAR';
        person1.familierelasjoner[1].relatertPersonsIdent = '28027338188';
        person1.familierelasjoner[1].relatertPersonsRolle = 'FAR';
        person1.familierelasjoner[1].minRolleForPerson = 'BAR';

        person1.forelderBarnRelasjoner = new List<KafkaPerson2.ForelderBarnRelasjoner>{
            new KafkaPerson2.ForelderBarnRelasjoner(),
            new KafkaPerson2.ForelderBarnRelasjoner()
        };
        person1.forelderBarnRelasjoner[0].relatertPersonsIdent = '03056630030';
        person1.forelderBarnRelasjoner[0].relatertPersonsRolle = 'MOR';
        person1.forelderBarnRelasjoner[0].minRolleForPerson = 'BAR';
        person1.forelderBarnRelasjoner[1].relatertPersonsIdent = '28027338188';
        person1.forelderBarnRelasjoner[1].relatertPersonsRolle = 'FAR';
        person1.forelderBarnRelasjoner[1].minRolleForPerson = 'BAR';

        person1.folkeregisterpersonstatus = new List<String>{ 'bosatt' };

        person1.innflyttingTilNorge = new List<KafkaPerson2.InnflyttingTilNorge>{
            new KafkaPerson2.InnflyttingTilNorge(),
            new KafkaPerson2.InnflyttingTilNorge(),
            new KafkaPerson2.InnflyttingTilNorge()
        };

        person1.innflyttingTilNorge[0].fraflyttingsland = 'SWE';
        person1.innflyttingTilNorge[0].fraflyttingsstedIUtlandet = null;

        person1.innflyttingTilNorge[1].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[1].fraflyttingsstedIUtlandet = null;

        person1.innflyttingTilNorge[2].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[2].fraflyttingsstedIUtlandet = null;

        person1.adressebeskyttelse = new List<String>{ 'FORTROLIG' };

        person1.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>{
            new PersonJSONFieldObjects.Sikkerhetstiltak()
        };
        person1.sikkerhetstiltak[0].beskrivelse = 'Fysisk/telefonisk utestengelse';
        person1.sikkerhetstiltak[0].tiltaksType = 'FTUS';
        person1.sikkerhetstiltak[0].gyldigFraOgMed = '2020-09-09';
        person1.sikkerhetstiltak[0].gyldigTilOgMed = '2020-11-14';
        person1.sikkerhetstiltak[0].kontaktPersonId = 'V112253';
        person1.sikkerhetstiltak[0].kontaktPersonEnhet = '1203';

        person1.bostedsadresse = new KafkaPerson2.Adresser();
        person1.bostedsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{ new KafkaPerson2.Vegadresse() };
        person1.bostedsadresse.vegadresse[0].kommunenummer = '1000';
        person1.bostedsadresse.vegadresse[0].adressenavn = 'Tullebråten';
        person1.bostedsadresse.vegadresse[0].husnummer = '30';
        person1.bostedsadresse.vegadresse[0].husbokstav = null;
        person1.bostedsadresse.vegadresse[0].postnummer = '2164';
        person1.bostedsadresse.vegadresse[0].bydelsnummer = '216444';
        person1.bostedsadresse.vegadresse[0].koordinater = '557556.7,5580733.0,0';

        person1.bostedsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>{
            new KafkaPerson2.Matrikkeladresse()
        };
        person1.bostedsadresse.matrikkeladresse[0].kommunenummer = '1871';
        person1.bostedsadresse.matrikkeladresse[0].postnummer = '8484';
        person1.bostedsadresse.matrikkeladresse[0].bydelsnummer = '187111';
        person1.bostedsadresse.matrikkeladresse[0].koordinater = '525368.0,7636126.0,0.0';

        person1.bostedsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>{};

        person1.bostedsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{ new KafkaPerson2.UkjentBosted() };
        person1.bostedsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.oppholdsadresse = new KafkaPerson2.Adresser();
        person1.oppholdsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{ new KafkaPerson2.Vegadresse() };
        person1.oppholdsadresse.vegadresse[0].kommunenummer = '2023';
        person1.oppholdsadresse.vegadresse[0].adressenavn = 'LYDERS FISK AS';
        person1.oppholdsadresse.vegadresse[0].husnummer = null;
        person1.oppholdsadresse.vegadresse[0].husbokstav = null;
        person1.oppholdsadresse.vegadresse[0].postnummer = '9771';
        person1.oppholdsadresse.vegadresse[0].bydelsnummer = null;
        person1.oppholdsadresse.vegadresse[0].koordinater = null;

        person1.oppholdsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>{};

        person1.oppholdsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>{};

        person1.oppholdsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{ new KafkaPerson2.UkjentBosted() };
        person1.oppholdsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.statsborgerskap = new List<String>{ 'NOR' };

        person1.sivilstand = new List<KafkaPerson2.Sivilstand>{ new KafkaPerson2.Sivilstand() };
        person1.sivilstand[0].type = 'UGIFT';
        person1.sivilstand[0].gyldigFraOgMed = null;
        person1.sivilstand[0].relatertVedSivilstand = null;

        person1.kommunenummerFraGt = '0301';
        person1.kommunenummerFraAdresse = '1000';
        person1.bydelsnummerFraGt = '030102';
        person1.bydelsnummerFraAdresse = '216444';

        person1.kjoenn = new List<String>{ 'MANN' };

        person1.doedsfall = new List<KafkaPerson2.Doedsfall>{
            new KafkaPerson2.Doedsfall(),
            new KafkaPerson2.Doedsfall()
        };
        person1.doedsfall[0].doedsdato = '1962-07-08';
        person1.doedsfall[0].master = 'PDL';

        person1.doedsfall[1].doedsdato = '1962-07-09';
        person1.doedsfall[1].master = 'FREG';

        person1.telefonnummer = new List<KafkaPerson2.Telefonnummer>{ new KafkaPerson2.Telefonnummer() };
        person1.telefonnummer[0].landskode = '+47';
        person1.telefonnummer[0].nummer = '95911111';
        person1.telefonnummer[0].prioritet = '1';

        person1.utflyttingFraNorge = new List<KafkaPerson2.UtflyttingFraNorge>{ new KafkaPerson2.UtflyttingFraNorge() };
        person1.utflyttingFraNorge[0].tilflyttingsland = 'IND';
        person1.utflyttingFraNorge[0].tilflyttingsstedIUtlandet = null;

        person1.talesspraaktolk = new List<String>{ 'AM' };

        //fullmakt and vergemål are now empty lists -> meaning these attributes should be nulled
        person1.fullmakt = new List<PersonJSONFieldObjects.Fullmakt>{};

        person1.vergemaalEllerFremtidsfullmakt = new List<PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt>{};

        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
            )
        );

        // Act
        Test.startTest();
        insert kafkaMessages;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        Person__c updatedPerson = [
            SELECT Id, INT_PowerOfAttorney__c, INT_GuardianshipOrFuturePowerOfAttorney__c
            FROM Person__c
            WHERE INT_ActorId__c = '1000012345678'
        ];

        System.assertEquals(
            null,
            updatedPerson.INT_GuardianshipOrFuturePowerOfAttorney__c,
            'Guardianship or future power of attorney not correcly removed'
        );
        System.assertEquals(null, updatedPerson.INT_PowerOfAttorney__c, 'Power of attorney was not correctly removed');
    }

    @IsTest
    private static void processMessagesTest() {
        KafkaPerson2 person1 = new KafkaPerson2();
        person1.aktoerId = '1000012345678';
        person1.folkeregisterId = new List<String>{ '20000000000' };
        person1.foedselsdato = new List<String>{ '1966-08-19' };

        person1.navn = new List<KafkaPerson2.Navn>{ new KafkaPerson2.Navn() };
        person1.navn[0].fornavn = 'TULLENAVN';
        person1.navn[0].mellomnavn = 'TØRRKAT';
        person1.navn[0].etternavn = 'TULLEEFTERNAVN';

        person1.forelderBarnRelasjoner = new List<KafkaPerson2.ForelderBarnRelasjoner>{
            new KafkaPerson2.ForelderBarnRelasjoner(),
            new KafkaPerson2.ForelderBarnRelasjoner()
        };
        person1.forelderBarnRelasjoner[0].relatertPersonsIdent = '03056630030';
        person1.forelderBarnRelasjoner[0].relatertPersonsRolle = 'MOR';
        person1.forelderBarnRelasjoner[0].minRolleForPerson = 'BAR';
        person1.forelderBarnRelasjoner[1].relatertPersonsIdent = '28027338188';
        person1.forelderBarnRelasjoner[1].relatertPersonsRolle = 'FAR';
        person1.forelderBarnRelasjoner[1].minRolleForPerson = 'BAR';

        person1.folkeregisterpersonstatus = new List<String>{ 'bosatt' };

        person1.innflyttingTilNorge = new List<KafkaPerson2.InnflyttingTilNorge>{
            new KafkaPerson2.InnflyttingTilNorge(),
            new KafkaPerson2.InnflyttingTilNorge(),
            new KafkaPerson2.InnflyttingTilNorge()
        };

        person1.innflyttingTilNorge[0].fraflyttingsland = 'SWE';
        person1.innflyttingTilNorge[0].fraflyttingsstedIUtlandet = null;

        person1.innflyttingTilNorge[1].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[1].fraflyttingsstedIUtlandet = null;

        person1.innflyttingTilNorge[2].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[2].fraflyttingsstedIUtlandet = null;

        person1.adressebeskyttelse = new List<String>{ 'FORTROLIG' };

        person1.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>{
            new PersonJSONFieldObjects.Sikkerhetstiltak()
        };
        person1.sikkerhetstiltak[0].beskrivelse = 'Fysisk/telefonisk utestengelse';
        person1.sikkerhetstiltak[0].tiltaksType = 'FTUS';
        person1.sikkerhetstiltak[0].gyldigFraOgMed = '2020-09-09';
        person1.sikkerhetstiltak[0].gyldigTilOgMed = '2020-11-14';
        person1.sikkerhetstiltak[0].kontaktPersonId = 'V112253';
        person1.sikkerhetstiltak[0].kontaktPersonEnhet = '1203';

        person1.bostedsadresse = new KafkaPerson2.Adresser();
        person1.bostedsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{ new KafkaPerson2.Vegadresse() };
        person1.bostedsadresse.vegadresse[0].kommunenummer = '1000';
        person1.bostedsadresse.vegadresse[0].adressenavn = 'Tullebråten';
        person1.bostedsadresse.vegadresse[0].husnummer = '30';
        person1.bostedsadresse.vegadresse[0].husbokstav = null;
        person1.bostedsadresse.vegadresse[0].postnummer = '2164';
        person1.bostedsadresse.vegadresse[0].bydelsnummer = '216444';
        person1.bostedsadresse.vegadresse[0].koordinater = '557556.7,5580733.0,0';

        person1.bostedsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>{
            new KafkaPerson2.Matrikkeladresse()
        };
        person1.bostedsadresse.matrikkeladresse[0].kommunenummer = '1871';
        person1.bostedsadresse.matrikkeladresse[0].postnummer = '8484';
        person1.bostedsadresse.matrikkeladresse[0].bydelsnummer = '187111';
        person1.bostedsadresse.matrikkeladresse[0].koordinater = '525368.0,7636126.0,0.0';

        person1.bostedsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>{};

        person1.bostedsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{ new KafkaPerson2.UkjentBosted() };
        person1.bostedsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.oppholdsadresse = new KafkaPerson2.Adresser();
        person1.oppholdsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{ new KafkaPerson2.Vegadresse() };
        person1.oppholdsadresse.vegadresse[0].kommunenummer = '2023';
        person1.oppholdsadresse.vegadresse[0].adressenavn = 'LYDERS FISK AS';
        person1.oppholdsadresse.vegadresse[0].husnummer = null;
        person1.oppholdsadresse.vegadresse[0].husbokstav = null;
        person1.oppholdsadresse.vegadresse[0].postnummer = '9771';
        person1.oppholdsadresse.vegadresse[0].bydelsnummer = null;
        person1.oppholdsadresse.vegadresse[0].koordinater = null;

        person1.oppholdsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>{};

        person1.oppholdsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>{};

        person1.oppholdsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{ new KafkaPerson2.UkjentBosted() };
        person1.oppholdsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.statsborgerskap = new List<String>{ 'NOR' };

        person1.sivilstand = new List<KafkaPerson2.Sivilstand>{ new KafkaPerson2.Sivilstand() };
        person1.sivilstand[0].type = 'UGIFT';
        person1.sivilstand[0].gyldigFraOgMed = null;
        person1.sivilstand[0].relatertVedSivilstand = null;

        person1.kommunenummerFraGt = '0301';
        person1.kommunenummerFraAdresse = '1000';
        person1.bydelsnummerFraGt = '030102';
        person1.bydelsnummerFraAdresse = '216444';

        person1.kjoenn = new List<String>{ 'MANN' };

        person1.doedsfall = new List<KafkaPerson2.Doedsfall>{
            new KafkaPerson2.Doedsfall(),
            new KafkaPerson2.Doedsfall()
        };
        person1.doedsfall[0].doedsdato = '1962-07-08';
        person1.doedsfall[0].master = 'PDL';

        person1.doedsfall[1].doedsdato = '1962-07-09';
        person1.doedsfall[1].master = 'FREG';

        person1.telefonnummer = new List<KafkaPerson2.Telefonnummer>{ new KafkaPerson2.Telefonnummer() };
        person1.telefonnummer[0].landskode = '+47';
        person1.telefonnummer[0].nummer = '95911111';
        person1.telefonnummer[0].prioritet = '1';

        person1.utflyttingFraNorge = new List<KafkaPerson2.UtflyttingFraNorge>{ new KafkaPerson2.UtflyttingFraNorge() };
        person1.utflyttingFraNorge[0].tilflyttingsland = 'IND';
        person1.utflyttingFraNorge[0].tilflyttingsstedIUtlandet = null;

        person1.talesspraaktolk = new List<String>{ 'AM' };

        person1.fullmakt = new List<PersonJSONFieldObjects.Fullmakt>{ new PersonJSONFieldObjects.Fullmakt() };
        person1.fullmakt[0].motpartsRolle = 'FULLMEKTIG';
        person1.fullmakt[0].motpartsPersonident = '40000000000';
        person1.fullmakt[0].omraader = new List<String>{ '*' };
        person1.fullmakt[0].gyldigFraOgMed = '2020-02-05';
        person1.fullmakt[0].gyldigTilOgMed = '2021-02-05';

        person1.vergemaalEllerFremtidsfullmakt = new List<PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt>{
            new PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt()
        };
        person1.vergemaalEllerFremtidsfullmakt[0].type = 'voksen';
        person1.vergemaalEllerFremtidsfullmakt[0].embete = 'fylkesmannenIVestfoldOgTelemark';
        person1.vergemaalEllerFremtidsfullmakt[0].navn = null;
        person1.vergemaalEllerFremtidsfullmakt[0].motpartsPersonident = '30000000000';
        person1.vergemaalEllerFremtidsfullmakt[0].omfang = 'personligeOgOekonomiskeInteresser';
        person1.vergemaalEllerFremtidsfullmakt[0].omfangetErInnenPersonligOmraade = true;

        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
            )
        );

        // Verify that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert kafkaMessages;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        List<KafkaMessage__c> processedKafkamessages = [
            SELECT Id, CRM_Status__c, CreatedDate
            FROM KafkaMessage__c
            WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED
        ];

        // Assert that 1 Person Accounts have been inserted
        System.assertEquals(1, [SELECT COUNT() FROM Person__c], 'Expected that 1 Person have been inserted');

        // Assert that all Kafka Message records have been marked as processed
        System.assertEquals(1, processedKafkamessages.size(), 'Expected to have one KafkaMessage marked as processed');

        Map<String, Person__c> personByPersonIdent = getPersonAccountByPersonIdent();

        System.assertEquals(
            processedKafkamessages[0].CreatedDate,
            personByPersonIdent.get(person1.folkeregisterId[0]).INT_LastUpdatedFromPDL__c,
            'Expected that Last Updated PDL matched the Created Date or the Kafka message'
        );

        // Assert that Person Account records have been created with the correct field transformation and mapping
        assertTransformation(person1, personByPersonIdent.get(person1.folkeregisterId[0]));

        // Update person1 values
        person1.bostedsadresse.vegadresse.remove(0);
        person1.oppholdsadresse.vegadresse.remove(0);

        // Insert a new Kafka Message with updated person 1 values
        KafkaMessage__c kafkaMessageUpdate = new KafkaMessage__c(
            CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
            CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
        );
        insert kafkaMessageUpdate;
        kafkaMessageUpdate = [
            SELECT Id, CRM_Key__c, CRM_Status__c, CRM_Topic__c, CRM_Value__c, CreatedDate
            FROM KafkaMessage__c
            WHERE Id = :kafkaMessageUpdate.Id
        ];

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaPDLHandler2().processMessages(new List<KafkaMessage__c>{ kafkaMessageUpdate });

        // Query for the latest field values
        personByPersonIdent = getPersonAccountByPersonIdent();

        System.assertEquals(
            kafkaMessageUpdate.CreatedDate,
            personByPersonIdent.get(person1.folkeregisterId[0]).INT_LastUpdatedFromPDL__c,
            'Expected that Last Updated PDL matched the Created Date or the Kafka message'
        );

        // Assert that the account name has been updated and that Gradert information is removed.
        assertTransformation(person1, personByPersonIdent.get(person1.folkeregisterId[0]));
        System.assertEquals(0, [SELECT COUNT() FROM Application_Log__c], 'Did not expect anything to be logged');
    }

    private static void assertTransformation(KafkaPerson2 kafkaPerson, Person__c person) {
        Boolean confidentialAddress = KafkaPDLHandler2.ADR_BESKYTTELSES_GRADERING.get(person.INT_Confidential__c) > 2;
        System.assertEquals(kafkaPerson.aktoerId, person.INT_ActorId__c);
        System.assertEquals(kafkaPerson.folkeregisterId[0], person.Name);
        System.assertEquals(kafkaPerson.foedselsdato[0], person.INT_DateOfBirth__c);
        System.assertEquals(kafkaPerson.Navn[0].fornavn, person.INT_FirstName__c);
        System.assertEquals(kafkaPerson.Navn[0].mellomnavn, person.INT_MiddleName__c);
        System.assertEquals(kafkaPerson.Navn[0].etternavn, person.INT_LastName__c);

        if (kafkaPerson.familierelasjoner != null) {
            System.assertEquals(JSON.serialize(kafkaPerson.familierelasjoner), person.INT_FamilyRelations__c);
        }
        System.assertEquals(JSON.serialize(kafkaPerson.forelderBarnRelasjoner), person.INT_FamilyRelations__c);

        System.assertEquals(
            kafkaPerson.folkeregisterpersonstatus[0].toLowerCase(),
            person.INT_LegalStatus__c.toLowerCase()
        );

        System.assertEquals(
            KafkaPDLHandler2.getCountryFromIso(kafkaPerson.innflyttingTilNorge[2].fraflyttingsland) == null
                ? null
                : KafkaPDLHandler2.getCountryFromIso(kafkaPerson.innflyttingTilNorge[2].fraflyttingsland).Id,
            person.INT_MovedFromCountry__c
        );
        System.assertEquals(kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet, person.INT_MovedFromPlace__c);
        System.assertEquals(kafkaPerson.adressebeskyttelse[0], person.INT_Confidential__c);

        System.assertEquals(JSON.serialize(kafkaPerson.sikkerhetstiltak), person.INT_SecurityMeasures__c);

        // bostedsadresser
        // assumption: vegadresse has first pri, then ukjentbosted
        if (kafkaPerson.bostedsadresse.vegadresse.size() > 0) {
            System.assertEquals(
                KafkaPDLHandler2.addressCreator(
                        new List<String>{
                            kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,
                            kafkaPerson.bostedsadresse.vegadresse[0].husnummer,
                            kafkaPerson.bostedsadresse.vegadresse[0].husbokstav
                        }
                    ) == ''
                    ? null
                    : KafkaPDLHandler2.addressCreator(
                          new List<String>{
                              kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,
                              kafkaPerson.bostedsadresse.vegadresse[0].husnummer,
                              kafkaPerson.bostedsadresse.vegadresse[0].husbokstav
                          }
                      ),
                person.INT_ResidentialAddress__c
            );
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(
                kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer,
                person.INT_AddressMunicipalityNumber__c
            );
            System.assertEquals(
                kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer,
                person.INT_AddressDistrictNumber__c
            );
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].koordinater, person.INT_Coordinates__c);
        } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 0) {
            System.assertEquals(
                kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer,
                person.INT_ResidentialZipCode__c
            );
            System.assertEquals(
                kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer,
                person.INT_AddressMunicipalityNumber__c
            );
            System.assertEquals(
                kafkaPerson.bostedsadresse.matrikkeladresse[0].bydelsnummer,
                person.INT_AddressDistrictNumber__c
            );
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        } else if (kafkaPerson.bostedsadresse.ukjentBosted.size() > 0) {
            person.INT_MunicipalityNumber__c = confidentialAddress
                ? ''
                : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune;
        }

        // oppholdsadresser
        // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
        if (kafkaPerson.oppholdsadresse.vegadresse.size() > 0) {
            System.assertEquals(
                KafkaPDLHandler2.addressCreator(
                        new List<String>{
                            kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn,
                            kafkaPerson.oppholdsadresse.vegadresse[0].husnummer,
                            kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav
                        }
                    ) == ''
                    ? null
                    : KafkaPDLHandler2.addressCreator(
                          new List<String>{
                              kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn,
                              kafkaPerson.oppholdsadresse.vegadresse[0].husnummer,
                              kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav
                          }
                      ),
                person.INT_TemporaryAddress__c
            );
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].postnummer, person.INT_TemporaryZipCode__c);
            System.assertEquals(
                kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer,
                person.INT_TemporaryMunicipalityNumber__c
            );
            System.assertEquals(
                kafkaPerson.oppholdsadresse.vegadresse[0].koordinater,
                person.INT_TemporaryCoordinates__c
            );
        } else if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 0) {
            System.assertEquals(
                kafkaPerson.oppholdsadresse.matrikkeladresse[0].postnummer,
                person.INT_ResidentialZipCode__c
            );
            System.assertEquals(kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        } else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 0) {
            System.assertEquals(
                KafkaPDLHandler2.addressCreator(
                        new List<String>{
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer,
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet,
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn,
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode,
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted,
                            kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade
                        }
                    ) == ''
                    ? null
                    : KafkaPDLHandler2.addressCreator(
                          new List<String>{
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer,
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet,
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn,
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode,
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted,
                              kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade
                          }
                      ),
                person.INT_TemporaryAddress__c
            );
            System.assertEquals(
                kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode,
                person.INT_TemporaryCountryCode__c
            );
        } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 0) {
            System.assertEquals(
                confidentialAddress ? '' : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune,
                person.INT_TemporaryMunicipalityNumber__c
            );
        }

        System.assertEquals(
            KafkaPDLHandler2.crateCitizenshipString(kafkaPerson.statsborgerskap),
            person.INT_Citizenships__c
        );
        System.assertEquals(kafkaPerson.sivilstand[0].type, person.INT_MaritalStatus__c);
        System.assertEquals(
            KafkaPDLHandler2.dateCreator(kafkaPerson.sivilstand[0].gyldigFraOgMed),
            person.INT_MaritalStatusDate__c
        );
        System.assertEquals(kafkaPerson.sivilstand[0].relatertVedSivilstand, person.INT_MaritalRelation__c);

        System.assertEquals(kafkaPerson.kjoenn[0].toLowerCase(), person.INT_Sex__c.toLowerCase());
        System.assertEquals(
            kafkaPerson.doedsfall[0].doedsdato == null ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato),
            person.INT_DateOfDeath__c
        );
        System.assertEquals(kafkaPerson.doedsfall[0].doedsdato != null ? true : false, person.INT_IsDeceased__c);
        for (KafkaPerson2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            if (tlf.prioritet == '1')
                System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone1__c);
            else if (tlf.prioritet == '2')
                System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone2__c);
        }
        System.assertEquals(
            KafkaPDLHandler2.getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland) == null
                ? null
                : KafkaPDLHandler2.getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland).Id,
            person.INT_MovedToCountry__c
        );
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet, person.INT_MovedToPlace__c);
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet, person.INT_MovedToPlace__c);

        System.assertEquals(
            KafkaPDLHandler2.safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk),
            person.INT_SpokenLanguageIntepreter__c
        );
    }

    private static Map<String, Person__c> getPersonAccountByPersonIdent() {
        Map<String, Person__c> personByPersonIdent = new Map<String, Person__c>();
        for (Person__c person : [
            SELECT
                Id,
                Name,
                INT_ActorId__c,
                INT_AddressDistrictNumber__c,
                INT_AddressMunicipalityNumber__c,
                INT_Citizenships__c,
                INT_Confidential__c,
                INT_Coordinates__c,
                INT_DateOfBirth__c,
                INT_DateOfDeath__c,
                INT_DistrictNumber__c,
                INT_FamilyRelations__c,
                INT_FirstName__c,
                INT_GTDistrictNumber__c,
                INT_GTMunicipalityNumber__c,
                INT_IsDeceased__c,
                INT_IsNavEmployee__c,
                INT_LastName__c,
                INT_LastUpdatedFromPDL__c,
                INT_LastUpdatedFromKRR__c,
                INT_LegalStatus__c,
                INT_MaritalRelation__c,
                INT_MaritalStatus__c,
                INT_MaritalStatusDate__c,
                INT_MiddleName__c,
                INT_MovedFromCountry__c,
                INT_MovedFromPlace__c,
                INT_MovedToCountry__c,
                INT_MovedToPlace__c,
                INT_MunicipalityNumber__c,
                INT_Phone1__c,
                INT_Phone2__c,
                INT_RegionNumber__c,
                INT_ResidentialAddress__c,
                INT_ResidentialZipCode__c,
                INT_SecurityMeasures__c,
                INT_Sex__c,
                INT_SpokenLanguageIntepreter__c,
                INT_TemporaryAddress__c,
                INT_TemporaryCountryCode__c,
                INT_TemporaryMunicipalityNumber__c,
                INT_TemporaryZipCode__c,
                INT_TemporaryCoordinates__c
            FROM Person__c
        ]) {
            personByPersonIdent.put(person.Name, person);
            System.debug(person.INT_SecurityMeasures__c);
        }
        return personByPersonIdent;
    }
}
