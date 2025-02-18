@isTest
private class PDL_API_QueryTest {
    @isTest
    private static void makePersonTest(){
        PDL_API_QueryHelper q = new PDL_API_QueryHelper('12106519356');
        q.selectAll(true);
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        Test.startTest();
        PDL_API_Response r = q.execute();
        Person__c p = PDL_API_Query.makePersonFromResponse(r);
        Test.stopTest();
        System.assertNotEquals(null, r);
        System.assertEquals('2762473496911',p.INT_ActorID__c);
        System.assertEquals('12106519356',p.Name);
        System.assertEquals('1965-10-12',p.INT_DateOfBirth__c);
        System.assertEquals('VAKKER',p.INT_FirstName__c);
        System.assertEquals('SLØVENDE',p.INT_MiddleName__c);
        System.assertEquals('SNERK',p.INT_LastName__c);
        //System.assertEquals('',p.INT_FamilyRelations__c);
        //System.assertEquals('',p.INT_LegalStatus__c);
        //System.assertEquals('',p.INT_MovedFromCountry__c);
        //System.assertEquals('',p.INT_MovedFromPlace__c);
        //System.assertEquals('',p.INT_Confidential__c);
        //System.assertEquals('',p.INT_SecurityMeasures__c);
        System.assertEquals('Plassavegen 1',p.INT_ResidentialAddress__c);
        System.assertEquals('6636',p.INT_ResidentialZipCode__c);
        System.assertEquals('1557',p.INT_AddressMunicipalityNumber__c);
        //System.assertEquals('',p.INT_Coordinates__c);
        //System.assertEquals('',p.INT_TemporaryMunicipalityNumber__c);
        //System.assertEquals('',p.INT_TemporaryAddress__c);
        //System.assertEquals('',p.INT_TemporaryZipCode__c);
        //System.assertEquals('',p.INT_TemporaryMunicipalityNumber__c);
        //System.assertEquals('',p.INT_TemporaryCoordinates__c);
        //System.assertEquals('',p.INT_TemporaryCountryCode__c);
        //System.assertEquals('',p.INT_Citizenships__c);
        //System.assertEquals('UGIFT',p.INT_MaritalStatus__c);
        //System.assertEquals('',p.INT_MaritalStatusDate__c);
        //System.assertEquals('',p.INT_MaritalRelation__c);
        //System.assertEquals('MANN',p.INT_Sex__c);
        //System.assertEquals('',p.INT_DateOfDeath__c);
        //System.assertEquals(false,p.INT_IsDeceased__c);
        //System.assertEquals('',p.INT_Phone1__c);
        //System.assertEquals('',p.INT_Phone2__c);
        //System.assertEquals('',p.INT_MovedToCountry__c);
        //System.assertEquals('',p.INT_MovedToPlace__c);
        //System.assertEquals('',p.INT_SpokenLanguageInterpreter__c);
        //System.assertEquals('',p.INT_PowerOfAttorney__c);
        //System.assertEquals('',p.GuardianshipOrFuturePowerOfAttorney__c);
    }
    @isTest
    private static void NavnTest() {
        String expected =
        '{"variables":{"ident":"1234567890"},"query":"query ($ident: ID! ){ hentPerson(ident : $ident ){ navn(historikk : false ){ fornavn mellomnavn etternavn}}}"}';
        String actual = PDL_API_Query.Navn('1234567890');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
    @isTest
    private static void getRelationsByRoleTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        Test.startTest();
        List<String> l = PDL_API_Query.getRelationsByRole('12106519356', PDL_ForelderBarnRelasjonRolle.BARN);
        Test.stopTest();
        System.assertNotEquals(null, l);
        System.assertEquals(false, l.isEmpty());
        System.assertEquals('02091379875', l[0]);
    }
    @isTest
    private static void getChildDataTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        PDL_API_Response r = PDL_API_Query.getChildData('12106519356');
        System.assertNotEquals(null, r);
        System.assertEquals(1965, r.data.hentPerson.foedsel[0].foedselsaar);
    }
    @isTest
    private static void getChildrenTest(){
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        List<PDL_API_Response> rl = PDL_API_Query.getChildren('12106519356');
        System.assertNotEquals(null, rl);
        System.assertEquals(1, rl.size());
    }
    @isTest
    private static void AnsvarssubjektTest(){
        String expected =
        '{"variables":{"ident":"1234567890"},"query":"query ($ident: ID! ){ hentPerson(ident : $ident ){ foreldreansvar(historikk : false ){ ansvarssubjekt}}}"}';
        String actual = PDL_API_Query.Ansvarssubjekt('1234567890');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
    @isTest
    private static void allFieldsTest(){
        String expected = 
        '{' +
            '"variables":{"grupper":["AKTORID","FOLKEREGISTERIDENT","NPID"],"ident":"12345678901"},' +
            '"query":"query ($ident: ID! $grupper: [IdentGruppe!] ){ ' +
                'hentPerson(ident : $ident ){ ' +
                    'adressebeskyttelse(historikk : false ){ ' +
                        'gradering ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'bostedsadresse(historikk : false ){ ' +
                        'angittFlyttedato ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'coAdressenavn ' +
                        'vegadresse{ ' +
                            'matrikkelId ' +
                            'husnummer ' +
                            'husbokstav ' +
                            'bruksenhetsnummer ' +
                            'adressenavn ' +
                            'kommunenummer ' +
                            'bydelsnummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'utenlandskAdresse{ ' +
                            'adressenavnNummer ' +
                            'bygningEtasjeLeilighet ' +
                            'postboksNummerNavn ' +
                            'postkode ' +
                            'bySted ' +
                            'regionDistriktOmraade ' +
                            'landkode' +
                        '} ' +
                        'ukjentBosted{ bostedskommune} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'deltBosted(historikk : false ){ ' +
                        'startdatoForKontrakt ' +
                        'sluttdatoForKontrakt ' +
                        'coAdressenavn ' +
                        'vegadresse{ ' +
                            'matrikkelId ' +
                            'husnummer ' +
                            'husbokstav ' +
                            'bruksenhetsnummer ' +
                            'adressenavn ' +
                            'kommunenummer ' +
                            'bydelsnummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'utenlandskAdresse{ ' +
                            'adressenavnNummer ' +
                            'bygningEtasjeLeilighet ' +
                            'postboksNummerNavn ' +
                            'postkode ' +
                            'bySted ' +
                            'regionDistriktOmraade ' +
                            'landkode' +
                        '} ' +
                        'ukjentBosted{ bostedskommune} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'doedfoedtBarn{ ' + 
                        'dato ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'doedsfall{ ' +
                        'doedsdato ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'falskIdentitet{ ' +
                        'erFalsk ' +
                        'rettIdentitetVedIdentifikasjonsnummer ' +
                        'rettIdentitetErUkjent ' +
                        'rettIdentitetVedOpplysninger{ ' +
                            'personnavn{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'foedselsdato ' +
                            'statsborgerskap ' +
                            'kjoenn' +
                        '} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'foedsel{ ' +
                        'foedselsaar ' +
                        'foedselsdato ' +
                        'foedeland ' +
                        'foedested ' +
                        'foedekommune ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'foedested{ ' +
                        'foedeland ' +
                        'foedested ' +
                        'foedekommune ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'foedselsdato{ ' +
                        'foedselsaar ' +
                        'foedselsdato ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'folkeregisteridentifikator(historikk : false ){ ' +
                        'identifikasjonsnummer ' +
                        'status ' +
                        'type ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'folkeregisterpersonstatus(historikk : false ){ ' +
                        'status ' +
                        'forenkletStatus ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'forelderBarnRelasjon{ ' +
                        'relatertPersonsIdent ' +
                        'relatertPersonsRolle ' +
                        'minRolleForPerson ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'foreldreansvar(historikk : false ){ ' +
                        'ansvar ' +
                        'ansvarlig ' +
                        'ansvarssubjekt ' +
                        'ansvarligUtenIdentifikator{ ' +
                            'navn{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'foedselsdato ' +
                            'statsborgerskap ' +
                            'kjoenn' +
                        '} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'fullmakt(historikk : false ){ ' +
                        'motpartsPersonident ' +
                        'motpartsRolle ' +
                        'omraader ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'identitetsgrunnlag(historikk : false ){ ' +
                        'status ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'kjoenn(historikk : false ){ ' +
                        'kjoenn ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'kontaktadresse(historikk : false ){ ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'type ' +
                        'coAdressenavn ' +
                        'postboksadresse{ ' +
                            'postbokseier ' +
                            'postboks ' +
                            'postnummer' +
                        '} ' +
                        'vegadresse{ ' +
                            'matrikkelId ' +
                            'husnummer ' +
                            'husbokstav ' +
                            'bruksenhetsnummer ' +
                            'adressenavn ' +
                            'kommunenummer ' +
                            'bydelsnummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'postadresseIFrittFormat{ ' +
                            'adresselinje1 ' +
                            'adresselinje2 ' +
                            'adresselinje3 ' +
                            'postnummer' +
                        '} ' +
                        'utenlandskAdresse{ ' +
                            'adressenavnNummer ' +
                            'bygningEtasjeLeilighet ' +
                            'postboksNummerNavn ' +
                            'postkode ' +
                            'bySted ' +
                            'regionDistriktOmraade ' +
                            'landkode' +
                        '} ' +
                        'utenlandskAdresseIFrittFormat{ ' +
                            'adresselinje1 ' +
                            'adresselinje2 ' +
                            'adresselinje3 ' +
                            'postkode ' +
                            'byEllerStedsnavn ' +
                            'landkode' +
                        '} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'kontaktinformasjonForDoedsbo(historikk : false ){ ' +
                        'skifteform ' +
                        'attestutstedelsesdato ' +
                        'personSomKontakt{ ' +
                            'foedselsdato ' +
                            'personnavn{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'identifikasjonsnummer' +
                        '} ' +
                        'advokatSomKontakt{ ' +
                            'personnavn{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'organisasjonsnavn ' +
                            'organisasjonsnummer' +
                        '} ' +
                        'organisasjonSomKontakt{ ' +
                            'kontaktperson{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'organisasjonsnavn ' +
                            'organisasjonsnummer' +
                        '} ' +
                        'adresse{ ' +
                            'adresselinje1 ' +
                            'adresselinje2 ' +
                            'poststedsnavn ' +
                            'postnummer ' +
                            'landkode' +
                        '} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'navn(historikk : false ){ ' +
                        'fornavn ' +
                        'mellomnavn ' +
                        'etternavn ' +
                        'forkortetNavn ' +
                        'originaltNavn{ ' +
                            'fornavn ' +
                            'mellomnavn ' +
                            'etternavn' +
                        '} ' +
                        'gyldigFraOgMed ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'opphold(historikk : false ){ ' +
                        'type ' +
                        'oppholdFra ' +
                        'oppholdTil ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'oppholdsadresse(historikk : false ){ ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'coAdressenavn ' +
                        'utenlandskAdresse{ ' +
                            'adressenavnNummer ' +
                            'bygningEtasjeLeilighet ' +
                            'postboksNummerNavn ' +
                            'postkode ' +
                            'bySted ' +
                            'regionDistriktOmraade ' +
                            'landkode' +
                        '} ' +
                        'vegadresse{ ' +
                            'matrikkelId ' +
                            'husnummer ' +
                            'husbokstav ' +
                            'bruksenhetsnummer ' +
                            'adressenavn ' +
                            'kommunenummer ' +
                            'bydelsnummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater{ ' +
                                'x ' +
                                'y ' +
                                'z ' +
                                'kvalitet' +
                            '}' +
                        '} ' +
                        'oppholdAnnetSted ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'sikkerhetstiltak{ ' +
                        'tiltakstype ' +
                        'beskrivelse ' +
                        'kontaktperson{ ' +
                            'personident ' +
                            'enhet' +
                        '} ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'sivilstand(historikk : false ){ ' +
                        'type ' +
                        'gyldigFraOgMed ' +
                        'relatertVedSivilstand ' +
                        'bekreftelsesdato ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'statsborgerskap(historikk : false ){ ' +
                        'land ' +
                        'bekreftelsesdato ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'telefonnummer{ ' +
                        'landskode ' +
                        'nummer ' +
                        'prioritet ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'tilrettelagtKommunikasjon{ ' +
                        'talespraaktolk{ ' +
                            'spraak' +
                        '} ' +
                        'tegnspraaktolk{ ' +
                            'spraak' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'utenlandskIdentifikasjonsnummer(historikk : false ){ ' +
                        'identifikasjonsnummer ' +
                        'utstederland ' +
                        'opphoert ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'innflyttingTilNorge{ ' +
                        'fraflyttingsland ' +
                        'fraflyttingsstedIUtlandet ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'utflyttingFraNorge{ ' +
                        'tilflyttingsland ' +
                        'tilflyttingsstedIUtlandet ' +
                        'utflyttingsdato ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '} ' +
                    'vergemaalEllerFremtidsfullmakt(historikk : false ){ ' +
                        'type ' +
                        'embete ' +
                        'vergeEllerFullmektig{ ' +
                            'motpartsPersonident ' +
                            'omfang ' +
                            'omfangetErInnenPersonligOmraade ' +
                            'tjenesteomraade{ ' +
                                'tjenesteoppgave ' +
                                'tjenestevirksomhet' +
                            '} ' +
                            'identifiserendeInformasjon{ ' +
                                'navn{ ' +
                                    'fornavn ' +
                                    'mellomnavn ' +
                                    'etternavn' +
                                '} ' +
                                'kjoenn ' +
                                'foedselsdato ' +
                                'statsborgerskap' +
                            '}' +
                        '} ' +
                        'folkeregistermetadata{ ' +
                            'ajourholdstidspunkt ' +
                            'gyldighetstidspunkt ' +
                            'opphoerstidspunkt ' +
                            'kilde ' +
                            'aarsak ' +
                            'sekvens' +
                        '} ' +
                        'metadata{ ' +
                            'opplysningsId ' +
                            'master ' +
                            'endringer{ ' +
                                'type ' +
                                'registrert ' +
                                'registrertAv ' +
                                'systemkilde ' +
                                'kilde' +
                            '} ' +
                            'historisk' +
                        '}' +
                    '}' +
                '}' +

                ' ' +
                'hentIdenter(ident : $ident historikk : false grupper : $grupper ){ ' +
                    'identer{ ' +
                        'ident ' +
                        'gruppe ' +
                        'historisk' +
                    '}' +
                '}' +

            '}"' +
        '}';
        String actual = PDL_API_Query.allFields('12345678901');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
}
