/**
 * Tests for KafkaPdlGtHandler, i.e. geografisk tilknytning.
 * Assumes KafkaPdlPersondokumentHandler is working as expected, as we will test
 * against persons inserted using that.
 */
@IsTest
private with sharing class KafkaPdlGtHandlerTest {

    /**
     * Useful information for debugging
     */
    private static void printLogsAndMessages() {
        for (Application_Log__c l : [SELECT Category__c, Log_Level__c, Log_Message__c from Application_Log__c]) {
            System.debug('log entry: ' + l.Category__c + ' ' + l.Log_Level__c + ': ' + l.Log_Message__c);
        }
        for (KafkaMessage__c m : [SELECT CRM_Status__c, CRM_Topic__c, CRM_Key__c, CRM_ErrorMessage__c FROM KafkaMessage__c]) { // WHERE CRM_Status__c!=:KafkaMessageService.STATUS_PROCESSED]) {
            System.debug(String.format(
                    //'unprocessed ({0}) message on {1}:\nKey: {2}\nError: {3}',
                    '{0} message on {1}:\nKey: {2}\nError: {3}',
                    new List<Object>{
                        m.CRM_Status__c,
                        m.CRM_Topic__c,
                        m.CRM_Key__c,
                        m.CRM_ErrorMessage__c}));
        }
    }

    /**
     * Occasionally useful information for debugging.
     * (Obviously never run this in a big environment.)
     */
    private static void printPeople() {
        System.debug('all people in db: ' + JSON.serializePretty(Database.query('SELECT ' + String.join(Schema.Person__c.SObjectType.getDescribe().fields.getMap().keySet(), ',') + ' FROM Person__c')));
    }

    /**
     * Sends kafka messages. like KafkaMessageAsyncJob but without the async
     */
    private static void handleMessages() {
        new KafkaMessageService(
            [SELECT Id, CreatedDate, CRM_Topic__c, CRM_Key__c, CRM_Value__c FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PENDING]
            ).handleMessages();
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
        handler.processMessages(messages); // don't bother inserting the message
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
        printLogsAndMessages();
        printPeople();
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
        printLogsAndMessages();
        ps = [SELECT INT_ActorId__c, INT_GTMunicipalityNumber__c, INT_MunicipalityNumber__c, INT_RegionNumber__c FROM Person__c];
        Assert.areEqual(1, ps.size());
        p = ps[0];
        Assert.areEqual('1337', p.INT_GTMunicipalityNumber__c);
        Assert.areEqual('1337', p.INT_MunicipalityNumber__c);
        Assert.areEqual('13', p.INT_RegionNumber__c);
    }

    /**
     * Tests setting _all_ of the fields, based on district number.
     * https://pdl-docs.intern.nav.no/ekstern/index.html#geografisk-tilknytning
     */
    @IsTest
    static void setGTFromBydel() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(new List<KafkaMessage__c>{
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.geografisktilknytning-v1',
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING),
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.geografisktilknytning-v1',
                CRM_Key__c = '2541865828329',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["2541865828329","10460353203"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING)
        });
        Test.stopTest();
        printLogsAndMessages();
        Person__c[] people = [SELECT
            INT_ActorId__c,
            INT_GTDistrictNumber__c,
            INT_GTMunicipalityNumber__c,
            INT_DistrictNumber__c,
            INT_MunicipalityNumber__c,
            INT_RegionNumber__c
            FROM Person__c];
        Assert.areEqual(2, people.size());
        for (Person__c p : people) {
            Assert.areEqual('133769', p.INT_GTDistrictNumber__c);
            Assert.areEqual('1337', p.INT_GTMunicipalityNumber__c);
            Assert.areEqual('133769', p.INT_DistrictNumber__c);
            Assert.areEqual('1337', p.INT_MunicipalityNumber__c);
            Assert.areEqual('13', p.INT_RegionNumber__c);
        }
    }

    /**
     * Tests that updating the person document does not clear the address
     * information fetched from the geographical affiliation, which should have
     * a higher priority.
     */
    @IsTest
    static void setPersonDocAfterGt() {
        Person__c[] people;
        String sandvika;
        // Basic person
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        Test.startTest();
        // Set GT
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.geografisktilknytning-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        people = [SELECT INT_MunicipalityNumber__c from Person__c];
        Assert.areEqual(1, people.size());
        sandvika = people[0].INT_MunicipalityNumber__c;
        Assert.areEqual('1337', sandvika);
        // Minimal update to person that shouldn't affect address
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.pdl-persondokument-tagged-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"hentPerson":{"adressebeskyttelse":[],"bostedsadresse":[{"angittFlyttedato":"1972-09-26","gyldigFraOgMed":"1972-09-26T00:00:00","gyldigTilOgMed":null,"coAdressenavn":null,"vegadresse":{"matrikkelId":330462890,"husnummer":"54","husbokstav":null,"bruksenhetsnummer":null,"adressenavn":"Tromøy kirkevei","kommunenummer":"4203","tilleggsnavn":null,"postnummer":"4818","bydelsnummer":null,"koordinater":{"x":489639.3,"y":6478898.8,"z":null}},"matrikkeladresse":null,"ukjentBosted":null,"utenlandskAdresse":null,"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:39.83","gyldighetstidspunkt":"1972-09-26T00:00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"582d32a7-f923-467a-9cd6-17976f6727d2","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:39.83","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"deltBosted":[],"doedfoedtBarn":[],"doedsfall":[],"foedsel":[],"folkeregisteridentifikator":[],"folkeregisterpersonstatus":[],"forelderBarnRelasjon":[],"foreldreansvar":[],"fullmakt":[],"identitetsgrunnlag":[],"innflyttingTilNorge":[],"kjoenn":[],"kontaktadresse":[],"kontaktinformasjonForDoedsbo":[],"navn":[{"etternavn":"FORTSATTSEN"}],"opphold":[],"oppholdsadresse":[],"sikkerhetstiltak":[],"sivilstand":[],"statsborgerskap":[],"telefonnummer":[],"tilrettelagtKommunikasjon":[],"utenlandskIdentifikasjonsnummer":[],"utflyttingFraNorge":[],"vergemaalEllerFremtidsfullmakt":[]},"hentIdenter":{"identer":[{"ident":"68719476736","historisk":false,"gruppe":"FOLKEREGISTERIDENT","metadata":null,"folkeregistermetadata":null},{"ident":"4398046511104","historisk":false,"gruppe":"AKTORID","metadata":null,"folkeregistermetadata":null}]}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        printLogsAndMessages();
        printPeople();
        people = [SELECT INT_MunicipalityNumber__c from Person__c];
        Assert.areEqual(1, people.size());
        sandvika = people[0].INT_MunicipalityNumber__c;
        Assert.areEqual('1337', sandvika);
    }

    /**
     * Tests that nothing remains of the old GT when inserting a new GT with
     * lower precision.
     */
    @IsTest
    static void setMunicipalityAfterDistrict() {
        Person__c guy;
        // Give our guy the highest precision (district)
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.geografisktilknytning-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c from Person__c][0];
        Assert.areEqual('1337', guy.INT_MunicipalityNumber__c);
        Assert.areEqual('133769', guy.INT_GTDistrictNumber__c);
        Assert.areEqual('133769', guy.INT_DistrictNumber__c);
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.geografisktilknytning-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"2024","gtBydel":null,"gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        Test.startTest();
        AsyncRequestSchedulable.enqueueAsyncJobs(); // This enqueues the job.
        Test.stopTest(); // This runs the job.
        printLogsAndMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c from Person__c][0];
        Assert.areEqual('2024', guy.INT_MunicipalityNumber__c);
        Assert.isNull(guy.INT_GTDistrictNumber__c);
        Assert.isNull(guy.INT_DistrictNumber__c);
    }

    /**
     * Tests that nothing remains of the old GT when inserting UDEFINERT.
     */
    @IsTest
    static void setUndefinedAfterDistrict() {
        Person__c guy;
        // Give our guy the highest precision (district)
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.geografisktilknytning-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c from Person__c][0];
        Assert.areEqual('1337', guy.INT_MunicipalityNumber__c);
        insert new KafkaMessage__c(
            CRM_Topic__c = 'pdl.geografisktilknytning-v1',
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"UDEFINERT","gtKommune":null,"gtBydel":null,"gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        Test.startTest();
        AsyncRequestSchedulable.enqueueAsyncJobs(); // This enqueues the job.
        Test.stopTest(); // This runs the job.
        printLogsAndMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_GTMunicipalityNumber__c, INT_MunicipalityNumber__c, INT_RegionNumber__c from Person__c][0];
        Assert.isNull(guy.INT_GTDistrictNumber__c);
        Assert.isNull(guy.INT_DistrictNumber__c);
        Assert.isNull(guy.INT_GTMunicipalityNumber__c);
        Assert.isNull(guy.INT_MunicipalityNumber__c);
        Assert.isNull(guy.INT_RegionNumber__c);
    }
}
