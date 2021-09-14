@isTest
private class PDL_API_QueryTest {
    @isTest
    private static void NavnTest() {
        String expected =
        '{"variables":{"ident":"1234567890"},"query":"query ($ident: ID! ){ hentPerson(ident : $ident ){ navn(historikk : false ){ fornavn mellomnavn etternavn}}}"}';
        String actual = PDL_API_Query.Navn('1234567890');
        System.debug(actual);
        System.assertEquals(expected, actual);
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
            '"variables":{"ident":"12345678901"},' +
            '"query":"query ($ident: ID! ){ ' +
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
                            'navn{ ' +
                                'fornavn ' +
                                'mellomnavn ' +
                                'etternavn' +
                            '} ' +
                            'motpartsPersonident ' +
                            'omfang ' +
                            'omfangetErInnenPersonligOmraade' +
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
            '}"' +
        '}';
        String actual = PDL_API_Query.allFields('12345678901');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
}
