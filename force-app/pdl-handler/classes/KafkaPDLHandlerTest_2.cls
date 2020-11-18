@IsTest
public with sharing class KafkaPDLHandlerTest_2 {
    @IsTest private static void processMessagesTest() {
        // Initialize test data
        String s = '{\n' +
                '  "aktoerId": "1000012345678",\n' +
                '  "folkeregisterId": "20000000000",\n' +
                '  "navn": [\n' +
                '    {\n' +
                '      "fornavn": "TULLENAVN",\n' +
                '      "mellomnavn": "TØRRKAT",\n' +
                '      "etternavn": "TULLEEFTERNAVN"\n' +
                '    }\n' +
                '  ],\n' +
                '  "familierelasjoner": [\n' +
                '    {\n' +
                '      "relatertPersonsIdent": "03056630030",\n' +
                '      "relatertPersonsRolle": "MOR",\n' +
                '      "minRolleForPerson": "BARN"\n' +
                '    },\n' +
                '    {\n' +
                '      "relatertPersonsIdent": "28027338188",\n' +
                '      "relatertPersonsRolle": "FAR",\n' +
                '      "minRolleForPerson": "BARN"\n' +
                '    }\n' +
                '  ],\n' +
                '  "folkeregisterpersonstatus": [\n' +
                '    "bosatt"\n' +
                '  ],\n' +
                '  "innflyttingTilNorge": [\n' +
                '    {\n' +
                '      "fraflyttingsland": "IND",\n' +
                '      "fraflyttingsstedIUtlandet": "Unseen data"\n' +
                '    }\n' +
                '  ],\n' +
                '  "adressebeskyttelse": [\n' +
                '    "FORTROLIG"\n' +
                '  ],\n' +
                '  "sikkerhetstiltak": [\n' +
                '    {\n' +
                '      "beskrivelse": "Fysisk/telefonisk utestengelse",\n' +
                '      "tiltaksType": "FTUS",\n' +
                '      "gyldigFraOgMed": "2020-09-09",\n' +
                '      "gyldigTilOgMed": "2020-11-14",\n' +
                '      "kontaktpersonId": "V112253",\n' +
                '      "kontaktpersonEnhet": "1203"\n' +
                '    }\n' +
                '  ],\n' +
                '  "bostedsadresse": {\n' +
                '    "vegadresse": [\n' +
                '      {\n' +
                '        "kommunenummer": "1000",\n' +
                '        "adressenavn": "Tullebråten",\n' +
                '        "husnummer": "30",\n' +
                '        "husbokstav": null,\n' +
                '        "postnummer": "2164",\n' +
                '        "bydelsnummer": "216444",\n' +
                '        "koordinater": "557556.7,5580733.0,0"\n' +
                '      }\n' +
                '    ],\n' +
                '    "matrikkeladresse": [\n' +
                '      {\n' +
                '        "kommunenummer": "1871",\n' +
                '        "postnummer": "8484",\n' +
                '        "bydelsnummer": "187111",\n' +
                '        "koordinater": "525368.0,7636126.0,0.0"\n' +
                '      }\n' +
                '    ],\n' +
                '    "utenlandskAdresse": [\n' +
                '      {\n' +
                '        "adressenavnNummer": "Gatenavn unseen",\n' +
                '        "bygningEtasjeLeilighet": "navn etage pa bygg unseen",\n' +
                '        "postboksNummerNavn": "P.O.Box 1234 Place Unseen",\n' +
                '        "postkode": "SE-12345 Unseen",\n' +
                '        "bySted": "Haworth Unseen",\n' +
                '        "regionDistriktOmraade": "Yorkshire Unseen",\n' +
                '        "landkode": "On alpha-x standard Unseen"\n' +
                '      }\n' +
                '    ],\n' +
                '    "ukjentBosted": [\n' +
                '      {\n' +
                '        "bostedskommune": "5001"\n' +
                '      }\n' +
                '    ]\n' +
                '  },\n' +
                '  "oppholdsadresse": {\n' +
                '    "vegadresse": [\n' +
                '      {\n' +
                '        "kommunenummer": "2023",\n' +
                '        "adressenavn": "LYDERS FISK AS",\n' +
                '        "husnummer": null,\n' +
                '        "husbokstav": null,\n' +
                '        "postnummer": "9771",\n' +
                '        "bydelsnummer": null,\n' +
                '        "koordinater": null\n' +
                '      }\n' +
                '    ],\n' +
                '    "matrikkeladresse": [\n' +
                '      {\n' +
                '        "kommunenummer": "1000",\n' +
                '        "postnummer": "8000",\n' +
                '        "bydelsnummer": "187000",\n' +
                '        "koordinater": "525001.0,7636001.0,0.0"\n' +
                '      }\n' +
                '    ],\n' +
                '    "utenlandskAdresse": [\n' +
                '      {\n' +
                '        "adressenavnNummer": "Opphold Gatenavn unseen",\n' +
                '        "bygningEtasjeLeilighet": "navn etage pa bygg unseen",\n' +
                '        "postboksNummerNavn": "P.O.Box 1234 Place Unseen",\n' +
                '        "postkode": "SE-12345 Unseen",\n' +
                '        "bySted": "Haworth Unseen",\n' +
                '        "regionDistriktOmraade": "Yorkshire Unseen",\n' +
                '        "landkode": "On alpha-x standard Unseen"\n' +
                '      }\n' +
                '    ],\n' +
                '    "ukjentBosted": [\n' +
                '      \n' +
                '    ]\n' +
                '  },\n' +
                '  "statsborgerskap": [\n' +
                '    "NOR",\n' +
                '    "SVE"\n' +
                '  ],\n' +
                '  "sivilstand": [\n' +
                '    {\n' +
                '      "type": "UGIFT",\n' +
                '      "gyldigFraOgMed": null,\n' +
                '      "relatertVedSivilstand": null\n' +
                '    }\n' +
                '  ],\n' +
                '  "kommunenummerFraGt": "030",\n' +
                '  "kommunenummerFraAdresse": "1000",\n' +
                '  "bydelsnummerFraGt": "030102",\n' +
                '  "bydelsnummerFraAdresse": "216444",\n' +
                '  "kjoenn": [\n' +
                '    "MANN"\n' +
                '  ],\n' +
                '  "doedsfall": [\n' +
                '    {\n' +
                '      "doedsdato": "1962-07-08",\n' +
                '      "master": "Freg"\n' +
                '    }\n' +
                '  ],\n' +
                '  "telefonnummer": [\n' +
                '    {\n' +
                '      "landskode": "+47",\n' +
                '      "nummer": "95911111",\n' +
                '      "prioritet": 1\n' +
                '    }\n' +
                '  ],\n' +
                '  "utflyttingFraNorge": [\n' +
                '    {\n' +
                '      "tilflyttingsland": "IND",\n' +
                '      "tilflyttingsstedIUtlandet": "Unseen data"\n' +
                '    }\n' +
                '  ],\n' +
                '  "talesspraaktolk": [\n' +
                '    "AM"\n' +
                '  ]\n' +
                '}';

        KafkaPerson_2 person1 = new KafkaPerson_2();
        person1.aktoerId = '1000012345678';
        person1.folkeregisterId = '20000000000';

        person1.navn = new List<KafkaPerson_2.Navn>{new KafkaPerson_2.Navn()};
        person1.navn[0].fornavn = 'TULLENAVN';
        person1.navn[0].mellomnavn = 'TØRRKAT';
        person1.navn[0].etternavn = 'TULLEEFTERNAVN';

        person1.familierelasjoner = new List<KafkaPerson_2.Familierelasjoner>{new KafkaPerson_2.Familierelasjoner(), new KafkaPerson_2.Familierelasjoner()};
        person1.familierelasjoner[0].relatertPersonsIdent = '03056630030';
        person1.familierelasjoner[0].relatertPersonsRolle = 'MOR';
        person1.familierelasjoner[0].minRolleForPerson = 'BAR';
        person1.familierelasjoner[1].relatertPersonsIdent = '28027338188';
        person1.familierelasjoner[1].relatertPersonsRolle = 'FAR';
        person1.familierelasjoner[1].minRolleForPerson = 'BAR';

        person1.folkeregisterpersonstatus = new List<String>{'bosatt'};

        person1.innflyttingTilNorge = new List<KafkaPerson_2.InnflyttingTilNorge>{
                new KafkaPerson_2.InnflyttingTilNorge()
        };
        person1.innflyttingTilNorge[0].fraflyttingsland = 'IND';
        person1.innflyttingTilNorge[0].fraflyttingsstedIUtlandet = null;

        person1.adressebeskyttelse = new List<String>{'FORTROLIG'};

        person1.sikkerhetstiltak = new List<KafkaPerson_2.Sikkerhetstiltak>{new KafkaPerson_2.Sikkerhetstiltak()};
        person1.sikkerhetstiltak[0].beskrivelse = 'Fysisk/telefonisk utestengelse';
        person1.sikkerhetstiltak[0].tiltaksType = 'FTUS';
        person1.sikkerhetstiltak[0].gyldigFraOgMed = '2020-09-09';
        person1.sikkerhetstiltak[0].gyldigTilOgMed = '2020-11-14';
        person1.sikkerhetstiltak[0].kontaktPersonId = 'V112253';
        person1.sikkerhetstiltak[0].kontaktPersonEnhet = '1203';

        person1.bostedsadresse = new KafkaPerson_2.Adresser();
        person1.bostedsadresse.vegadresse = new List<KafkaPerson_2.Vegadresse>{new KafkaPerson_2.Vegadresse()};
        person1.bostedsadresse.vegadresse[0].kommunenummer = '1000';
        person1.bostedsadresse.vegadresse[0].adressenavn = 'Tullebråten';
        person1.bostedsadresse.vegadresse[0].husnummer = '30';
        person1.bostedsadresse.vegadresse[0].husbokstav = null;
        person1.bostedsadresse.vegadresse[0].postnummer = '2164';
        person1.bostedsadresse.vegadresse[0].bydelsnummer = '216444';
        person1.bostedsadresse.vegadresse[0].koordinater = '557556.7,5580733.0,0';

        person1.bostedsadresse.matrikkeladresse = new List<KafkaPerson_2.Matrikkeladresse>{new KafkaPerson_2.Matrikkeladresse()};
        person1.bostedsadresse.matrikkeladresse[0].kommunenummer = '1871';
        person1.bostedsadresse.matrikkeladresse[0].postnummer = '8484';
        person1.bostedsadresse.matrikkeladresse[0].bydelsnummer = '187111';
        person1.bostedsadresse.matrikkeladresse[0].koordinater = '525368.0,7636126.0,0.0';

        person1.bostedsadresse.utenlandskAdresse = new List<KafkaPerson_2.UtenlandskAdresse>{
                new KafkaPerson_2.UtenlandskAdresse()
        };

        person1.bostedsadresse.ukjentBosted = new List<KafkaPerson_2.UkjentBosted>{new KafkaPerson_2.UkjentBosted()};
        person1.bostedsadresse.ukjentBosted[0].bostedskommune = '5001';

        person1.oppholdsadresse = new KafkaPerson_2.Adresser();
        person1.oppholdsadresse.vegadresse = new List<KafkaPerson_2.Vegadresse>{new KafkaPerson_2.Vegadresse()};
        person1.oppholdsadresse.vegadresse[0].kommunenummer = '2023';
        person1.oppholdsadresse.vegadresse[0].adressenavn = 'LYDERS FISK AS';
        person1.oppholdsadresse.vegadresse[0].husnummer = null;
        person1.oppholdsadresse.vegadresse[0].husbokstav = null;
        person1.oppholdsadresse.vegadresse[0].postnummer = '9771';
        person1.oppholdsadresse.vegadresse[0].bydelsnummer = null;
        person1.oppholdsadresse.vegadresse[0].koordinater = null;

        person1.oppholdsadresse.matrikkeladresse = new List<KafkaPerson_2.Matrikkeladresse>{};

        person1.statsborgerskap = new List<String>{'NOR'};

        person1.sivilstand = new List<KafkaPerson_2.Sivilstand>{new KafkaPerson_2.Sivilstand()};
        person1.sivilstand[0].type = 'UGIFT';
        person1.sivilstand[0].gyldigFraOgMed = null;
        person1.sivilstand[0].relatertVedSivilstand = null;

        person1.kommunenummerFraGt = '030';
        person1.kommunenummerFraAdresse = '1000';
        person1.bydelsnummerFraGt = '030102';
        person1.bydelsnummerFraAdresse = '216444';

        person1.kjoenn = new List<String>{'MANN'};

        person1.doedsfall = new List<KafkaPerson_2.Doedsfall>{new KafkaPerson_2.Doedsfall()};
        person1.doedsfall[0].doedsdato = '1962-07-08';
        person1.doedsfall[0].master = 'Freg';

        person1.telefonnummer = new List<KafkaPerson_2.Telefonnummer>{new KafkaPerson_2.Telefonnummer()};
        person1.telefonnummer[0].landskode = '+47';
        person1.telefonnummer[0].nummer = '95911111';
        person1.telefonnummer[0].prioritet = '1';

        person1.utflyttingFraNorge = new List<KafkaPerson_2.UtflyttingFraNorge>{new KafkaPerson_2.UtflyttingFraNorge()};
        person1.utflyttingFraNorge[0].tilflyttingsland = 'IND';
        person1.utflyttingFraNorge[0].tilflyttingsstedIUtlandet = null;

        person1.talesspraaktolk = new List<String>{'AM'};




        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v2',
                CRM_Key__c = person1.aktoerId,
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
        assertTransformation(person1, personByPersonIdent.get(person1.folkeregisterId));

        // Update person1 values
        person1.bostedsadresse.vegadresse.remove(0);
//        person1.oppholdsadresse.vegadresse.remove(0);
//        person1.kommunenummerFraGt = KafkaPDLHandler_2.PDL_ERROR_STRING;

        // Insert a new Kafka Message with updated person 1 values
        KafkaMessage__c kafkaMessageUpdate = new KafkaMessage__c(
                CRM_Topic__c = 'privat-sf-person-v2',
                CRM_Key__c = person1.aktoerId,
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(person1)))
        );
        insert kafkaMessageUpdate;

        // Run method explicitly because we cannot rely on the queuable job again in the test context (only one start/stoptest block is allowed)
        new KafkaPDLHandler_2().processMessages(new List<KafkaMessage__c>{
                kafkaMessageUpdate
        });

        // Query for the latest field values
        personByPersonIdent = getPersonAccountByPersonIdent();

        // Assert that the account name has been updated and that Gradert information is removed.
        assertTransformation(person1, personByPersonIdent.get(person1.folkeregisterId));

    }


    private static void assertTransformation(KafkaPerson_2 kafkaPerson, Person__c person) {
        Boolean confidentialAddress = KafkaPDLHandler_2.ADR_BESKYTTELSES_GRADERING.get(person.INT_Confidential__c) > 2;
        System.assertEquals(kafkaPerson.aktoerId , person.INT_ActorId__c);
        System.assertEquals(kafkaPerson.folkeregisterId , person.Name);
        System.assertEquals(kafkaPerson.Navn[0].fornavn , person.INT_FirstName__c);
        System.assertEquals(kafkaPerson.Navn[0].mellomnavn , person.INT_MiddleName__c);
        System.assertEquals(kafkaPerson.Navn[0].etternavn , person.INT_LastName__c);

        System.assertEquals(JSON.serialize(kafkaPerson.familierelasjoner) , person.INT_FamilyRelations__c);

        System.assertEquals(KafkaPDLHandler_2.getCountryFromIso(kafkaPerson.innflyttingTilNorge[0].fraflyttingsland) , person.INT_MovedFromCountry__c);
        System.assertEquals(kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet , person.INT_MovedFromPlace__c);
        System.assertEquals(kafkaPerson.adressebeskyttelse[0] , person.INT_Confidential__c);

        System.assertEquals(JSON.serialize(kafkaPerson.sikkerhetstiltak) , person.INT_SecurityMeasures__c);

        // bostedsadresser
        // assumption: vegadresse has first pri, then ukjentbosted
        if (kafkaPerson.bostedsadresse.vegadresse.size()>0) {
            System.assertEquals(KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,  kafkaPerson.bostedsadresse.vegadresse[0].husnummer,  kafkaPerson.bostedsadresse.vegadresse[0].husbokstav}) == '' ? null : KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,  kafkaPerson.bostedsadresse.vegadresse[0].husnummer,  kafkaPerson.bostedsadresse.vegadresse[0].husbokstav}), person.INT_ResidentialAddress__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.bostedsadresse.vegadresse[0].koordinater, person.INT_Coordinates__c);
        } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size()>0) {
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.bostedsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        }
        else if (kafkaPerson.bostedsadresse.ukjentBosted.size()>0) {
            person.INT_MunicipalityNumber__c = confidentialAddress ? '' : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune;
        }

        // oppholdsadresser
        // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
        if (kafkaPerson.oppholdsadresse.vegadresse.size()>0) {
            System.assertEquals(KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn, kafkaPerson.oppholdsadresse.vegadresse[0].husnummer, kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav}) == '' ? null : KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn, kafkaPerson.oppholdsadresse.vegadresse[0].husnummer, kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav}), person.INT_TemporaryAddress__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].postnummer, person.INT_TemporaryZipCode__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer, person.INT_TemporaryMunicipalityNumber__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.vegadresse[0].koordinater, person.INT_TemporaryCoordinates__c);
        } else if (kafkaPerson.oppholdsadresse.matrikkeladresse.size()>0) {
            System.assertEquals(kafkaPerson.oppholdsadresse.matrikkeladresse[0].postnummer, person.INT_ResidentialZipCode__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater, person.INT_Coordinates__c);
        }
        else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size()>0) {
            System.assertEquals(KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade}) == '' ? null : KafkaPDLHandler_2.addressCreator(new List<String>{kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade}), person.INT_TemporaryAddress__c);
            System.assertEquals(kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode, person.INT_TemporaryCountryCode__c);
        } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size()>0) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune, person.INT_TemporaryMunicipalityNumber__c);
        }

        System.assertEquals(KafkaPDLHandler_2.safelyJoinMultiPicklistString(kafkaPerson.statsborgerskap) , person.INT_Citizenships__c);
        System.assertEquals(kafkaPerson.sivilstand[0].type , person.INT_MaritalStatus__c);
        System.assertEquals(KafkaPDLHandler_2.dateCreator(kafkaPerson.sivilstand[0].gyldigFraOgMed) , person.INT_MaritalStatusDate__c);
        System.assertEquals(kafkaPerson.sivilstand[0].relatertVedSivilstand , person.INT_MaritalRelation__c);

        if (kafkaPerson.kommunenummerFraGt != KafkaPDLHandler_2.PDL_ERROR_STRING) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.kommunenummerFraGt , person.INT_MunicipalityNumber__c);
        } else if (kafkaPerson.kommunenummerFraAdresse != KafkaPDLHandler_2.PDL_ERROR_STRING) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.kommunenummerFraAdresse , person.INT_MunicipalityNumber__c);
        }
        if (kafkaPerson.bydelsnummerFraGt != KafkaPDLHandler_2.PDL_ERROR_STRING) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.bydelsnummerFraGt.left(2) , person.INT_RegionNumber__c);
        } else if (kafkaPerson.bydelsnummerFraAdresse != KafkaPDLHandler_2.PDL_ERROR_STRING) {
            System.assertEquals(confidentialAddress ? '' : kafkaPerson.bydelsnummerFraAdresse.left(2), person.INT_RegionNumber__c);
        }

        System.assertEquals(KafkaPDLHandler_2.sexTranslator(kafkaPerson.kjoenn[0]) , person.INT_Sex__c);
        System.assertEquals(kafkaPerson.doedsfall[0].doedsdato == '0' ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato) , person.INT_DateOfDeath__c);
        System.assertEquals(kafkaPerson.doedsfall[0].doedsdato != null ? true : false, person.INT_IsDeceased__c);
        for (KafkaPerson_2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            if (tlf.prioritet == '1') System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone1__c);
            else if (tlf.prioritet == '2') System.assertEquals(tlf.landskode + tlf.nummer, person.INT_Phone2__c);
        }
        System.assertEquals(KafkaPDLHandler_2.getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland) , person.INT_MovedToCountry__c);
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet , person.INT_MovedToPlace__c);
        System.assertEquals(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet , person.INT_MovedToPlace__c);


        System.assertEquals(KafkaPDLHandler_2.safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk) , person.INT_SpokenLanguageIntepreter__c);
    }

    private static Map<String, Person__c> getPersonAccountByPersonIdent() {
        Map<String, Person__c> personByPersonIdent = new Map<String, Person__c>();
        for (Person__c person : [SELECT Id, Name, INT_ActorId__c, INT_Citizenships__c, INT_Confidential__c, INT_Country__c, INT_DateOfDeath__c, INT_District__c, INT_FirstName__c, INT_IsDeceased__c, INT_IsNavEmployee__c, INT_KrrEmail__c, INT_KrrIntegrationStatus__c, INT_KrrMobilePhone__c, INT_LastName__c, INT_LastUpdatedFromKRR__c, INT_LegalStatus__c, INT_MaritalStatus__c, INT_MaritalStatusDate__c, INT_MiddleName__c, INT_MovedFromCountry__c, INT_MovedFromPlace__c, INT_MovedToCountry__c, INT_MovedToPlace__c, INT_MunicipalityNumber__c, INT_Phone1__c, INT_Phone2__c, INT_RegionNumber__c, INT_ResidentialAddress__c, INT_ResidentialZipCode__c, INT_SecurityMeasures__c, INT_Sex__c, INT_SpokenLanguageIntepreter__c, INT_TemporaryAddress__c, INT_TemporaryCountryCode__c, INT_TemporaryMunicipalityNumber__c, INT_TemporaryZipCode__c, INT_FamilyRelations__c, INT_Coordinates__c, INT_TemporaryCoordinates__c, INT_MaritalRelation__c FROM Person__c]) {
            personByPersonIdent.put(person.Name, person);
            System.debug(person.INT_SecurityMeasures__c);
        }
        return personByPersonIdent;
    }
    
}