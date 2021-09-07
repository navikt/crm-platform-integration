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
                    'adressebeskyttelse(historikk : false ){ gradering} ' +
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
                            'koordinater' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater' +
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
                        'ukjentBosted{ bostedskommune}' +
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
                            'koordinater' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater' +
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
                        'ukjentBosted{ bostedskommune}' +
                    '} ' +
                    'doedfoedtBarn{ dato} ' +
                    'doedsfall{ doedsdato} ' +
                    'falskIdentitet{ ' +
                        'erFalsk ' +
                        'rettIdentitetVedIdentifikasjonsnummer ' +
                        'rettIdentitetErUkjent ' +
                        'rettIdentitetVedOpplysninger' +
                    '} ' +
                    'foedsel{ ' +
                        'foedselsaar ' +
                        'foedselsdato ' +
                        'foedeland ' +
                        'foedested ' +
                        'foedekommune' +
                    '} ' +
                    'folkeregisteridentifikator(historikk : false ){ ' +
                        'identifikasjonsnummer ' +
                        'status ' +
                        'type' +
                    '} ' +
                    'folkeregisterpersonstatus(historikk : false ){ ' +
                        'status ' +
                        'forenkletStatus' +
                    '} ' +
                    'forelderBarnRelasjon{ ' +
                        'relatertPersonsIdent ' +
                        'relatertPersonsRolle ' +
                        'minRolleForPerson' +
                    '} ' +
                    'foreldreansvar(historikk : false ){ ' +
                        'ansvar ' +
                        'ansvarlig ' +
                        'ansvarssubjekt ' +
                        'ansvarligUtenIdentificator' +
                    '} ' +
                    'fullmakt(historikk : false ){ ' +
                        'motpartsPersonident ' +
                        'motpartsRolle ' +
                        'omraader ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed' +
                    '} ' +
                    'identitetsgrunnlag(historikk : false ){ status} ' +
                    'kjoenn(historikk : false ){ kjoenn} ' +
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
                            'koordinater' +
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
                        '}' +
                    '} ' +
                    'kontaktinformasjonForDoedsbo(historikk : false ){ ' +
                        'skifteform ' +
                        'attestutstedelsesdato ' +
                        'personSomKontakt{ ' +
                            'foedselsdato ' +
                            'personnavn ' +
                            'identifikasjonsnummer' +
                        '} ' +
                        'advokatSomKontakt{ ' +
                            'personnavn ' +
                            'organisasjonsnavn ' +
                            'organisasjonsnummer' +
                        '} ' +
                        'organisasjonSomKontakt{ ' +
                            'kontaktperson ' +
                            'organisasjonsnavn ' +
                            'organisasjonsnummer' +
                        '} ' +
                        'adresse{ ' +
                            'adresselinje1 ' +
                            'adresselinje2 ' +
                            'poststedsnavn ' +
                            'postnummer ' +
                            'landkode' +
                        '}' +
                    '} ' +
                    'navn(historikk : false ){ ' +
                        'fornavn ' +
                        'mellomnavn ' +
                        'etternavn ' +
                        'forkortetNavn ' +
                        'originaltNavn ' +
                        'gyldigFraOgMed' +
                    '} ' +
                    'opphold(historikk : false ){ ' +
                        'type ' +
                        'oppholdFra ' +
                        'oppholdTil' +
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
                            'koordinater' +
                        '} ' +
                        'matrikkeladresse{ ' +
                            'matrikkelId ' +
                            'bruksenhetsnummer ' +
                            'kommunenummer ' +
                            'tilleggsnavn ' +
                            'postnummer ' +
                            'koordinater' +
                        '} ' +
                        'oppholdAnnetSted' +
                    '} ' +
                    'sikkerhetstiltak{ ' +
                        'tiltakstype ' +
                        'beskrivelse ' +
                        'kontaktperson{ ' +
                            'personident ' +
                            'enhet' +
                        '} ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed' +
                    '} ' +
                    'sivilstand(historikk : false ){ ' +
                        'type ' +
                        'gyldigFraOgMed ' +
                        'relatertVedSivilstand ' +
                        'bekreftelsesdato' +
                    '} ' +
                    'statsborgerskap(historikk : false ){ ' +
                        'land ' +
                        'bekreftelsesdato ' +
                        'gyldigFraOgMed ' +
                        'gyldigTilOgMed' +
                    '} ' +
                    'telefonnummer{ ' +
                        'landskode ' +
                        'nummer ' +
                        'prioritet' +
                    '} ' +
                    'tilrettelagtKommunikasjon{ ' +
                        'talespraaktolk ' +
                        'tegnspraaktolk' +
                    '} ' +
                    'utenlandskIdentifikasjonsnummer(historikk : false ){ ' +
                        'identifikasjonsnummer ' +
                        'utstederland ' +
                        'opphoert' +
                    '} ' +
                    'innflyttingTilNorge(historikk : false ){ ' +
                        'fraflyttingsland ' +
                        'fraflyttingsstedIUtlandet' +
                    '} ' +
                    'utflyttingFraNorge(historikk : false ){ ' +
                        'tilflyttingsland ' +
                        'tilflyttingsstedIUtlandet ' +
                        'utflyttingsdato' +
                    '} ' +
                    'vergemaalEllerFremtidsfullmakt(historikk : false ){ ' +
                        'type ' +
                        'embete ' +
                        'vergeEllerFullmektig' +
                    '}' +
                '}' +
            '}"' +
        '}';
        String actual = PDL_API_Query.allFields('12345678901');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
}
