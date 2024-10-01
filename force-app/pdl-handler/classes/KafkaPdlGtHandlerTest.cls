/**
 * Tests for KafkaPdlGtHandler, i.e. geografisk tilknytning.
 * Assumes KafkaPdlPersondokumentHandler is working as expected, as we will test
 * against persons inserted using that.
 */
@IsTest
private class KafkaPdlGtHandlerTest {

    /**
     * Sends kafka messages. like KafkaMessageAsyncJob but without the async
     */
    private static void handleMessages() {
        new KafkaMessageService(
            [SELECT Id, CreatedDate, CRM_Topic__c, CRM_Key__c, CRM_Value__c
            FROM KafkaMessage__c
            WHERE CRM_Status__c = :KafkaMessageService.STATUS_PENDING]
            ).handleMessages();
    }

    /**
     * Create a message for inserting a person document.
     * See KafkaPdlPersondokumentHandlerTest for more information.
     * Explicitly set status, which would otherwise only get called when using
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
            CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
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
     * Initializes KafkaPerson3 as in KafkaPdlPersondokumentHandlerTest
     */
    private static KafkaPerson3 createBaseKafkaPerson(String actorId) {
        KafkaPerson3 kp = new KafkaPerson3();
        kp.hentIdenter = new KafkaPerson3.HentIdenter();
        kp.hentIdenter.identer = new List<PDL_IdentInformasjon>();
        kp.hentPerson = new PdlHentperson();
        // just initialise all the lists.
        kp.hentPerson.adressebeskyttelse = new List<PdlAdressebeskyttelse>();
        kp.hentPerson.bostedsadresse = new List<PdlBostedsadresse>();
        kp.hentPerson.deltBosted = new List<PdlDeltbosted>();
        kp.hentPerson.doedfoedtBarn = new List<PdlDoedfoedtbarn>();
        kp.hentPerson.doedsfall = new List<PdlDoedsfall>();
        kp.hentPerson.foedsel = new List<PdlFoedsel>();
        kp.hentPerson.folkeregisteridentifikator = new List<PdlFolkeregisteridentifikator>();
        kp.hentPerson.folkeregisterpersonstatus = new List<PdlFolkeregisterpersonstatus>();
        kp.hentPerson.forelderBarnRelasjon = new List<PdlForelderbarnrelasjon>();
        kp.hentPerson.foreldreansvar = new List<PdlForeldreansvar>();
        kp.hentPerson.fullmakt = new List<PdlFullmakt>();
        kp.hentPerson.identitetsgrunnlag = new List<PdlIdentitetsgrunnlag>();
        kp.hentPerson.innflyttingTilNorge = new List<PdlInnflyttingtilnorge>();
        kp.hentPerson.kjoenn = new List<PdlKjoenn>();
        kp.hentPerson.kontaktadresse = new List<PdlKontaktadresse>();
        kp.hentPerson.kontaktinformasjonForDoedsbo = new List<PdlKontaktinformasjonfordoedsbo>();
        kp.hentPerson.navn = new List<PdlNavn>();
        kp.hentPerson.opphold = new List<PdlOpphold>();
        kp.hentPerson.oppholdsadresse = new List<PdlOppholdsadresse>();
        kp.hentPerson.sikkerhetstiltak = new List<PdlSikkerhetstiltak>();
        kp.hentPerson.sivilstand = new List<PdlSivilstand>();
        kp.hentPerson.statsborgerskap = new List<PdlStatsborgerskap>();
        kp.hentPerson.telefonnummer = new List<PdlTelefonnummer>();
        kp.hentPerson.tilrettelagtKommunikasjon = new List<PdlTilrettelagtkommunikasjon>();
        kp.hentPerson.utenlandskIdentifikasjonsnummer = new List<PdlUtenlandskidentifikasjonsnummer>();
        kp.hentPerson.utflyttingFraNorge = new List<PdlUtflyttingfranorge>();
        kp.hentPerson.vergemaalEllerFremtidsfullmakt = new List<PdlVergemaalellerfremtidsfullmakt>();
        // Default values
        // Ident
        kp.hentIdenter.identer.add(new PDL_IdentInformasjon());
        kp.hentIdenter.identer[0].gruppe = PDL_IdentGruppe.AKTORID;
        kp.hentIdenter.identer[0].historisk = false;
        kp.hentIdenter.identer[0].ident = actorId;
        // Person status
        kp.hentPerson.folkeregisterpersonstatus.add(new PdlFolkeregisterpersonstatus());
        kp.hentPerson.folkeregisterpersonstatus[0].status = 'bosatt';
        // Name
        kp.hentPerson.navn.add(new PdlNavn());
        kp.hentPerson.navn[0].etternavn = 'TRESTRESEN';
        kp.hentPerson.adressebeskyttelse.add(new PdlAdressebeskyttelse());
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
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '1017419408436',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["1017419408436","74194084361"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"1337","gtBydel":null,"gtLand":null,"regel":"2"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(kafkaMessages);
        Test.stopTest();
        List<Person__c> pl = [SELECT Id FROM Person__c WHERE INT_ActorId__c = '1017419408436'];
        Assert.areEqual(1, pl.size(), 'Expected one person inserted.');
    }

    /**
     * Tests that a person can be created from a persondokument. This lets us
     * write terse test methods below.
     */
    @isTest
    static void personCanBeCreatedFromPersonDocument() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        Test.startTest();
        Test.stopTest();
        Person__c[] people = [SELECT INT_ActorId__c FROM Person__c];
        Assert.areEqual('4398046511104', people[0].INT_ActorId__c);
    }

    /**
     * Tests setting GT for existing person.
     */
    @IsTest
    static void geografiskTilknytningIsSetCorrectlyForExistingPerson() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        Person__c[] people = [SELECT INT_ActorId__c, INT_GTMunicipalityNumber__c FROM Person__c];
        Assert.areEqual(1, people.size());
        Person__c person = people[0];
        Assert.isNull(person.INT_GTMunicipalityNumber__c);
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"1337","gtBydel":null,"gtLand":null,"regel":"2"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(kafkaMessages);
        Test.stopTest();
        people = [SELECT INT_ActorId__c, INT_GTMunicipalityNumber__c, INT_MunicipalityNumber__c, INT_RegionNumber__c FROM Person__c];
        Assert.areEqual(1, people.size());
        person = people[0];
        Assert.areEqual('1337', person.INT_GTMunicipalityNumber__c);
        Assert.areEqual('1337', person.INT_MunicipalityNumber__c);
        Assert.areEqual('13', person.INT_RegionNumber__c);
    }

    /**
     * Tests setting _all_ of the fields, based on district number.
     * https://pdl-docs.intern.nav.no/ekstern/index.html#geografisk-tilknytning
     */
    @IsTest
    static void geografiskTilknytningIsSetCorrectlyForExistingPersonFromDistrictNumber() {
        createAndInsertBaseKafkaPerson('4398046511104', '68719476736');
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(new List<KafkaMessage__c>{
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING),
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '2541865828329',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["2541865828329","10460353203"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING)
        });
        Test.stopTest();
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
     * Tests that nothing remains of the old GT when inserting a new GT with
     * lower precision.
     */
    @IsTest
    static void clearDistrictWhenSettingMunicipality() {
        Person__c guy;
        // Give our guy the highest precision (district)
        insert new KafkaMessage__c(
            CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c FROM Person__c][0];
        Assert.areEqual('1337', guy.INT_MunicipalityNumber__c);
        Assert.areEqual('133769', guy.INT_GTDistrictNumber__c);
        Assert.areEqual('133769', guy.INT_DistrictNumber__c);
        insert new KafkaMessage__c(
            CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"2024","gtBydel":null,"gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        Test.startTest();
        AsyncRequestSchedulable.enqueueAsyncJobs(); // This enqueues the job.
        Test.stopTest(); // This runs the job.
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c FROM Person__c][0];
        Assert.areEqual('2024', guy.INT_MunicipalityNumber__c);
        Assert.isNull(guy.INT_GTDistrictNumber__c);
        Assert.isNull(guy.INT_DistrictNumber__c);
    }

    /**
     * Tests that nothing remains of the old GT when inserting UDEFINERT.
     */
    @IsTest
    static void clearEverythingWhenSettingUdefinert() {
        Person__c guy;
        // Give our guy the highest precision (district)
        insert new KafkaMessage__c(
            CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        handleMessages();
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_MunicipalityNumber__c FROM Person__c][0];
        Assert.areEqual('1337', guy.INT_MunicipalityNumber__c);
        insert new KafkaMessage__c(
            CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
            CRM_Key__c = '4398046511104',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","68719476736"],"geografiskTilknytning":{"gtType":"UDEFINERT","gtKommune":null,"gtBydel":null,"gtLand":null,"regel":"666"}}')),
            CRM_Status__c = KafkaMessageService.STATUS_PENDING);
        Test.startTest();
        AsyncRequestSchedulable.enqueueAsyncJobs(); // This enqueues the job.
        Test.stopTest(); // This runs the job.
        guy = [SELECT INT_GTDistrictNumber__c, INT_DistrictNumber__c, INT_GTMunicipalityNumber__c, INT_MunicipalityNumber__c, INT_RegionNumber__c FROM Person__c][0];
        Assert.isNull(guy.INT_GTDistrictNumber__c);
        Assert.isNull(guy.INT_DistrictNumber__c);
        Assert.isNull(guy.INT_GTMunicipalityNumber__c);
        Assert.isNull(guy.INT_MunicipalityNumber__c);
        Assert.isNull(guy.INT_RegionNumber__c);
    }

    /**
     * Tests that the kafka message statuses on a batch of two are correct when
     * the DML fails on one of them.
     */
    @IsTest
    static void batchWithBadPersonResultsInPartialUpsert() {
        // two valid messages
        KafkaMessage__c[] messages = new KafkaMessage__c[]{
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","34359738368"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING),
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '8796093022208',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["8796093022208","34359738368"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING)};
        // persons with the same indices
        Person__c[] persons = new Person__c[]{};
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        for (KafkaMessage__c msg : messages) {
            Person__c person = handler.createPersonRecord(msg);
            persons.add(person);
            msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
        }
        // mess up one of our persons by exceeding the max length of one of its
        // fields. this will trigger a dml exception upon insertion, which
        // will set the kafka message status to Error.
        persons[0].INT_GTDistrictNumber__c = '1234567';
        Test.startTest();
        handler.upsertResult(persons, messages);
        Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_ERROR, messages[0].CRM_Status__c);
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[1].CRM_Status__c);
    }

    /**
     * Tests that an invalid message value (e.g. null, which should never occur,
     * but might with certain test users, including AREMARK) does not cause the
     * entire batch to fail.
     */
    @IsTest
    static void batchWithBadMessageValueResultsInPartialUpsert() {
        // two messages, one valid, one invalid
        KafkaMessage__c[] messages = new KafkaMessage__c[]{
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","34359738368"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING),
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '8796093022208',
                CRM_Value__c = null,
                CRM_Status__c = KafkaMessageService.STATUS_PENDING)};
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[0].CRM_Status__c);
        Assert.areEqual(KafkaMessageService.STATUS_ERROR, messages[1].CRM_Status__c);
    }

    /**
     * Tests that when two valid messages with the same key appear in the same
     * batch, they are both processed, and the result is one person with the
     * values sent in the last message.
     */
    @IsTest
    static void onlyLastMessageIsUsedWhenReceivingMultipleWithSameKey() {
        // two different messages with the same key
        KafkaMessage__c[] messages = new KafkaMessage__c[]{
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","34359738368"],"geografiskTilknytning":{"gtType":"BYDEL","gtKommune":null,"gtBydel":"133769","gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING),
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                CRM_Key__c = '4398046511104',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["4398046511104","34359738368"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"7776","gtBydel":null,"gtLand":null,"regel":"666"}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING)};
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[0].CRM_Status__c);
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[1].CRM_Status__c);
        Person__c[] persons = [SELECT INT_DistrictNumber__c, INT_MunicipalityNumber__c FROM Person__c];
        Assert.areEqual(1, persons.size());
        Assert.areEqual('7776', persons[0].INT_MunicipalityNumber__c);
        Assert.isNull(persons[0].INT_DistrictNumber__c);
    }

    /**
     * Ensure we update the current actor, and not any historical ones left
     * in _identer_.
     */
    @IsTest
    static void onlyCrmkeyIsUsedForSettingActorid() {
        KafkaMessage__c[] messages = new KafkaMessage__c[]{
            new KafkaMessage__c(
                    CRM_Topic__c = KafkaPdlGtHandler.GT_TOPIC,
                    CRM_Key__c = '4398046511104',
                    CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"identer":["68719476736", "4398046511104","7625597484987"],"geografiskTilknytning":{"gtType":"KOMMUNE","gtKommune":"7776","gtBydel":null,"gtLand":null,"regel":"666"}}')),
                    CRM_Status__c = KafkaMessageService.STATUS_PENDING)};
        KafkaPdlGtHandler handler = new KafkaPdlGtHandler();
        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[0].CRM_Status__c);
        Person__c[] persons = [SELECT INT_ActorId__c FROM Person__c];
        Assert.areEqual(1, persons.size());
        Assert.areEqual('4398046511104', persons[0].INT_ActorId__c);
    }
}
