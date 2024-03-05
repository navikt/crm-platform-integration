/**
 * Tests for KafkaPdlGtHandler, i.e. geografisk tilknytning.
 * Assumes KafkaPdlPersondokumentHandler is working as expected, as we will test
 * against persons inserted using that.
 */
@IsTest
private with sharing class KafkaPdlGtHandlerTest {

    static void printLogs() {
        for (Application_Log__c l : [SELECT Category__c, Log_Level__c, Log_Message__c from Application_Log__c]) {
            System.debug('log entry: ' + l.Category__c + ' ' + l.Log_Level__c + ': ' + l.Log_Message__c);
        }
    }

    /**
     * Create a message for inserting a person document.
     * See KafkaPdlPersondokumentHandlerTest for more information.
     * Explicitly set status; which would otherwise only get called when using
     * KafkaMessageService (i.e. upon insert).
     */
    private static KafkaMessage__c createPersonDocumentMessage(
        String aktorId,
        KafkaPerson3 kafkaPerson
    ) {
        KafkaMessage__c kafkaMessage = new KafkaMessage__c(
            CRM_Key__c = aktorId,
            CRM_Value__c = (kafkaPerson == null ?
                null :
                EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(kafkaPerson)))),
            CRM_Topic__c = 'pdl.pdl-persondokument-tagged-v1',
            CRM_Status__c = KafkaMessageService.STATUS_PENDING
        );
        return kafkaMessage;
    }

    /**
     * Inserts kafka person into the database
     */
    private static void insertBaseKafkaPerson(String aktorId, KafkaPerson3 kp) {
        KafkaMessage__c[] messages = new List<KafkaMessage__c>{
            createPersonDocumentMessage(aktorId, kp)
        };
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.processMessages(messages);
    }

    /**
     * Initializes KafkaPerson3 as in KafkaPdlPersondokumentHandlerTest and
     * creates and inserts a Person based on him.
     */
    private static KafkaPerson3 createBaseKafkaPerson(String actorId) {
        KafkaPerson3 kp = new KafkaPerson3();
        kp.hentIdenter = new KafkaPerson3.HentIdenter();
        kp.hentIdenter.identer = new List<PDL_IdentInformasjon>();
        kp.hentPerson = new PDL_HentPerson();
        // just initialise all the lists.
        kp.hentPerson.adressebeskyttelse = new List<PDL_Adressebeskyttelse>();
        kp.hentPerson.bostedsadresse = new List<PDL_Bostedsadresse>();
        kp.hentPerson.deltBosted = new List<PDL_DeltBosted>();
        kp.hentPerson.doedfoedtBarn = new List<PDL_DoedfoedtBarn>();
        kp.hentPerson.doedsfall = new List<PDL_Doedsfall>();
        kp.hentPerson.foedsel = new List<PDL_Foedsel>();
        kp.hentPerson.folkeregisteridentifikator = new List<PDL_Folkeregisteridentifikator>();
        kp.hentPerson.folkeregisterpersonstatus = new List<PDL_Folkeregisterpersonstatus>();
        kp.hentPerson.forelderBarnRelasjon = new List<PDL_ForelderBarnRelasjon>();
        kp.hentPerson.foreldreansvar = new List<PDL_Foreldreansvar>();
        kp.hentPerson.fullmakt = new List<PDL_Fullmakt>();
        kp.hentPerson.identitetsgrunnlag = new List<PDL_Identitetsgrunnlag>();
        kp.hentPerson.innflyttingTilNorge = new List<PDL_InnflyttingTilNorge>();
        kp.hentPerson.kjoenn = new List<PDL_Kjoenn>();
        kp.hentPerson.kontaktadresse = new List<PDL_Kontaktadresse>();
        kp.hentPerson.kontaktinformasjonForDoedsbo = new List<PDL_KontaktinformasjonForDoedsbo>();
        kp.hentPerson.navn = new List<PDL_Navn>();
        kp.hentPerson.opphold = new List<PDL_Opphold>();
        kp.hentPerson.oppholdsadresse = new List<PDL_Oppholdsadresse>();
        kp.hentPerson.sikkerhetstiltak = new List<PDL_Sikkerhetstiltak>();
        kp.hentPerson.sivilstand = new List<PDL_Sivilstand>();
        kp.hentPerson.statsborgerskap = new List<PDL_Statsborgerskap>();
        kp.hentPerson.telefonnummer = new List<PDL_Telefonnummer>();
        kp.hentPerson.tilrettelagtKommunikasjon = new List<PDL_TilrettelagtKommunikasjon>();
        kp.hentPerson.utenlandskIdentifikasjonsnummer = new List<PDL_UtenlandskIdentifikasjonsnummer>();
        kp.hentPerson.utflyttingFraNorge = new List<PDL_UtflyttingFraNorge>();
        kp.hentPerson.vergemaalEllerFremtidsfullmakt = new List<PDL_VergemaalEllerFremtidsfullmakt>();
        // Default values
        // Ident
        kp.hentIdenter.identer.add(new PDL_IdentInformasjon());
        kp.hentIdenter.identer[0].gruppe = PDL_IdentGruppe.AKTORID;
        kp.hentIdenter.identer[0].historisk = false;
        kp.hentIdenter.identer[0].ident = actorId;
        // Person status
        kp.hentPerson.folkeregisterpersonstatus.add(new PDL_Folkeregisterpersonstatus());
        kp.hentPerson.folkeregisterpersonstatus[0].status = 'bosatt';
        // Name
        kp.hentPerson.navn.add(new PDL_Navn());
        kp.hentPerson.navn[0].etternavn = 'TRESTRESEN';
        kp.hentPerson.adressebeskyttelse.add(new PDL_Adressebeskyttelse());
        kp.hentPerson.adressebeskyttelse[0].gradering = PDL_AdressebeskyttelseGradering.UGRADERT;
        return kp;
    }

    /**
     * Calls createBaseKafkaPerson(String), and adds a folkeregisterident
     */
    private static KafkaPerson3 createBaseKafkaPerson(String actorId, String fregId) {
        KafkaPerson3 kp = createBaseKafkaPerson(actorId);
        kp.hentIdenter.identer.add(new PDL_IdentInformasjon());
        Integer i = kp.hentIdenter.identer.size() - 1;
        kp.hentIdenter.identer[i].ident = fregId;
        kp.hentIdenter.identer[i].historisk = false;
        kp.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        return kp;
    }

    /**
     * Initializes KafkaPerson3 as in KafkaPdlPersondokumentHandlerTest and
     * creates and inserts a Person based on him.
     */
    private static void createAndInsertBaseKafkaPerson(String actorId) {
        KafkaPerson3 kp = createBaseKafkaPerson(actorId);
        insertBaseKafkaPerson(actorId, kp);
    }

    /**
     * As the above, but also includes folkeregisterident.
     */
    private static void createAndInsertBaseKafkaPerson(String actorId, String fregId) {
        KafkaPerson3 kp = createBaseKafkaPerson(actorId, fregId);
        insertBaseKafkaPerson(actorId, kp);
    }

    /**
     * Tests that GT by itself results in a new person.
     */
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

    /**
     * Tests that we can insert a basic person for further testing.
     */
    @isTest
    static void testCreatePersonFromPersonDocument() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        Test.startTest();
        Test.stopTest();
        Person__c[] ps = [SELECT INT_ActorId__c FROM Person__c];
        Assert.areEqual('4398046511104', ps[0].INT_ActorId__c);
    }

    /**
     * Tests setting GT for existing person.
     */
    @IsTest
    static void setGTFromKommunenummer() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        Person__c[] ps = [SELECT INT_ActorId__c, INT_GTMunicipalityNumber__c FROM Person__c];
        Assert.areEqual(1, ps.size());
        Person__c p = ps[0];
        Assert.isNull(p.INT_GTMunicipalityNumber__c);
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.geografisktilknytning-v1',
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"1337","gtBydel":null,"gtLand":null,"regel":"2"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(kafkaMessages);
        Test.stopTest();
        ps = [SELECT INT_ActorId__c, INT_GTMunicipalityNumber__c FROM Person__c];
        Assert.areEqual(1, ps.size());
        p = ps[0];
        Assert.areEqual('1337', p.INT_GTMunicipalityNumber__c);
        //System.assertEquals('030101', p.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        //System.assertEquals('03', p.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        //System.assertEquals('0301', p.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        //System.assertEquals('030101', p.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    /*
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
