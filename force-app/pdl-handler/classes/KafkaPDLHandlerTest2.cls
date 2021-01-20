@IsTest
public with sharing class KafkaPDLHandlerTest2 {
    
    @TestSetup
    static void makeData(){
        // record for setting correct Country from Country ISO code
        List<Common_Code__c> commonCodes = new List<Common_Code__c>();
    
        Common_Code__c ccIND = new Common_Code__c();
        ccIND.Name = 'India';
        ccIND.CRM_Code_Set__c = 'Landkoder';
        ccIND.CRM_Code__c = 'IND';
        ccIND.CRM_Active__c = TRUE;
        commonCodes.add(ccIND);
    
        Common_Code__c ccNOR = new Common_Code__c();
        ccNOR.Name = 'Norge';
        ccNOR.CRM_Code_Set__c = 'Landkoder';
        ccNOR.CRM_Code__c = 'NOR';
        ccNOR.CRM_Active__c = TRUE;
        commonCodes.add(ccNOR);
    
        insert commonCodes;
    }

    @IsTest static void setMaritialStatusNullList() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Sivilstand> maritialStatuses;

        Test.startTest();
        person = new KafkaPDLHandler2().setMaritialStatus(person,maritialStatuses);
        Test.stopTest();

        System.assertEquals(null, person.INT_MaritalStatus__c, 'Expected to have a null value');
        System.assertEquals(null, person.INT_MaritalStatusDate__c, 'Expected to have a null value');
        System.assertEquals(null, person.INT_MaritalRelation__c, 'Expected to have a null value');
    }

    @IsTest static void setMaritialStatusEmptyList() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Sivilstand> maritialStatuses = new List<KafkaPerson2.Sivilstand>();

        Test.startTest();
        person = new KafkaPDLHandler2().setMaritialStatus(person,maritialStatuses);
        Test.stopTest();

        System.assertEquals(null, person.INT_MaritalStatus__c, 'Expected to have a null value');
        System.assertEquals(null, person.INT_MaritalStatusDate__c, 'Expected to have a null value');
        System.assertEquals(null, person.INT_MaritalRelation__c, 'Expected to have a null value');
    }

    @IsTest static void setMaritialStatusOneValue() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Sivilstand> maritialStatuses = new List<KafkaPerson2.Sivilstand>();
        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[0].type = 'UGIFT';
        maritialStatuses[0].gyldigFraOgMed = null;
        maritialStatuses[0].relatertVedSivilstand = null;

        Test.startTest();
        person = new KafkaPDLHandler2().setMaritialStatus(person,maritialStatuses);
        Test.stopTest();

        System.assertEquals('UGIFT', person.INT_MaritalStatus__c, 'Expected that the only value is added');
        System.assertEquals(null, person.INT_MaritalStatusDate__c, 'Expected to have a null value');
        System.assertEquals(null, person.INT_MaritalRelation__c, 'Expected to have a null value');
    }

    @IsTest static void setMaritialStatusMultipleValues() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Sivilstand> maritialStatuses = new List<KafkaPerson2.Sivilstand>();
        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[0].type = 'UGIFT';
        maritialStatuses[0].gyldigFraOgMed = null;
        maritialStatuses[0].relatertVedSivilstand = null;

        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[1].type = 'GIFT';
        maritialStatuses[1].gyldigFraOgMed = '2001-06-20';
        maritialStatuses[1].relatertVedSivilstand = null;
        
        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[2].type = 'ENKE_ELLER_ENKEMANN';
        maritialStatuses[2].gyldigFraOgMed = '2021-06-20';
        maritialStatuses[2].relatertVedSivilstand = null;

        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[3].type = 'UGIFT';
        maritialStatuses[3].gyldigFraOgMed = '2020-05-20';
        maritialStatuses[3].relatertVedSivilstand = null;

        maritialStatuses.add(new KafkaPerson2.Sivilstand());
        maritialStatuses[0].type = 'GIFT';
        maritialStatuses[0].gyldigFraOgMed = null;
        maritialStatuses[0].relatertVedSivilstand = null;

        Test.startTest();
        person = new KafkaPDLHandler2().setMaritialStatus(person,maritialStatuses);
        Test.stopTest();

        System.assertEquals('ENKE_ELLER_ENKEMANN', person.INT_MaritalStatus__c, 'Expected the most recent element to be set');
        System.assertEquals(Date.newInstance(2021, 6, 20), person.INT_MaritalStatusDate__c, 'Expected the most recent element to be set');
        System.assertEquals(null, person.INT_MaritalRelation__c, 'Expected to have a null value');
    }

    @IsTest private static void setInnflyttingNorgeNullList() {
        Person__c person = new Person__c();

        List<KafkaPerson2.InnflyttingTilNorge> innflyttingTilNorge;

        Test.startTest();
        person = new KafkaPDLHandler2().setInnflyttingtilNorge(person, innflyttingTilNorge);
        Test.stopTest();

        System.assertEquals(null, person.INT_MovedFromCountry__c, 'Expected no value to be set');
        System.assertEquals(null, person.INT_MovedFromPlace__c, 'Expected no value to be set');
    }

    @IsTest private static void setInnflyttingNorgeNoCountry() {
        Person__c person = new Person__c();

        List<KafkaPerson2.InnflyttingTilNorge> innflyttingTilNorge = new List<KafkaPerson2.InnflyttingTilNorge>();
        innflyttingTilNorge.add(new KafkaPerson2.InnflyttingTilNorge());
        innflyttingTilNorge[0].fraflyttingsland='';
        innflyttingTilNorge[0].fraflyttingsstedIUtlandet='test sted';

        Test.startTest();
        person = new KafkaPDLHandler2().setInnflyttingtilNorge(person, innflyttingTilNorge);
        Test.stopTest();

        System.assertEquals(null, person.INT_MovedFromCountry__c, 'Expected no value to be set');
        System.assertEquals(null, person.INT_MovedFromPlace__c, 'Expected no value to be set');
    }

    @IsTest private static void setInnflyttingNorgeWithCountry() {
        Person__c person = new Person__c();

        List<KafkaPerson2.InnflyttingTilNorge> innflyttingTilNorge = new List<KafkaPerson2.InnflyttingTilNorge>();
        innflyttingTilNorge.add(new KafkaPerson2.InnflyttingTilNorge());
        innflyttingTilNorge[0].fraflyttingsland='IND';
        innflyttingTilNorge[0].fraflyttingsstedIUtlandet='test sted';

        Test.startTest();
        person = new KafkaPDLHandler2().setInnflyttingtilNorge(person, innflyttingTilNorge);
        Test.stopTest();

        System.assertNotEquals(null, person.INT_MovedFromCountry__c, 'Expected the country common code to be set');
        System.assertEquals('test sted', person.INT_MovedFromPlace__c, 'Expected the free text value');
    }

    @IsTest private static void setUtflyttingFraNorgeNullList() {
        Person__c person = new Person__c();
        
        List<KafkaPerson2.UtflyttingFraNorge> utflyttingFraNorge;

        Test.startTest();
        person = new KafkaPDLHandler2().setUtflyttingFraNorge(person, utflyttingFraNorge);
        Test.stopTest();

        System.assertEquals(null, person.INT_MovedToCountry__c, 'Expected no value to be set');
        System.assertEquals(null, person.INT_MovedToPlace__c, 'Expected no value to be set');
    }

    @IsTest private static void setUtflyttingFraNorgeNoCountry() {
        Person__c person = new Person__c();

        List<KafkaPerson2.UtflyttingFraNorge> utflyttingFraNorge = new List<KafkaPerson2.UtflyttingFraNorge>();
        utflyttingFraNorge.add(new KafkaPerson2.UtflyttingFraNorge());
        utflyttingFraNorge[0].tilflyttingsland='';
        utflyttingFraNorge[0].tilflyttingsstedIUtlandet='test sted';

        Test.startTest();
        person = new KafkaPDLHandler2().setUtflyttingFraNorge(person, utflyttingFraNorge);
        Test.stopTest();

        System.assertEquals(null, person.INT_MovedToCountry__c, 'Expected no value to be set');
        System.assertEquals(null, person.INT_MovedToPlace__c, 'Expected no value to be set');
    }

    @IsTest private static void setUtflyttingFraNorgeWithCountry() {
        Person__c person = new Person__c();

        List<KafkaPerson2.UtflyttingFraNorge> utflyttingFraNorge = new List<KafkaPerson2.UtflyttingFraNorge>();
        utflyttingFraNorge.add(new KafkaPerson2.UtflyttingFraNorge());
        utflyttingFraNorge[0].tilflyttingsland='IND';
        utflyttingFraNorge[0].tilflyttingsstedIUtlandet='test sted';

        Test.startTest();
        person = new KafkaPDLHandler2().setUtflyttingFraNorge(person, utflyttingFraNorge);
        Test.stopTest();

        System.assertNotEquals(null, person.INT_MovedToCountry__c, 'Expected the country common code to be set');
        System.assertEquals('test sted', person.INT_MovedToPlace__c, 'Expected the free text value');
    }

    @IsTest private static void setDateOfDeathNullList() {
        Person__c person = new Person__c();

        Test.startTest();
        person = new KafkaPDLHandler2().setDoedsfall(person, null);
        Test.stopTest();

        System.assertEquals(false, person.INT_IsDeceased__c, 'Expected that the person is alive, not deceased if date of death is not set');
        System.assertEquals(null, person.INT_DateOfDeath__c, 'This to be null since we have not added any date of death');
    }

    @IsTest private static void setDateOfDeathEmptyList() {
        Person__c person = new Person__c();

        Test.startTest();
        person = new KafkaPDLHandler2().setDoedsfall(person, new List<KafkaPerson2.Doedsfall>());
        Test.stopTest();

        System.assertEquals(false, person.INT_IsDeceased__c, 'Expected that the person is alive, not deceased if date of death is not set');
        System.assertEquals(null, person.INT_DateOfDeath__c, 'This to be null since we have not added any date of death');
    }

    @IsTest private static void setDateOfDeathListOneElement() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Doedsfall> listDatesOfDeath = new List<KafkaPerson2.Doedsfall>();
        listDatesOfDeath.add(new KafkaPerson2.Doedsfall());
        listDatesOfDeath[0].doedsdato = '2021-01-01';
        listDatesOfDeath[0].master = 'PDL';

        Test.startTest();
        person = new KafkaPDLHandler2().setDoedsfall(person, listDatesOfDeath);
        Test.stopTest();

        System.assertEquals(true, person.INT_IsDeceased__c, 'Expected that the person is alive, not deceased if date of death is not set');
        System.assertEquals(Date.newInstance(2021, 1, 1), person.INT_DateOfDeath__c, 'Excepted date of death to be set');
    }

    @IsTest private static void setDateOfDeathListMultipleElements() {
        Person__c person = new Person__c();

        List<KafkaPerson2.Doedsfall> listDatesOfDeath = new List<KafkaPerson2.Doedsfall>();
        listDatesOfDeath.add(new KafkaPerson2.Doedsfall());
        listDatesOfDeath[0].doedsdato = '2021-01-01';
        listDatesOfDeath[0].master = 'PDL';
        listDatesOfDeath.add(new KafkaPerson2.Doedsfall());
        listDatesOfDeath[1].doedsdato = '2019-01-01';
        listDatesOfDeath[1].master = 'PDL';
        listDatesOfDeath.add(new KafkaPerson2.Doedsfall());
        listDatesOfDeath[2].doedsdato = '2020-01-01';
        listDatesOfDeath[2].master = 'PDL';

        Test.startTest();
        person = new KafkaPDLHandler2().setDoedsfall(person, listDatesOfDeath);
        Test.stopTest();

        System.assertEquals(true, person.INT_IsDeceased__c, 'Expected that the person is alive, not deceased if date of death is not set');
        System.assertEquals(Date.newInstance(2019, 1, 1), person.INT_DateOfDeath__c, 'Excepted date of death to be set');
    }

    @IsTest private static void processMessagesTest() {

        KafkaPerson2 person1 = new KafkaPerson2();
        person1.aktoerId = '1000012345678';
        person1.folkeregisterId = new List<String>{'20000000000'};
        person1.foedselsdato = new List<String>{'1966-08-19'};

        person1.navn = new List<KafkaPerson2.Navn>{
                new KafkaPerson2.Navn()
        };
        person1.navn[0].fornavn = 'TULLENAVN';
        person1.navn[0].mellomnavn = 'TØRRKAT';
        person1.navn[0].etternavn = 'TULLEEFTERNAVN';

        person1.familierelasjoner = new List<KafkaPerson2.Familierelasjoner>{
                new KafkaPerson2.Familierelasjoner(), new KafkaPerson2.Familierelasjoner()
        };
        person1.familierelasjoner[0].relatertPersonsIdent = '03056630030';
        person1.familierelasjoner[0].relatertPersonsRolle = 'MOR';
        person1.familierelasjoner[0].minRolleForPerson = 'BAR';
        person1.familierelasjoner[1].relatertPersonsIdent = '28027338188';
        person1.familierelasjoner[1].relatertPersonsRolle = 'FAR';
        person1.familierelasjoner[1].minRolleForPerson = 'BAR';

        person1.folkeregisterpersonstatus = new List<String>{'bosatt'};

        person1.innflyttingTilNorge = new List<KafkaPerson2.InnflyttingTilNorge>{
                new KafkaPerson2.InnflyttingTilNorge()
        };
        person1.innflyttingTilNorge[0].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[0].fraflyttingsstedIUtlandet = null;

        person1.adressebeskyttelse = new List<String>{'FORTROLIG'};

        person1.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>{new PersonJSONFieldObjects.Sikkerhetstiltak()};
        person1.sikkerhetstiltak[0].beskrivelse = 'Fysisk/telefonisk utestengelse';
        person1.sikkerhetstiltak[0].tiltaksType = 'FTUS';
        person1.sikkerhetstiltak[0].gyldigFraOgMed = '2020-09-09';
        person1.sikkerhetstiltak[0].gyldigTilOgMed = '2020-11-14';
        person1.sikkerhetstiltak[0].kontaktPersonId = 'V112253';
        person1.sikkerhetstiltak[0].kontaktPersonEnhet = '1203';

        person1.bostedsadresse = new KafkaPerson2.Adresser();
        person1.bostedsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{
                new KafkaPerson2.Vegadresse()
        };
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

        person1.bostedsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{
                new KafkaPerson2.UkjentBosted()
        };
        person1.bostedsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.oppholdsadresse = new KafkaPerson2.Adresser();
        person1.oppholdsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>{
                new KafkaPerson2.Vegadresse()
        };
        person1.oppholdsadresse.vegadresse[0].kommunenummer = '2023';
        person1.oppholdsadresse.vegadresse[0].adressenavn = 'LYDERS FISK AS';
        person1.oppholdsadresse.vegadresse[0].husnummer = null;
        person1.oppholdsadresse.vegadresse[0].husbokstav = null;
        person1.oppholdsadresse.vegadresse[0].postnummer = '9771';
        person1.oppholdsadresse.vegadresse[0].bydelsnummer = null;
        person1.oppholdsadresse.vegadresse[0].koordinater = null;

        person1.oppholdsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>{};

        person1.oppholdsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>{};

        person1.oppholdsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>{
                new KafkaPerson2.UkjentBosted()
        };
        person1.oppholdsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.statsborgerskap = new List<String>{'NOR'};

        person1.sivilstand = new List<KafkaPerson2.Sivilstand>{
                new KafkaPerson2.Sivilstand()
        };
        person1.sivilstand[0].type = 'UGIFT';
        person1.sivilstand[0].gyldigFraOgMed = null;
        person1.sivilstand[0].relatertVedSivilstand = null;

        person1.kommunenummerFraGt = '030';
        person1.kommunenummerFraAdresse = '1000';
        person1.bydelsnummerFraGt = '030102';
        person1.bydelsnummerFraAdresse = '216444';

        person1.kjoenn = new List<String>{'MANN'};

        person1.doedsfall = new List<KafkaPerson2.Doedsfall>{
                new KafkaPerson2.Doedsfall()
        };
        person1.doedsfall[0].doedsdato = '1962-07-08';
        person1.doedsfall[0].master = 'Freg';

        person1.telefonnummer = new List<KafkaPerson2.Telefonnummer>{
                new KafkaPerson2.Telefonnummer()
        };
        person1.telefonnummer[0].landskode = '+47';
        person1.telefonnummer[0].nummer = '95911111';
        person1.telefonnummer[0].prioritet = '1';

        person1.utflyttingFraNorge = new List<KafkaPerson2.UtflyttingFraNorge>{
                new KafkaPerson2.UtflyttingFraNorge()
        };
        person1.utflyttingFraNorge[0].tilflyttingsland = 'IND';
        person1.utflyttingFraNorge[0].tilflyttingsstedIUtlandet = null;

        person1.talesspraaktolk = new List<String>{'AM'};

        person1.fullmakt = new List<PersonJSONFieldObjects.Fullmakt>{new PersonJSONFieldObjects.Fullmakt()};
        person1.fullmakt[0].motpartsRolle = 'FULLMEKTIG';
        person1.fullmakt[0].motpartsPersonident = '40000000000';
        person1.fullmakt[0].omraader = new List<String>{'*'};
        person1.fullmakt[0].gyldigFraOgMed = '2020-02-05';
        person1.fullmakt[0].gyldigTilOgMed = '2021-02-05';

        person1.vergemaalEllerFremtidsfullmakt = new List<PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt>{new PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt()};
        person1.vergemaalEllerFremtidsfullmakt[0].type = 'voksen';
        person1.vergemaalEllerFremtidsfullmakt[0].embete = 'fylkesmannenIVestfoldOgTelemark';
        person1.vergemaalEllerFremtidsfullmakt[0].navn = null;
        person1.vergemaalEllerFremtidsfullmakt[0].motpartsPersonident = '30000000000';
        person1.vergemaalEllerFremtidsfullmakt[0].omfang = 'personligeOgOekonomiskeInteresser';
        person1.vergemaalEllerFremtidsfullmakt[0].omfangetErInnenPersonligOmraade = true;




        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}')),
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
        ));

        // Verify that no Accounts have been inserted
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

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
        System.assertEquals(1, [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]);

        Map<String, Person__c> personByPersonIdent = getPersonAccountByPersonIdent();

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

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaPDLHandler2().processMessages(new List<KafkaMessage__c>{
                kafkaMessageUpdate
        });

        // Query for the latest field values
        personByPersonIdent = getPersonAccountByPersonIdent();

        // Assert that the account name has been updated and that Gradert information is removed.
        assertTransformation(person1, personByPersonIdent.get(person1.folkeregisterId[0]));

    }


    private static void assertTransformation(KafkaPerson2 kafkaPerson, Person__c person) {
        Boolean confidentialAddress = KafkaPDLHandler2.ADR_BESKYTTELSES_GRADERING.get(person.INT_Confidential__c) > 2;
        System.assertEquals(kafkaPerson.aktoerId , person.INT_ActorId__c);
        System.assertEquals(kafkaPerson.folkeregisterId[0] , person.Name);
        System.assertEquals(kafkaPerson.foedselsdato[0] , person.INT_DateOfBirth__c);
        System.assertEquals(kafkaPerson.Navn[0].fornavn , person.INT_FirstName__c);
        System.assertEquals(kafkaPerson.Navn[0].mellomnavn , person.INT_MiddleName__c);
        System.assertEquals(kafkaPerson.Navn[0].etternavn , person.INT_LastName__c);

        System.assertEquals(JSON.serialize(kafkaPerson.familierelasjoner) , person.INT_FamilyRelations__c);

        System.assertEquals(kafkaPerson.folkeregisterpersonstatus[0].toLowerCase(), person.INT_LegalStatus__c.toLowerCase());

        System.assertEquals(KafkaPDLHandler2.getCountryFromIso(kafkaPerson.innflyttingTilNorge[0].fraflyttingsland) == null ? null : KafkaPDLHandler2.getCountryFromIso(kafkaPerson.innflyttingTilNorge[0].fraflyttingsland).Id , person.INT_MovedFromCountry__c);
        System.assertEquals(kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet , person.INT_MovedFromPlace__c);
        System.assertEquals(kafkaPerson.adressebeskyttelse[0] , person.INT_Confidential__c);

        System.assertEquals(JSON.serialize(kafkaPerson.sikkerhetstiltak) , person.INT_SecurityMeasures__c);

        // bostedsadresser
        // assumption: vegadresse has first pri, then ukjentbosted
        if (kafkaPerson.bostedsadresse.vegadresse.size()>0) {
            System.assertEquals(KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,  kafkaPerson.bostedsadresse.vegadresse[0].husnummer,  kafkaPerson.bostedsadresse.vegadresse[0].husbokstav}) == '' ? null : KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,  kafkaPerson.bostedsadresse.vegadresse[0].husnummer,  kafkaPerson.bostedsadresse.vegadresse[0].husbokstav}), person.INT_ResidentialAddress__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer, person.INT_AddressMunicipalityNumber__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer, person.INT_AddressDistrictNumber__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].koordinater, person.INT_Coordinates__c);
        } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size()>0) {
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer, person.INT_AddressMunicipalityNumber__c);
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].bydelsnummer, person.INT_AddressDistrictNumber__c);
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        }
        else if (kafkaPerson.bostedsadresse.ukjentBosted.size()>0) {
            person.INT_MunicipalityNumber__c = confidentialAddress ? '' : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune;
        }

        // oppholdsadresser
        // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
        if (kafkaPerson.oppholdsadresse.vegadresse.size()>0) {
            System.assertEquals(KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn, kafkaPerson.oppholdsadresse.vegadresse[0].husnummer, kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav}) == '' ? null : KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn, kafkaPerson.oppholdsadresse.vegadresse[0].husnummer, kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav}), person.INT_TemporaryAddress__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].postnummer, person.INT_TemporaryZipCode__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer, person.INT_TemporaryMunicipalityNumber__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].koordinater, person.INT_TemporaryCoordinates__c);
        } else if (kafkaPerson.oppholdsadresse.matrikkeladresse.size()>0) {
            System.assertEquals(kafkaPerson.oppholdsadresse.matrikkeladresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        }
        else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size()>0) {
            System.assertEquals(KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade}) == '' ? null : KafkaPDLHandler2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade}), person.INT_TemporaryAddress__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode, person.INT_TemporaryCountryCode__c);
        } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size()>0) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune, person.INT_TemporaryMunicipalityNumber__c);
        }

        System.assertEquals(KafkaPDLHandler2.crateCitizenshipString(kafkaPerson.statsborgerskap) , person.INT_Citizenships__c);
        System.assertEquals(kafkaPerson.sivilstand[0].type , person.INT_MaritalStatus__c);
        System.assertEquals(KafkaPDLHandler2.dateCreator(kafkaPerson.sivilstand[0].gyldigFraOgMed) , person.INT_MaritalStatusDate__c);
        System.assertEquals(kafkaPerson.sivilstand[0].relatertVedSivilstand , person.INT_MaritalRelation__c);

        System.assertEquals(kafkaPerson.kjoenn[0].toLowerCase() , person.INT_Sex__c.toLowerCase());
        System.assertEquals(kafkaPerson.doedsfall[0].doedsdato == null ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato) , person.INT_DateOfDeath__c);
        System.assertEquals(kafkaPerson.doedsfall[0].doedsdato != null ? true : false, person.INT_IsDeceased__c);
        for (KafkaPerson2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            if (tlf.prioritet == '1') System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone1__c);
            else if (tlf.prioritet == '2') System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone2__c);
        }
        System.assertEquals(KafkaPDLHandler2.getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland) == null ? null : KafkaPDLHandler2.getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland).Id, person.INT_MovedToCountry__c);
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet , person.INT_MovedToPlace__c);
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet , person.INT_MovedToPlace__c);


        System.assertEquals(KafkaPDLHandler2.safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk) , person.INT_SpokenLanguageIntepreter__c);
    }

    private static Map<String, Person__c> getPersonAccountByPersonIdent() {
        Map<String, Person__c> personByPersonIdent = new Map<String, Person__c>();
        for (Person__c person : [SELECT Id, Name, INT_ActorId__c, INT_Citizenships__c, INT_Confidential__c, INT_DateOfBirth__c, INT_DateOfDeath__c, INT_DistrictNumber__c, INT_AddressDistrictNumber__c, INT_GTDistrictNumber__c, INT_FirstName__c, INT_IsDeceased__c, INT_IsNavEmployee__c,  INT_LastName__c, INT_LastUpdatedFromKRR__c, INT_LegalStatus__c, INT_MaritalStatus__c, INT_MaritalStatusDate__c, INT_MiddleName__c, INT_MovedFromCountry__c, INT_MovedFromPlace__c, INT_MovedToCountry__c, INT_MovedToPlace__c, INT_MunicipalityNumber__c, INT_AddressMunicipalityNumber__c, INT_GTMunicipalityNumber__c, INT_Phone1__c, INT_Phone2__c, INT_RegionNumber__c, INT_ResidentialAddress__c, INT_ResidentialZipCode__c, INT_SecurityMeasures__c, INT_Sex__c, INT_SpokenLanguageIntepreter__c, INT_TemporaryAddress__c, INT_TemporaryCountryCode__c, INT_TemporaryMunicipalityNumber__c, INT_TemporaryZipCode__c, INT_FamilyRelations__c, INT_Coordinates__c, INT_TemporaryCoordinates__c, INT_MaritalRelation__c FROM Person__c]) {
            personByPersonIdent.put(person.Name, person);
            System.debug(person.INT_SecurityMeasures__c);
        }
        return personByPersonIdent;
    }
    
}