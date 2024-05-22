@IsTest
private with sharing class KafkaPdlPersondokumentHandlerTest {

    /**
     * Creates data we would otherwise fetch; common codes, and so on.
     */
    @TestSetup
    static void makeData() {
        List<Common_Code__c> commonCodes = new List<Common_Code__c>();
        Common_Code__c ccIND = new Common_Code__c();
        ccIND.Name = 'India';
        ccIND.CRM_Code_Set__c = 'Landkoder';
        ccIND.CRM_Code__c = 'IND';
        ccIND.CRM_Active__c = true;
        commonCodes.add(ccIND);
        Common_Code__c ccBEL = new Common_Code__c();
        ccBEL.Name = 'BELGIA';
        ccBEL.CRM_Code_Set__c = 'Landkoder';
        ccBEL.CRM_Code__c = 'BEL';
        ccBEL.CRM_Active__c = true;
        commonCodes.add(ccBEL);
        Common_Code__c ccNOR = new Common_Code__c();
        ccNOR.Name = 'Norge';
        ccNOR.CRM_Code_Set__c = 'Landkoder';
        ccNOR.CRM_Code__c = 'NOR';
        ccNOR.CRM_Active__c = true;
        commonCodes.add(ccNOR);
        insert commonCodes;
    }

    /**
     * Initializes KafkaPerson3 with PDL_IdentInformasjon and PdlHentperson,
     * similar to what we expect to receive as a minimum from PDL.
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
     * Pulls out all the fields in which we may be interested
     */
    private static Map<String, Person__c> getPersonAccountByActorIdent() {
        Map<String, Person__c> personByActorIdent = new Map<String, Person__c>();
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
                INT_dnr__c,
                INT_FamilyRelations__c,
                INT_fnr__c,
                INT_FirstName__c,
                INT_GTDistrictNumber__c,
                INT_GTMunicipalityNumber__c,
                INT_GuardianshipOrFuturePowerOfAttorney__c,
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
                INT_npid__c,
                INT_Phone1__c,
                INT_Phone2__c,
                INT_PowerOfAttorney__c,
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
            personByActorIdent.put(person.INT_ActorId__c, person);
        }
        return personByActorIdent;
    }

    /**
     * Test for a typical Dolly person
     */
    @isTest
    static void testCreatePersonFromPersonDokument() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                CRM_Key__c = '2594819806563',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"hentPerson":{"adressebeskyttelse":[],"bostedsadresse":[{"angittFlyttedato":"1972-07-01","gyldigFraOgMed":"1972-07-01T00:00:00","gyldigTilOgMed":null,"coAdressenavn":null,"vegadresse":{"matrikkelId":138391329,"husnummer":"11","husbokstav":null,"bruksenhetsnummer":null,"adressenavn":"Marihandstien","kommunenummer":"1806","tilleggsnavn":null,"postnummer":"8515","bydelsnummer":null,"koordinater":{"x":599891.371546,"y":7592866.900335,"z":null}},"matrikkeladresse":null,"ukjentBosted":null,"utenlandskAdresse":null,"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:37.045","gyldighetstidspunkt":"1972-07-01T00:00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"e52735a2-be2f-4b2a-b578-dec2f032e8dd","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:37.045","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"doedsfall":[],"foedsel":[{"foedselsaar":1972,"foedselsdato":"1972-07-01","foedeland":"BEL","foedested":"Fødested i/på BELGIA","foedekommune":null,"metadata":{"opplysningsId":"fadd61cf-0da2-4df1-9492-a5fb1532f50f","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:35.412","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false},"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:35.412","gyldighetstidspunkt":"2022-01-14T15:41:35.412","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null}}],"folkeregisteridentifikator":[{"identifikasjonsnummer":"01077211027","type":"FNR","status":"I_BRUK","folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:34.945","gyldighetstidspunkt":"2022-01-14T15:41:34.945","opphoerstidspunkt":null,"kilde":"srvdolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"4ed45e87-e02b-4aa0-8601-689bbd58f20f","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:35.058","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"srvdolly"}],"historisk":false}}],"folkeregisterpersonstatus":[{"status":"bosatt","forenkletStatus":"bosattEtterFolkeregisterloven","folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:37.899","gyldighetstidspunkt":"2022-01-14T15:41:37.899","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"37065f2d-5f9e-4046-a6d3-9f6856961cd6","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:37.899","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"forelderBarnRelasjon":[],"fullmakt":[],"kjoenn":[{"kjoenn":"KVINNE","folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:36.62","gyldighetstidspunkt":"2022-01-14T15:41:36.62","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"0847b543-0847-4494-9fca-857a1ca51a73","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:36.62","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"navn":[{"fornavn":"ARTIG","mellomnavn":null,"etternavn":"SNERK","forkortetNavn":"SNERK ARTIG","originaltNavn":null,"gyldigFraOgMed":"2022-01-14","folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:36.237","gyldighetstidspunkt":"2022-01-14T15:41:36.237","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"44fbf7a6-6885-48ad-a303-e9d90fa4567f","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:36.237","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"oppholdsadresse":[],"sikkerhetstiltak":[],"sivilstand":[{"type":"UGIFT","gyldigFraOgMed":null,"relatertVedSivilstand":null,"bekreftelsesdato":null,"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:38.684","gyldighetstidspunkt":"2022-01-14T15:41:38.684","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"2d7f6623-3ba4-44d3-8e04-efced8cd77e3","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:38.684","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"statsborgerskap":[{"land":"NOR","bekreftelsesdato":null,"gyldigFraOgMed":"1972-07-01","gyldigTilOgMed":null,"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:38.327","gyldighetstidspunkt":"1972-07-01T00:00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"672b293a-b18e-4cd1-9a16-d4a03eb8581d","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:38.326","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"tilrettelagtKommunikasjon":[],"telefonnummer":[],"innflyttingTilNorge":[{"fraflyttingsland":"BEL","fraflyttingsstedIUtlandet":null,"folkeregistermetadata":{"ajourholdstidspunkt":"2022-01-14T15:41:37.532","gyldighetstidspunkt":"1972-07-01T00:00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"5345af76-ac03-4461-9d5c-f17c42ea8a32","master":"FREG","endringer":[{"type":"OPPRETT","registrert":"2022-01-14T15:41:37.532","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"utflyttingFraNorge":[],"vergemaalEllerFremtidsfullmakt":[]},"hentIdenter":{"identer":[{"ident":"01077211027","historisk":false,"gruppe":"FOLKEREGISTERIDENT","metadata":null,"folkeregistermetadata":null},{"ident":"2594819806563","historisk":false,"gruppe":"AKTORID","metadata":null,"folkeregistermetadata":null}]}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        System.Test.startTest();
        handler.processMessages(kafkaMessages);
        System.Test.stopTest();
        List<Person__c> pl = [SELECT Id from Person__c where INT_ActorId__c = '2594819806563'];
        Assert.areEqual(1, pl.size(), 'Expected one person inserted.');
    }

    /**
     * Simple test to ensure tombstones (null values) do not result in a person
     */
    @isTest
    static void testTombstoneIsNotInserted() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                CRM_Key__c = '2594819806564',
                CRM_Value__c = null,
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        Integer numPersonsBefore = [select id from person__c].size();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        System.Test.startTest();
        handler.processMessages(kafkaMessages);
        System.Test.stopTest();
        Assert.areEqual(numPersonsBefore, [select id from person__c].size(),
            'Expected none inserted.');
    }

    /*******************************************
     * TESTS FOR IDENTS *
     *******************************************/

    @isTest
    /**
     * Tests that person's Name is set to FOLKEREGISTERIDENT when both
     * FOLKEREGISTERIDENT and NPID exist and are not historic.
     * Also tests that Name is set to NPID when the FOLKEREGISTERIDENT exists
     * but is historic.
     */
    static void setNameFieldTest() {
        KafkaPerson3 kPerson = createBaseKafkaPerson('1234567890123');
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        Integer i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678901';
        kPerson.hentIdenter.identer[i].historisk = false;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        Integer fregIndex = i;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678911';
        kPerson.hentIdenter.identer[i].historisk = false;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.NPID;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '5234567890169';
        kPerson.hentIdenter.identer[i].historisk = false;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.AKTORID;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678902';
        kPerson.hentIdenter.identer[i].historisk = true;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        Person__c person = new Person__c();
        System.Test.startTest(); // eh
        KafkaPdlPersondokumentHandler.setNameField(person, kPerson.hentIdenter);
        Assert.areEqual('12345678901', person.Name, 'Expected non historisk FOLKEREGISTERIDENT');
        person = new Person__c();
        kPerson.hentIdenter.identer[fregIndex].historisk = true;
        KafkaPdlPersondokumentHandler.setNameField(person, kPerson.hentIdenter);
        System.Test.stopTest();
        Assert.areEqual('12345678911', person.Name, 'Expected non historisk NPID');
    }

    @IsTest
    /**
     * Tests that person's Name is not set and instead an exception is thrown
     * when FOLKEREGISTERIDENT and NPID exist but are historic.
     */
    static void setNameFieldException() {
        KafkaPerson3 kPerson = createBaseKafkaPerson('1234567890123');
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        Integer i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678901';
        kPerson.hentIdenter.identer[i].historisk = true;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678911';
        kPerson.hentIdenter.identer[i].historisk = true;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.NPID;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '5234567890169';
        kPerson.hentIdenter.identer[i].historisk = false;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.AKTORID;
        kPerson.hentIdenter.identer.add(new PDL_IdentInformasjon());
        i = kPerson.hentIdenter.identer.size() - 1;
        kPerson.hentIdenter.identer[i].ident = '12345678902';
        kPerson.hentIdenter.identer[i].historisk = true;
        kPerson.hentIdenter.identer[i].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        Person__c person = new Person__c();
        System.Test.startTest();
        try {
            KafkaPdlPersondokumentHandler.setNameField(person, kPerson.hentIdenter);
            Assert.fail('No exception thrown');
        } catch (KafkaPdlPersondokumentHandler.PdlIdentException ex) {
            System.assert(true); // ಠ_ಠ
        } catch (Exception e) {
            Assert.fail('Did not catch the correct exception');
        }
        System.Test.stopTest();
    }

    @IsTest
    /**
     * Create a person with an (active) FNR and an (inactive) DNR, ensure both
     * are set.
     */
    static void setIdentsTest() {
        KafkaPerson3 kPerson = createBaseKafkaPerson('1234567890123');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.ident = '12345678901';
        identInfo.historisk = false;
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kPerson.hentIdenter.identer.add(identInfo);
        identInfo = new PDL_IdentInformasjon();
        identInfo.ident = '12345678911';
        identInfo.historisk = false;
        identInfo.gruppe = PDL_IdentGruppe.NPID;
        kPerson.hentIdenter.identer.add(identInfo);
        identInfo = new PDL_IdentInformasjon();
        identInfo.ident = '52345678901';
        identInfo.historisk = true;
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kPerson.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        kPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '52345678901';
        fregIdent.status = PDL_IdentStatus.OPPHOERT;
        fregIdent.type = PDL_IdentType.DNR;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = true;
        kPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        Person__c person = new Person__c();
        System.Test.startTest();
        KafkaPdlPersondokumentHandler.setIdents(person, kPerson);
        System.Test.stopTest();
        Assert.areEqual(null, person.INT_ACTORID__c, 'Expected AKTORID to be null');
        Assert.areEqual('12345678901', person.INT_FNR__c, 'Expected FNR to be set');
        Assert.areEqual('12345678911', person.INT_NPID__c, 'Expect NPID to be set');
        Assert.areEqual('52345678901', person.INT_DNR__c, 'Expect DNR to be set');
    }

    /*******************************************
     * TESTS FOR checkLastUpdatedAndTombStones *
     *******************************************/

    /* SCENARIO:
     * A Person exists in Salesforce and we try to process a KafkaMessage__c
     * where the CreatedDate is older than the Person LastModifiedDate
     * KafkaMessage__c.CRM_Status__c should be set to error
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesOlderMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;
        String createdDate = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate + '"}', KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg.CRM_Key__c = '1000012345678';
        msg.CRM_Value__c = 'e30K'; // empty dict: nonnull, so tombstone is false
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_WARNING, msg.CRM_Status__c,
            'Expected the status to be set to warning');
    }

    /* SCENARIO:
     * A Person exists in Salesforce and we try to process a KafkaMessage__c
     * where the persons INT_LastUpdatedFromPDL__c is empty
     * KafkaMessage__c.CRM_Status__c should not be updated
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessagesNoLastUpdated() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = null;
        insert person1;
        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate + '"}', KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg.CRM_Key__c = '1000012345678';
        msg.CRM_Value__c = 'e30K'; // {}
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg.CRM_Status__c,
            'Expected the status to be the same');
    }

    /* SCENARIO:
     * A Person exists in Salesforce and we try to process a KafkaMessage__c
     * where the CreatedDate is after than the Person INT_LastUpdatedFromPDL__c
     * KafkaMessage__c.CRM_Status__c should not be updated
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;
        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate + '"}', KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg.CRM_Key__c = '1000012345678';
        msg.CRM_Value__c = 'e30K'; // {}
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg.CRM_Status__c,
            'Expected the status to be the same');
    }

    /* SCENARIO:
     * We try to process a KafkaMessage__c where we don't have any matching
     * person in Salesforce
     * KafkaMessage__c.CRM_Status__c should not be updated
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessages() {
        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate + '"}', KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg.CRM_Key__c = '1000012345678';
        msg.CRM_Value__c = 'e30K'; // {}
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg.CRM_Status__c,
            'Expected the status to be the same');
    }

    /* SCENARIO:
     * We try to process several KafkaMessage__c where they all have the same
     * key and matches a Person in Salesforce
     * KafkaMessage__c.CRM_Status__c should be set to processec on only the oldest
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesNewDuplicateMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;
        String createdDate1 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(3).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate3 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate4 = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 + '"}', KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg1.CRM_Key__c = '1000012345678';
        msg1.CRM_Value__c = 'e30K'; // {}
        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 + '"}', KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg2.CRM_Key__c = '1000012345678';
        msg2.CRM_Value__c = 'e30K'; // {}
        KafkaMessage__c msg3 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate3 + '"}', KafkaMessage__c.class
        );
        msg3.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg3.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg3.CRM_Key__c = '1000012345678';
        msg3.CRM_Value__c = 'e30K'; // {}
        KafkaMessage__c msg4 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate4 + '"}', KafkaMessage__c.class
        );
        msg4.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg4.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg4.CRM_Key__c = '1000012345678';
        msg4.CRM_Value__c = 'e30K'; // {}
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2, msg3, msg4 });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg1.CRM_Status__c,
            'Expected the status to be processed');
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg2.CRM_Status__c,
            'Expected the status to be the same');
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg3.CRM_Status__c,
            'Expected the status to be processed');
        Assert.areEqual(KafkaMessageService.STATUS_WARNING, msg4.CRM_Status__c,
            'Expected the status to be warning');
    }

    /* SCENARIO:
     * We try to process two several KafkaMessage__c where they all have the
     * same actorId that matches a Person in Salesforce, but one is a tombstone
     * Both KafkaMessage__c should be processed
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesDuplicateMessagesWithTombstone() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;
        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 + '"}', KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg1.CRM_Key__c = '1000012345678';
        msg1.CRM_Value__c = 'e30K'; // {}
        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 + '"}', KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg2.CRM_Key__c = '1000012345678';
        // CRM_Value__c is null
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2 });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_WARNING, msg1.CRM_Status__c,
            'Expected msg1 status to be warning');
        Assert.areEqual(KafkaMessageService.STATUS_PENDING, msg2.CRM_Status__c,
            'Expected msg2 status to be pending');
    }

    /* SCENARIO:
     * We try process a KafkaMessage__c where we dont have a match a Person in
     * Salesforce, but one is a tombstone
     * KafkaMessage__c.CRM_Status__c should be set to processed
     */
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessagesWithTombstone() {
        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 + '"}', KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC;
        msg1.CRM_Key__c = '1000012345678';
        // CRM_Value__c is null
        System.Test.startTest();
        new KafkaPdlPersondokumentHandler().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1 });
        System.Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, msg1.CRM_Status__c,
            'Expected the status to be processed'
        );
    }

    /* SCENARIO:
     * We try process a KafkaMessage__c where we have a match a Person in
     * Salesforce, the message is a tombstone and the value is null
     * Person should get a tombstone
     */
    @IsTest
    static void processTombstoneTest() {
        insert new Person__c(
            Name = '12345678901',
            INT_fnr__c = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                CRM_Key__c = '1000012345678',
                CRM_Value__c = null
            )
        );
        // Verify that we have only one Account
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        // Act
        System.Test.startTest();
        insert kafkaMessages;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        // Assert that 1 Person Account has been inserted
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        // Assert that all Kafka Message records have been marked as processed
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]
        );
        Person__c p = [
            SELECT Id, INT_ActorId__c, INT_fnr__c, Name, INT_IsHasTombstone__c, INT_FirstName__c, INT_LastName__c
            FROM Person__c
            LIMIT 1
        ];
        // Assert that only tombstone and id fields has values
        Assert.areEqual('1000012345678', p.INT_ActorId__c, 'ActorId');
        Assert.areEqual('12345678901', p.INT_fnr__c, 'fnr');
        Assert.areEqual('12345678901', p.Name, 'Name');
        Assert.areEqual(true, p.INT_IsHasTombstone__c, 'Tombstone');
        Assert.areEqual(null, p.INT_FirstName__c, 'Firstname');
        Assert.areEqual(null, p.INT_LastName__c, 'Lastname');
    }

    /********************************
     * TESTS FOR MESSAGE PROCESSING *
     ********************************/

    /**
     * Create a message similar to one we would receive via Kafka. Note that
     * JSON.serialize(null) correctly becomes the string "null", however, the
     * value denoting a tombstone is not the base64 encoding of this string, but
     * simply null. (Liable to change, perhaps to the empty string.)
     */
    private static KafkaMessage__c createKafkaMessage(
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

    private static void assertProcessed(KafkaMessage__c message) {
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message.CRM_Status__c,
            'Expected message to be processed but it is ' +
            message.CRM_Status__c +
            '. CRM_ErrorMessage__c: ' +
            message.CRM_ErrorMessage__c
        );
    }

    @isTest
    /**
     * Create, insert, and process a message.
     */
    static void insertKafkaMessageDefault() {
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        kafkaPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaMessage__c message = createKafkaMessage('1122334455666', kafkaPerson);
        // Verify that we don't have any Person__c records
        Assert.areEqual(0, [SELECT COUNT() FROM Person__c]);
        // Act
        System.Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        Person__c person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '1122334455666'
        ];
        Assert.areEqual('12345678901', person.INT_fnr__c, 'Expect FNR to be set');
        Assert.areEqual(null, person.INT_npid__c, 'Did not expect NPID to be set');
        Assert.areEqual(null, person.INT_dnr__c, 'Did not expect DNR to be set');
        Assert.areEqual('12345678901', person.Name, 'Expected NAME to be set');
        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØRID to be set');
    }

    @isTest
    /**
     * All this method seems to test is that persons are not updated when
     * there exists a (processed) tombstone with the same ident.
     */
    static void insertKafkaMessageProcessed() {
        KafkaPerson3 athos = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        athos.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        athos.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaPerson3 porthos = createBaseKafkaPerson('1122334455666');
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        porthos.hentIdenter.identer.add(identInfo);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        porthos.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaMessage__c message1 = createKafkaMessage('1122334455777', null);
        KafkaMessage__c message2 = createKafkaMessage('1122334455666', athos);
        KafkaMessage__c message3 = createKafkaMessage('1122334455666', porthos);
        KafkaMessage__c message4 = createKafkaMessage('1122334455666', null);
        // Act
        System.Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3, message4 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];
        message4 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message4.Id];
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_WARNING,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_WARNING,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message4.CRM_Status__c,
            '' + message4.CRM_ErrorMessage__c
        );
        Assert.areEqual(0, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
    }

    @isTest
    /**
     * Forces and catches nullpointerexception caused by attempting to create a
     * security measure with nonexistent INT_ValidFromDate__c. Catching this
     * exception should create the warning from the method name.
     */
    static void insertKafkaMessageWarning() {
        KafkaPerson3 laurel = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        laurel.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        laurel.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaPerson3 hardy = createBaseKafkaPerson('1122334455666');
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        hardy.hentIdenter.identer.add(identInfo);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        hardy.hentPerson.folkeregisteridentifikator.add(fregIdent);
        hardy.hentPerson.sikkerhetstiltak = new List<PdlSikkerhetstiltak>();
        hardy.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak());
        hardy.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak());
        hardy.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak()); // wtf?
        KafkaMessage__c message1 = createKafkaMessage('1122334455777', null);
        KafkaMessage__c message2 = createKafkaMessage('1122334455666', laurel);
        KafkaMessage__c message3 = createKafkaMessage('1122334455666', hardy);
        // Act
        System.Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_WARNING,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        Assert.areEqual(0, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
    }

    @isTest
    /**
     * TODO: check what exactly this tests
     */
    static void insertKafkaMessageUpdateError() {
        insert new Person__c(
            Name = '12345678901',
            INT_fnr__c = '12345678901',
            INT_ActorId__c = '1122334455666',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );
        KafkaPerson3 athos = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        athos.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        athos.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaPerson3 porthos = createBaseKafkaPerson('1122334455666');
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        porthos.hentIdenter.identer.add(identInfo);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        porthos.hentPerson.folkeregisteridentifikator.add(fregIdent);
        porthos.hentPerson.sikkerhetstiltak = new List<PdlSikkerhetstiltak>();
        porthos.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak());
        porthos.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak());
        porthos.hentPerson.sikkerhetstiltak.add(new PdlSikkerhetstiltak());
        KafkaPerson3 aramis = createBaseKafkaPerson('1122334455999');
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678902';
        aramis.hentIdenter.identer.add(identInfo);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.identifikasjonsnummer = '12345678902';
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        aramis.hentPerson.folkeregisteridentifikator.add(fregIdent);
        KafkaMessage__c message1 = createKafkaMessage('1122334455111', null);
        KafkaMessage__c message2 = createKafkaMessage('1122334455666', athos);
        KafkaMessage__c message3 = createKafkaMessage('1122334455333', null);
        KafkaMessage__c message4 = createKafkaMessage('1122334455666', porthos);
        KafkaMessage__c message5 = createKafkaMessage('1122334455222', null);
        KafkaMessage__c message6 = createKafkaMessage('1122334455999', aramis);
        // Act
        System.Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3, message4, message5, message6 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];
        message4 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message4.Id];
        message5 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message5.Id];
        message6 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message6.Id];
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_ERROR,
            message4.CRM_Status__c,
            '' + message4.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message5.CRM_Status__c,
            '' + message5.CRM_ErrorMessage__c
        );
        Assert.areEqual(
            KafkaMessageService.STATUS_PROCESSED,
            message6.CRM_Status__c,
            '' + message6.CRM_ErrorMessage__c
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c WHERE Name = '12345678902']);
    }

    @isTest
    static void insertKafkaMessageNpidPerson() {
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.NPID;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        //kafkaPerson.folkeregisterpersonstatus.clear();
        KafkaMessage__c message = createKafkaMessage('1122334455666', kafkaPerson);
        // Act
        System.Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        Person__c person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '1122334455666'
        ];
        Assert.areEqual(null, person.INT_fnr__c, 'Did not expect this value to be set');
        Assert.areEqual('12345678901', person.INT_npid__c, 'Expected this value to be set');
        Assert.areEqual(null, person.INT_dnr__c, 'Did not expect this value to be set');
        Assert.areEqual('12345678901', person.Name, 'Expected NAME to be set');
        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØRID to be set');
    }

    @isTest
    /**
     * Check that:
     * - person with npid is inserted normally, gets name = npid
     * - giving this person a dnr sets name = dnr
     * - deprecating the dnr and adding fnr sets name = fnr
     */
    static void insertKafkaMessageNpidPersonFromNpidToFnr() {
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.NPID;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        //kafkaPerson.folkeregisterpersonstatus.clear();
        // first message; person with active npid
        KafkaMessage__c message1 = createKafkaMessage('1122334455666', kafkaPerson);
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '52345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '52345678901';
        fregIdent.type = PDL_IdentType.DNR;
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        kafkaPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        kafkaPerson.hentPerson.folkeregisterpersonstatus.add(new PdlFolkeregisterpersonstatus());
        kafkaPerson.hentPerson.folkeregisterpersonstatus[0].status = 'bosatt';
        // second message; now also with active freg-ident: dnr
        KafkaMessage__c message2 = createKafkaMessage('1122334455666', kafkaPerson);
        // deprecate this ident
        kafkaPerson.hentIdenter.identer[kafkaPerson.hentIdenter.identer.size() - 1].historisk = true;
        kafkaPerson.hentPerson.folkeregisteridentifikator[kafkaPerson.hentPerson.folkeregisteridentifikator.size() - 1].status = PDL_IdentStatus.OPPHOERT;
        kafkaPerson.hentPerson.folkeregisteridentifikator[kafkaPerson.hentPerson.folkeregisteridentifikator.size() - 1].metadata.historisk = true;
        // and make a new one
        identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '11345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '11345678901';
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        kafkaPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        // third message; deprecated dnr-freg-ident, new fnr-freg-ident
        KafkaMessage__c message3 = createKafkaMessage('1122334455666', kafkaPerson);
        KafkaMessageService msgService;
        Person__c person;
        // Act
        System.Test.startTest();
        //Message 1
        insert message1;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message1 });
        msgService.handleMessages();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id LIMIT 1]
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '1122334455666'
        ];
        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        Assert.isNull(person.INT_fnr__c, 'Did not expect FNR to be set');
        Assert.areEqual('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        Assert.isNull(person.INT_dnr__c, 'Did not expect DNR to be set');
        Assert.areEqual('12345678901', person.Name, 'Expected NAME to be same as NPID');
        //Message 2
        insert message2;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message2 });
        msgService.handleMessages();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id LIMIT 1]
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '1122334455666'
        ];
        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        Assert.isNull(person.INT_fnr__c, 'Did not expect FNR to be set');
        Assert.areEqual('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        Assert.areEqual('52345678901', person.INT_dnr__c, 'Expected DNR to be set');
        Assert.areEqual('52345678901', person.Name, 'Expected NAME to be same as DNR');
        //Message 3
        insert message3;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message3 });
        msgService.handleMessages();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id LIMIT 1]
        );
        Assert.areEqual(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '1122334455666'
        ];
        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        Assert.areEqual('11345678901', person.INT_fnr__c, 'Expected FNR to be set');
        Assert.areEqual('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        Assert.areEqual('52345678901', person.INT_dnr__c, 'Expect DNR to be set');
        Assert.areEqual('11345678901', person.Name, 'Expected NAME to be same as FNR');
        System.Test.stopTest();
    }

    /***************************
     * VERIFY THE DATA MAPPING *
     **************************/

    @isTest
    static void mapFieldValuesExcludingAddresses() {
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PDL_IdentInformasjon identInfo = new PDL_IdentInformasjon();
        identInfo.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identInfo.historisk = false;
        identInfo.ident = '12345678901';
        kafkaPerson.hentIdenter.identer.add(identInfo);
        PdlFolkeregisteridentifikator fregIdent = new PdlFolkeregisteridentifikator();
        fregIdent.identifikasjonsnummer = '12345678901';
        fregIdent.type = PDL_IdentType.FNR;
        fregIdent.status = PDL_IdentStatus.I_BRUK;
        fregIdent.metadata = new PDL_Metadata();
        fregIdent.metadata.historisk = false;
        kafkaPerson.hentPerson.folkeregisteridentifikator.add(fregIdent);
        // surname already provided by createBaseKafkaPerson
        kafkaPerson.hentPerson.navn[0].fornavn = 'TREST';
        kafkaPerson.hentPerson.navn[0].mellomnavn = 'T.';
        PdlFoedsel foedsel = new PdlFoedsel();
        foedsel.foedselsdato = Date.valueOf('2020-02-25');
        kafkaPerson.hentPerson.foedsel.add(foedsel);
        PdlInnflyttingtilnorge innflytting = new PdlInnflyttingtilnorge();
        innflytting.fraflyttingsland = 'IND';
        innflytting.fraflyttingsstedIUtlandet = 'Delhi';
        kafkaPerson.hentPerson.innflyttingTilNorge.add(innflytting);
        PdlSikkerhetstiltak tiltak = new PdlSikkerhetstiltak();
        tiltak.beskrivelse = 'Telefonisk utestengelse';
        tiltak.tiltaksType = 'TFUS';
        tiltak.gyldigFraOgMed = Date.valueOf('2020-12-14');
        tiltak.gyldigTilOgMed = Date.valueOf('2020-12-20');
        tiltak.kontaktperson = new PDL_SikkerhetstiltakKontaktperson();
        tiltak.kontaktperson.personident = 'Z000000';
        tiltak.kontaktperson.enhet = '0000';
        kafkaPerson.hentPerson.sikkerhetstiltak.add(tiltak);
        PdlStatsborgerskap statsborgerskap = new PdlStatsborgerskap();
        statsborgerskap.land = 'NOR';
        kafkaPerson.hentPerson.statsborgerskap.add(statsborgerskap);
        PdlSivilstand sivilstand = new PdlSivilstand();
        sivilstand.type = PDL_Sivilstandstype.GIFT;
        sivilstand.gyldigFraOgMed = Date.newInstance(2001, 6, 20);
        sivilstand.relatertVedSivilstand = '12345678910';
        kafkaPerson.hentPerson.sivilstand.add(sivilstand);
        PdlKjoenn kjoenn = new PdlKjoenn();
        kjoenn.kjoenn = PDL_KjoennType.MANN;
        kafkaPerson.hentPerson.kjoenn.add(kjoenn);
        PdlDoedsfall doedsfall = new PdlDoedsfall();
        doedsfall.doedsdato = Date.valueOf('2019-01-29');
        doedsfall.metadata = new PDL_Metadata();
        doedsfall.metadata.master = 'FREG';
        kafkaPerson.hentPerson.doedsfall.add(doedsfall);
        PdlTelefonnummer nummer = new PdlTelefonnummer();
        nummer.landskode = '+46';
        nummer.nummer = '0765-43 21 07';
        nummer.prioritet = 2;
        kafkaPerson.hentPerson.telefonnummer.add(nummer);
        nummer = new PdlTelefonnummer();
        nummer.landskode = '+47';
        nummer.nummer = '987 65 432';
        nummer.prioritet = 1;
        kafkaPerson.hentPerson.telefonnummer.add(nummer);
        PdlUtflyttingfranorge utflytting = new PdlUtflyttingfranorge();
        utflytting.tilflyttingsland = 'IND';
        utflytting.tilflyttingsstedIUtlandet = 'Delhi';
        kafkaPerson.hentPerson.utflyttingFraNorge.add(utflytting);
        PdlTilrettelagtkommunikasjon kom = new PdlTilrettelagtkommunikasjon();
        kom.talespraaktolk = new PDL_Tolk();
        kom.talespraaktolk.spraak = 'NO';
        kafkaPerson.hentPerson.tilrettelagtKommunikasjon.add(kom);
        PdlFullmakt fullmakt = new PdlFullmakt();
        fullmakt.motpartsRolle = PDL_FullmaktsRolle.FULLMEKTIG;
        fullmakt.motpartsPersonident = '12345678910';
        fullmakt.omraader = new List<String>{ 'DAG' };
        fullmakt.gyldigFraOgMed = Date.valueOf('2020-02-14');
        fullmakt.gyldigTilOgMed = Date.valueOf('2020-02-28');
        kafkaPerson.hentPerson.fullmakt.add(fullmakt);
        PdlVergemaalellerfremtidsfullmakt verge = new PdlVergemaalellerfremtidsfullmakt();
        verge.type = 'stadfestetFremtidsfullmakt';
        verge.embete = 'Statsforvalter';
        verge.vergeEllerFullmektig = new PDL_VergeEllerFullmektig();
        verge.vergeEllerFullmektig.navn = null;
        verge.vergeEllerFullmektig.motpartsPersonident = '12345678910';
        verge.vergeEllerFullmektig.omfang = 'Personlige og/eller økonomiske interesser';
        verge.vergeEllerFullmektig.omfangetErInnenPersonligOmraade = true;
        kafkaPerson.hentPerson.vergemaalEllerFremtidsfullmakt.add(verge);

        KafkaMessage__c message = createKafkaMessage('1122334455666', kafkaPerson);
        System.Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        assertProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );
        Person__c person = getPersonAccountByActorIdent().get('1122334455666');

        Assert.areEqual('1122334455666', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        Assert.areEqual('12345678901', person.INT_fnr__c, 'Expected FNR to be set');
        Assert.isNull(person.INT_npid__c, 'Expected NPID to be null');
        Assert.isNull(person.INT_dnr__c, 'Expect DNR to be null');
        Assert.areEqual('12345678901', person.Name, 'Expected NAME to be same as FNR');
        Assert.areEqual('2020-02-25', person.INT_DateOfBirth__c);
        Assert.areEqual('TREST', person.INT_FirstName__c);
        Assert.areEqual('T.', person.INT_MiddleName__c);
        Assert.areEqual('TRESTRESEN', person.INT_LastName__c);
        Assert.areEqual('Bosatt', person.INT_LegalStatus__c);
        Assert.isNotNull(person.INT_MovedFromCountry__c);
        Assert.areEqual('Delhi', person.INT_MovedFromPlace__c);
        Assert.areEqual('[{"metadata":null,"tiltakstype":"TFUS","kontaktperson":{"personident":"Z000000","enhet":"0000"},"gyldigTilOgMed":"2020-12-20","gyldigFraOgMed":"2020-12-14","beskrivelse":"Telefonisk utestengelse"}]', person.INT_SecurityMeasures__c);
        Assert.areEqual('Norge', person.INT_Citizenships__c);
        Assert.areEqual('GIFT', person.INT_MaritalStatus__c);
        Assert.areEqual(Date.newInstance(2001, 6, 20), person.INT_MaritalStatusDate__c);
        Assert.areEqual('12345678910', person.INT_MaritalRelation__c);
        Assert.areEqual('Mann', person.INT_Sex__c);
        Assert.areEqual('+47987 65 432', person.INT_Phone1__c);
        Assert.areEqual('+460765-43 21 07', person.INT_Phone2__c);
        Assert.isNotNull(person.INT_MovedToCountry__c);
        Assert.areEqual('Delhi', person.INT_MovedToPlace__c);
        Assert.areEqual('NO', person.INT_SpokenLanguageIntepreter__c);
        Assert.areEqual('[{"metadata":null,"omraader":["DAG"],"motpartsRolle":"FULLMEKTIG","motpartsPersonident":"12345678910","gyldigTilOgMed":"2020-02-28","gyldigFraOgMed":"2020-02-14"}]', person.INT_PowerOfAttorney__c);
        Assert.areEqual('[{"metadata":null,"vergeEllerFullmektig":{"omfangetErInnenPersonligOmraade":true,"omfang":"Personlige og/eller økonomiske interesser","navn":null,"motpartsPersonident":"12345678910"},"type":"stadfestetFremtidsfullmakt","folkeregistermetadata":null,"embete":"Statsforvalter"}]', person.INT_GuardianshipOrFuturePowerOfAttorney__c);
        Assert.areEqual('UGRADERT', person.INT_Confidential__c);
        Assert.areEqual(Date.newInstance(2019, 1, 29), person.INT_DateOfDeath__c);
        Assert.areEqual(true, person.INT_IsDeceased__c);
    }

    /********************
     * OTHER UNIT TESTS *
     *******************/

    /**
     * Ensure that persons are assigned the highest possible confidentiality
     * based on all their address protections.
     */
    @isTest
    static void testHighestGradeApplies() {
        PdlAdressebeskyttelse ungraded = new PdlAdressebeskyttelse();
        ungraded.gradering = PDL_AdressebeskyttelseGradering.UGRADERT;
        PdlAdressebeskyttelse confidential = new PdlAdressebeskyttelse();
        confidential.gradering = PDL_AdressebeskyttelseGradering.FORTROLIG;
        PdlAdressebeskyttelse strictlyConfidential = new PdlAdressebeskyttelse();
        strictlyConfidential.gradering = PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG;
        PdlAdressebeskyttelse strictConfAbroad = new PdlAdressebeskyttelse();
        strictConfAbroad.gradering = PDL_AdressebeskyttelseGradering.STRENGT_FORTROLIG_UTLAND;
        KafkaPerson3 fiferPig = createBaseKafkaPerson('8849688496884', '88496884968');
        KafkaPerson3 fiddlerPig = createBaseKafkaPerson('8154968154968', '81549681549');
        KafkaPerson3 practicalPig = createBaseKafkaPerson('9471759694717', '94717596947');
        KafkaPerson3 bigBadWolf = createBaseKafkaPerson('9691858969185', '96918589691');
        // strip existing protection, empty list should default to UGRADERT
        bigBadWolf.hentPerson.adressebeskyttelse = new List<PdlAdressebeskyttelse>();
        // add protection
        fiddlerPig.hentPerson.adressebeskyttelse.add(confidential);
        fiddlerPig.hentPerson.adressebeskyttelse.add(strictConfAbroad);
        practicalPig.hentPerson.adressebeskyttelse.add(strictConfAbroad);
        practicalPig.hentPerson.adressebeskyttelse.add(strictlyConfidential);
        practicalPig.hentPerson.adressebeskyttelse.add(confidential);
        // send, receive, test
        KafkaMessage__c message1 = createKafkaMessage('8849688496884', fiferPig);
        KafkaMessage__c message2 = createKafkaMessage('8154968154968', fiddlerPig);
        KafkaMessage__c message3 = createKafkaMessage('9471759694717', practicalPig);
        KafkaMessage__c message4 = createKafkaMessage('9691858969185', bigBadWolf);
        System.Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3, message4 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        System.Test.stopTest();
        KafkaMessage__c[] wtf = [SELECT Id, CRM_Key__c, CRM_Status__c, CRM_ErrorMessage__c from KafkaMessage__c];
        Person__c[] all = [SELECT Id, INT_ActorId__c, INT_Confidential__c from Person__c];
        Integer n = [SELECT COUNT() from Person__c];
        Person__c fiferPerson = [SELECT Id, INT_Confidential__c from Person__c where INT_ActorId__c = '8849688496884'][0];
        Person__c fiddlerPerson = [SELECT Id, INT_Confidential__c from Person__c where INT_ActorId__c = '8154968154968'][0];
        Person__c practicalPerson = [SELECT Id, INT_Confidential__c from Person__c where INT_ActorId__c = '9471759694717'][0];
        Person__c bigBadPerson = [SELECT Id, INT_Confidential__c from Person__c where INT_ActorId__c = '9691858969185'][0];
        Assert.areEqual('UGRADERT', fiferPerson.INT_Confidential__c);
        Assert.areEqual('STRENGT_FORTROLIG_UTLAND', fiddlerPerson.INT_Confidential__c);
        Assert.areEqual('STRENGT_FORTROLIG', practicalPerson.INT_Confidential__c);
        Assert.areEqual('UGRADERT', bigBadPerson.INT_Confidential__c);
    }

    /**
     * Ensure error is thrown on unknown address protection.
     */
    @isTest
    static void testUnknownAddressProtection() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                CRM_Key__c = '9471759694717',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"hentPerson":{"vergemaalEllerFremtidsfullmakt":[],"utflyttingFraNorge":[],"utenlandskIdentifikasjonsnummer":[],"tilrettelagtKommunikasjon":[],"telefonnummer":[],"statsborgerskap":[],"sivilstand":[],"sikkerhetstiltak":[],"oppholdsadresse":[],"opphold":[],"navn":[{"originaltNavn":null,"metadata":null,"mellomnavn":null,"gyldigFraOgMed":null,"fornavn":null,"forkortetNavn":null,"folkeregistermetadata":null,"etternavn":"TRESTRESEN"}],"kontaktinformasjonForDoedsbo":[],"kontaktadresse":[],"kjoenn":[],"innflyttingTilNorge":[],"identitetsgrunnlag":[],"fullmakt":[],"foreldreansvar":[],"forelderBarnRelasjon":[],"folkeregisterpersonstatus":[{"status":"bosatt","metadata":null,"forenkletStatus":null,"folkeregistermetadata":null}],"folkeregisteridentifikator":[],"foedsel":[],"falskIdentitet":null,"doedsfall":[],"doedfoedtBarn":[],"deltBosted":[],"bostedsadresse":[],"adressebeskyttelse":[{"metadata":null,"gradering":"LOLGRADERT","folkeregistermetadata":null},{"metadata":null,"gradering":"STRENGT_FORTROLIG_UTLAND","folkeregistermetadata":null},{"metadata":null,"gradering":"STRENGT_FORTROLIG","folkeregistermetadata":null},{"metadata":null,"gradering":"FORTROLIG","folkeregistermetadata":null}]},"hentIdenter":{"identer":[{"ident":"9471759694717","historisk":false,"gruppe":"AKTORID"},{"ident":"94717596947","historisk":false,"gruppe":"FOLKEREGISTERIDENT"}]}}')),
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        System.Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.processMessages(kafkaMessages);
        System.Test.stopTest();
        Assert.areEqual(
            KafkaMessageService.STATUS_ERROR,
            kafkaMessages[0].CRM_Status__c,
            '' + kafkaMessages[0].CRM_ErrorMessage__c
        );
    }

    /****************
     * TEST ADDRESS *
     ***************/

    /**
     * Tests that setAddress combines fields from kafka person correctly.
     */
    @IsTest
    static void setBostedVegadresse() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PdlBostedsadresse bo = new PdlBostedsadresse();
        bo.vegadresse = new PDL_Vegadresse();
        bo.vegadresse.adressenavn = 'Testveien';
        bo.vegadresse.husnummer = '1';
        bo.vegadresse.husbokstav = 'A';
        bo.vegadresse.postnummer = '0001';
        bo.vegadresse.kommunenummer = '4321';
        bo.vegadresse.bydelsnummer = '030110';
        bo.vegadresse.koordinater = (PDL_Koordinater)System.JSON.deserialize(
            '{"x":354424, "y":6862099, "z":0}', PDL_Koordinater.class);
        kafkaPerson.hentPerson.bostedsadresse.add(bo);
        Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.setAddress(person, kafkaPerson.hentPerson, null);
        Test.stopTest();
        Assert.areEqual(
            'Testveien 1 A',
            person.INT_ResidentialAddress__c,
            'Expected residential address to be set correctly'
        );
        Assert.areEqual('0001', person.INT_ResidentialZipCode__c, 'Expected residential zip code to be set');
        Assert.areEqual(
            '4321',
            person.INT_AddressMunicipalityNumber__c,
            'Expected Address Municipality number to be set'
        );
        Assert.areEqual(
            '030110',
            person.INT_AddressDistrictNumber__c,
            'Expected Address District number to be set'
        );
        Assert.areEqual('x=354424.0, y=6862099.0, z=0.0', person.INT_Coordinates__c, 'Expected coordinates to be set');
        Assert.isNull(person.INT_TemporaryAddress__c);
        Assert.isNull(person.INT_TemporaryZipCode__c);
        Assert.isNull(person.INT_TemporaryMunicipalityNumber__c);
        Assert.isNull(person.INT_TemporaryCoordinates__c);
        Assert.isNull(person.INT_TemporaryCountryCode__c);
    }

    /**
     * Tests that the historical address is not saved but the non-historical one is
     */
    @IsTest
    static void setNonHistoricalBosted() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('1122334455666');
        PdlBostedsadresse bo = new PdlBostedsadresse();
        bo.vegadresse = new PDL_Vegadresse();
        bo.vegadresse.adressenavn = 'Gamleveien';
        bo.vegadresse.husnummer = '1';
        bo.vegadresse.husbokstav = 'A';
        bo.vegadresse.postnummer = '0001';
        bo.vegadresse.kommunenummer = '4321';
        bo.vegadresse.bydelsnummer = '030110';
        bo.vegadresse.koordinater = (PDL_Koordinater)System.JSON.deserialize(
            '{"x":354424, "y":6862099, "z":0}', PDL_Koordinater.class);
        bo.metadata = new PDL_Metadata();
        bo.metadata.historisk = true;
        kafkaPerson.hentPerson.bostedsadresse.add(bo);
        bo = new PdlBostedsadresse();
        bo.vegadresse = new PDL_Vegadresse();
        bo.vegadresse.adressenavn = 'Nyveien';
        bo.vegadresse.husnummer = '2';
        bo.vegadresse.husbokstav = 'B';
        bo.vegadresse.postnummer = '0002';
        bo.vegadresse.kommunenummer = '5432';
        bo.vegadresse.bydelsnummer = '141221';
        bo.vegadresse.koordinater = (PDL_Koordinater)System.JSON.deserialize(
            '{"x":354424, "y":6862099, "z":0}', PDL_Koordinater.class);
        kafkaPerson.hentPerson.bostedsadresse.add(bo);
        Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.setAddress(person, kafkaPerson.hentPerson, null);
        Test.stopTest();
        Assert.areEqual(
            'Nyveien 2 B',
            person.INT_ResidentialAddress__c,
            'Expected residential address to be set correctly'
        );
        Assert.areEqual('0002', person.INT_ResidentialZipCode__c, 'Expected residential zip code to be set');
        Assert.areEqual(
            '5432',
            person.INT_AddressMunicipalityNumber__c
        );
        Assert.areEqual(
            '141221',
            person.INT_AddressDistrictNumber__c
        );
        Assert.isNull(person.INT_TemporaryAddress__c);
        Assert.isNull(person.INT_TemporaryZipCode__c);
        Assert.isNull(person.INT_TemporaryMunicipalityNumber__c);
        Assert.isNull(person.INT_TemporaryCoordinates__c);
        Assert.isNull(person.INT_TemporaryCountryCode__c);
    }

    /**
     * Test secondary address, and that setAddress is actually called.
     */
    @IsTest
    static void setBostedCadastralAddress() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
                new KafkaMessage__c(
                    CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                    CRM_Key__c = '9011710145110',
                    CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"hentPerson":{"vergemaalEllerFremtidsfullmakt":[],"utflyttingFraNorge":[],"utenlandskIdentifikasjonsnummer":[],"tilrettelagtKommunikasjon":[],"telefonnummer":[],"statsborgerskap":[],"sivilstand":[],"sikkerhetstiltak":[],"oppholdsadresse":[],"opphold":[],"navn":[{"etternavn":"TRESTRESEN"}],"kontaktinformasjonForDoedsbo":[],"kontaktadresse":[],"kjoenn":[],"innflyttingTilNorge":[],"identitetsgrunnlag":[],"fullmakt":[],"foreldreansvar":[],"forelderBarnRelasjon":[],"folkeregisterpersonstatus":[{"status":"bosatt"}],"folkeregisteridentifikator":[],"foedsel":[],"doedsfall":[],"doedfoedtBarn":[],"deltBosted":[],"bostedsadresse":[{"matrikkeladresse":{"postnummer":"4096","kommunenummer":"8192","bydelsnummer":"262144","koordinater":{"x":4806741,"y":1286234,"z":-1}}}],"adressebeskyttelse":[]},"hentIdenter":{"identer":[{"ident":9011710145110,"historisk":false,"gruppe":"AKTORID"},{"ident":90117101451,"historisk":false,"gruppe":"FOLKEREGISTERIDENT"}]}}')),
                    CRM_Status__c = KafkaMessageService.STATUS_PENDING
                    )
                );
        System.Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.processMessages(kafkaMessages);
        System.Test.stopTest();
        Person__c p = [SELECT Id, INT_ResidentialZipCode__c, INT_AddressMunicipalityNumber__c, INT_AddressDistrictNumber__c, INT_Coordinates__c FROM Person__c][0];
        Assert.areEqual('4096', p.INT_ResidentialZipCode__c);
        Assert.areEqual('8192', p.INT_AddressMunicipalityNumber__c);
        Assert.areEqual('262144', p.INT_AddressDistrictNumber__c);
        Assert.areEqual('x=4806741.0, y=1286234.0, z=-1.0', p.INT_Coordinates__c);
    }

    /**
     * Tests that address protection actually works
     */
    @IsTest
    static void dontSetProtectedAddress() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
                new KafkaMessage__c(
                    CRM_Topic__c = KafkaPdlPersondokumentHandler.PD_TOPIC,
                    CRM_Key__c = '9011710145110',
                    CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf('{"hentPerson":{"vergemaalEllerFremtidsfullmakt":[],"utflyttingFraNorge":[],"utenlandskIdentifikasjonsnummer":[],"tilrettelagtKommunikasjon":[],"telefonnummer":[],"statsborgerskap":[],"sivilstand":[],"sikkerhetstiltak":[],"oppholdsadresse":[],"opphold":[],"navn":[{"etternavn":"TRESTRESEN"}],"kontaktinformasjonForDoedsbo":[],"kontaktadresse":[],"kjoenn":[],"innflyttingTilNorge":[],"identitetsgrunnlag":[],"fullmakt":[],"foreldreansvar":[],"forelderBarnRelasjon":[],"folkeregisterpersonstatus":[{"status":"bosatt"}],"folkeregisteridentifikator":[],"foedsel":[],"doedsfall":[],"doedfoedtBarn":[],"deltBosted":[],"bostedsadresse":[{"matrikkeladresse":{"postnummer":"4096","kommunenummer":"8192","bydelsnummer":"262144","koordinater":{"x":4806741,"y":1286234,"z":-1}}}],"adressebeskyttelse":[{"gradering":"STRENGT_FORTROLIG"}]},"hentIdenter":{"identer":[{"ident":9011710145110,"historisk":false,"gruppe":"AKTORID"},{"ident":90117101451,"historisk":false,"gruppe":"FOLKEREGISTERIDENT"}]}}')),
                    CRM_Status__c = KafkaMessageService.STATUS_PENDING
                    )
                );
        System.Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.processMessages(kafkaMessages);
        System.Test.stopTest();
        Person__c p = [SELECT Id, INT_ActorId__c, INT_ResidentialZipCode__c, INT_AddressMunicipalityNumber__c, INT_AddressDistrictNumber__c, INT_Coordinates__c FROM Person__c][0];
        Assert.areEqual('9011710145110', p.INT_ActorId__c);
        Assert.isNull(p.INT_ResidentialZipCode__c);
    }

    /**
     * Tests temporary address
     */
    @IsTest
    static void setOppholdVegadresse() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson3 kafkaPerson = createBaseKafkaPerson('11223344556');
        PdlOppholdsadresse opphold = new PdlOppholdsadresse();
        opphold.vegadresse = new PDL_Vegadresse();
        opphold.vegadresse.adressenavn = 'Testveien';
        opphold.vegadresse.husnummer = '1';
        opphold.vegadresse.husbokstav = 'A';
        opphold.vegadresse.postnummer = '0001';
        opphold.vegadresse.kommunenummer = '4321';
        opphold.vegadresse.bydelsnummer = '030110';
        opphold.vegadresse.koordinater = (PDL_Koordinater)System.JSON.deserialize(
            '{"x":354424, "y":6862099, "z":0}', PDL_Koordinater.class);
        kafkaPerson.hentPerson.oppholdsadresse.add(opphold);
        Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.setAddress(person, kafkaPerson.hentPerson, null);
        Test.stopTest();
        Assert.isNull(person.INT_ResidentialAddress__c);
        Assert.isNull(person.INT_ResidentialZipCode__c);
        Assert.isNull(person.INT_AddressMunicipalityNumber__c);
        Assert.isNull(person.INT_Coordinates__c);
        Assert.areEqual('Testveien 1 A', person.INT_TemporaryAddress__c);
        Assert.areEqual('0001', person.INT_TemporaryZipCode__c);
        Assert.areEqual('4321',person.INT_TemporaryMunicipalityNumber__c);
        Assert.areEqual('x=354424.0, y=6862099.0, z=0.0',person.INT_TemporaryCoordinates__c);
        Assert.isNull(person.INT_TemporaryCountryCode__c);
    }

    /**
     * Tests that when two valid messages with the same key appear in the same
     * batch, they are both processed, and the result is one person with the
     * values sent in the last message.
     */
    @IsTest
    static void testDuplicateKeys() {
        KafkaPerson3 jekyll = createBaseKafkaPerson('3138428376721', '25937424601');
        jekyll.hentPerson.navn[0].fornavn = 'HENRY';
        jekyll.hentPerson.navn[0].etternavn = 'JEKYLL';
        KafkaPerson3 hyde = createBaseKafkaPerson('3138428376721', '25937424601');
        hyde.hentPerson.navn[0].etternavn = 'HYDE';
        KafkaMessage__c[] messages = new KafkaMessage__c[]{
            createKafkaMessage('3138428376721', jekyll),
            createKafkaMessage('3138428376721', hyde)};
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        Test.startTest();
        handler.processMessages(messages);
        Test.stopTest();
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[0].CRM_Status__c);
        Assert.areEqual(KafkaMessageService.STATUS_PROCESSED, messages[1].CRM_Status__c);
        Person__c[] persons = [SELECT INT_FirstName__c, INT_LastName__c from Person__c];
        Assert.areEqual(1, persons.size());
        Assert.areEqual('HYDE', persons[0].INT_LastName__c);
        Assert.isNull(persons[0].INT_FirstName__c);
    }

    /**
     * Tests that interpreter languages arrive in the correct format when there
     * are more or less than one of them.
     */
    @IsTest
    static void testNoneOrMultipleInterpreterLanguages() {
        PdlTilrettelagtkommunikasjon[] polyComms = new List<PdlTilrettelagtkommunikasjon>();
        PdlTilrettelagtkommunikasjon[] noComms = new List<PdlTilrettelagtkommunikasjon>();
        PdlTilrettelagtkommunikasjon comm1 = new PdlTilrettelagtkommunikasjon();
        comm1.talespraaktolk = new PDL_Tolk();
        comm1.talespraaktolk.spraak = '漢語';
        polyComms.add(comm1);
        PdlTilrettelagtkommunikasjon comm2 = new PdlTilrettelagtkommunikasjon();
        comm2.talespraaktolk = new PDL_Tolk();
        comm2.talespraaktolk.spraak = 'IT';
        polyComms.add(comm2);
        Test.startTest();
        String polyResult = KafkaPdlPersondokumentHandler.interpreterLanguagesString(polyComms);
        String noResult = KafkaPdlPersondokumentHandler.interpreterLanguagesString(noComms);
        Test.stopTest();
        Assert.areEqual('漢語;IT', polyResult);
        Assert.isNull(noResult);
    }
}
