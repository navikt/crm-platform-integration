public with sharing class PDL_API_Query {

    @TestVisible
    private static final Map<String, Integer> ADR_BESKYTTELSES_GRADERING = new Map<String, Integer>{
        'STRENGT_FORTROLIG' => 4,
        'STRENGT_FORTROLIG_UTLAND' => 3,
        'FORTROLIG' => 2,
        'UGRADERT' => 1
    };
    @TestVisible
    private static final Map<String, Common_Code__c> ISO_MAP = createIsoMap(
        [
            SELECT Name, CRM_Code__c
            FROM Common_Code__c
            WHERE CRM_Active__c = TRUE AND CRM_Code_Set__c IN ('Landkoder', 'LandkoderISO2')
        ]
    );

    public static List<PDL_API_Response> getChildren(String ident){
        List<String> ChildrenId = getRelationsByRole(ident, PDL_ForelderBarnRelasjonRolle.BARN);
        List<PDL_API_Response> result = new List<PDL_API_Response>();
        for(String childId : ChildrenId){
            result.add( getChildData(childId) );
        }
        return result;
    }

    public static List<String> getRelationsByRole(String ident, PDL_ForelderBarnRelasjonRolle role){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.forelderBarnRelasjon.selectAll();
        PDL_API_Response pdl = query.execute();
        List<String> result = new List<String>();
        for(PDL_ForelderBarnRelasjon relation : pdl.data.hentPerson.forelderBarnRelasjon){
            if(relation.relatertPersonsRolle == role){
                result.add(relation.relatertPersonsIdent);
            }
        }
        return result;
    }

    public static PDL_API_Response getChildData(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        query.hentPerson.adressebeskyttelse.gradering = true;
        query.hentPerson.foedsel.foedselsdato = true;
        query.hentPerson.foedsel.foedselsaar = true;
        query.hentPerson.kjoenn.kjoenn = true;
        return query.execute();
    }

    public static String Navn(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.navn.fornavn = true;
        query.hentPerson.navn.mellomnavn = true;
        query.hentPerson.navn.etternavn = true;
        return query.build();
    }

    public static Person__c makePersonFromResponse(PDL_API_Response response){
        Person__c person = new Person__c();
        person.INT_ActorId__c = PDL_IdentUtility.getAktorId(response);
        person.Name = PDL_IdentUtility.getFNR(response);
        if(person.Name == null) person.Name = PDL_IdentUtility.getDNR(response);

        person.INT_DateOfBirth__c = getFoedselsdato(response);
        setNavn(person, response);
        person.INT_FamilyRelations__c = getForelderBarnRelasjonJSON(response);
        person.INT_LegalStatus__c = getFolkeregisterpersonstatus(response);
        setInnflytting(person, response);
        person.INT_Confidential__c = getAdressebeskyttelse(response);
        person.INT_SecurityMeasures__c = getSikkerhetstiltakJSON(response);
        setBostedsadresse(person, response);
        setOppholdsadresse(person, response);
        person.INT_Citizenships__c = getStatsborgerskap(response);
        setSivilstand(person, response);
        person.INT_Sex__c = getKjoenn(response);
        setDeodsfall(person, response);
        setTelefonnummer(person, response);
        setUtflytting(person, response);
        person.INT_SpokenLanguageIntepreter__c = getTalespraaktolk(response);
        person.INT_PowerOfAttorney__c = getFullmaktJSON(response);
        person.INT_GuardianshipOrFuturePowerOfAttorney__c = getVergemaalEllerFremtidsfullmakt(response);

        return person;
    }
    private static String getVergemaalEllerFremtidsfullmakt(PDL_API_Response response){
        if(response.data?.hentPerson?.vergemaalEllerFremtidsfullmakt == null){
            return null;
        }
        if(response.data.hentPerson.vergemaalEllerFremtidsfullmakt.isEmpty()){
            return null;
        }
        return JSON.serialize(response.data.hentPerson.vergemaalEllerFremtidsfullmakt);
    }
    private static String getFullmaktJSON(PDL_API_Response response){
        if(response.data?.hentPerson?.fullmakt == null){
            return null;
        }
        if(response.data.hentPerson.fullmakt.isEmpty()){
            return null;
        }
        return JSON.serialize(response.data.hentPerson.fullmakt);
    }
    private static String getTalespraaktolk(PDL_API_Response response){
        if(response.data?.hentPerson?.tilrettelagtKommunikasjon == null){
            return null;
        }
        List<String> spraakList = new List<String>();
        for(PDL_TilrettelagtKommunikasjon tk : response.data.hentPerson.tilrettelagtKommunikasjon){
            if(tk.talespraaktolk?.spraak != null){
                spraakList.add(tk.talespraaktolk.spraak);
            }
        }
        if(!spraakList.isEmpty()){
            return safelyJoinMultiPicklistString(spraakList);
        }
        return null;
    }
    private static void setTelefonnummer(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.telefonnummer == null){
            return;
        }
        String phone1;
        String phone2;
        for(PDL_Telefonnummer telefonnummer : response.data.hentPerson.telefonnummer){
            if(telefonnummer.prioritet == 1){
                phone1 = getNummer(telefonnummer);
            }else if(telefonnummer.prioritet == 2){
                phone2 = getNummer(telefonnummer);
            }else{
                if(String.isBlank(phone1)){
                    phone1 = getNummer(telefonnummer);
                }else if(String.isBlank(phone2)){
                    phone2 = getNummer(telefonnummer);
                }
            }
        }
        person.INT_Phone1__c = phone1;
        person.INT_Phone2__c = phone2;
    }
    private static String getNummer(PDL_Telefonnummer telefonnummer){
        if(String.isBlank(telefonnummer.nummer)){
            return null;
        }
        if(String.isNotBlank(telefonnummer.landskode)){
            return telefonnummer.landskode + telefonnummer.nummer;
        }
        return telefonnummer.nummer;
    }
    private static void setDeodsfall(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.doedsfall == null){
            return;
        }
        Map<String, Date> doedsfallMap = new Map<String, Date>();
        String MASTER_UNDEFINED = 'undefined';
        for(PDL_Doedsfall doedsfall : response.data.hentPerson.doedsfall){
            if(doedsfall.metadata?.master != null){
                doedsfallMap.put(doedsfall.metadata.master.toLowerCase(), doedsfall.doedsdato);
            }else{
                doedsfallMap.put(MASTER_UNDEFINED, doedsfall.doedsdato);
            }
        }
        if(doedsfallMap.isEmpty()){
            return;
        }
        if(doedsfallMap.containsKey('PDL')){
            person.INT_DateOfDeath__c = doedsfallMap.get('PDL');
        }else if(doedsfallMap.containsKey('FREG')){
            person.INT_DateOfDeath__c = doedsfallMap.get('FREG');
        }else if(doedsfallMap.containsKey(MASTER_UNDEFINED)){
            person.INT_DateOFDeath__c = doedsfallMap.get(MASTER_UNDEFINED);
        }
        person.INT_IsDeceased__c = true;
    }
    private static String getKjoenn(PDL_API_Response response){
        if(response.data?.hentPerson?.kjoenn == null){
            return null;
        }
        for(PDL_Kjoenn kjoenn : response.data.hentPerson.kjoenn){
            if(kjoenn.metadata?.historisk != true){
                return kjoenn.kjoenn?.name();
            }
        }
        return null;
    }
    private static void setSivilstand(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.sivilstand == null){
            return;
        }
        for(PDL_Sivilstand sivilstand : response.data.hentPerson.sivilstand){
            if(sivilstand.metadata?.historisk != true){
                person.INT_MaritalStatus__c = sivilstand.type?.name();
                person.INT_MaritalStatusDate__c = sivilstand.gyldigFraOgMed;
                person.INT_MaritalRelation__c = sivilstand.relatertVedSivilstand;
                return;
            }
        }
    }
    private static String getStatsborgerskap(PDL_API_Response response){
        if(response.data?.hentPerson?.statsborgerskap == null){
            return null;
        }
        List<String> statsborgerskapList = new List<String>();
        for(PDL_Statsborgerskap statsborgerskap : response.data.hentPerson.statsborgerskap){
            if(statsborgerskap.metadata?.historisk != true && statsborgerskap.land != null){
                statsborgerskapList.add(statsborgerskap.land);
            }
        }
        if(statsborgerskapList.isEmpty()){
            return null;
        }
        return crateCitizenshipString(statsborgerskapList);
    }
    private static void setBostedsadresse(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.bostedsadresse == null){
            return;
        }
        for(PDL_Bostedsadresse ba : response.data.hentPerson.bostedsadresse){
            if(ba.metadata?.historisk != true){
                if(hasVegadresse(ba.vegadresse)){
                    person.INT_ResidentialAddress__c = addressCreator(
                        new List<String>{
                            ba.vegadresse.adressenavn,
                            ba.vegadresse.husnummer,
                            ba.vegadresse.husbokstav
                        }
                    );
                    person.INT_ResidentialZipCode__c = ba.vegadresse.postnummer;
                    person.INT_AddressMunicipalityNumber__c = ba.vegadresse.kommunenummer;
                    person.INT_AddressDistrictNumber__c = ba.vegadresse.bydelsnummer;
                    person.INT_Coordinates__c = JSON.serialize(ba.vegadresse.koordinater);
                }else if(hasMatrikkeladresse(ba.matrikkeladresse)){
                    person.INT_ResidentialZipCode__c = ba.matrikkeladresse.postnummer;
                    person.INT_AddressMunicipalityNumber__c = ba.matrikkeladresse.kommunenummer;
                    person.INT_Coordinates__c = JSON.serialize(ba.matrikkeladresse.koordinater);
                }else if(hasUkjentBosted(ba.ukjentBosted)){
                    person.INT_TemporaryMunicipalityNumber__c = ba.ukjentBosted.bostedskommune;
                }
                return;
            }
        }
    }

    private static Boolean hasVegadresse(PDL_Vegadresse vegadresse){
        return (vegadresse != null && 
                (vegadresse.adressenavn != null ||
                vegadresse.postnummer != null ||
                vegadresse.kommunenummer != null ||
                vegadresse.koordinater != null));
    }
    private static Boolean hasMatrikkeladresse(PDL_Matrikkeladresse matrikkeladresse){
        return (matrikkeladresse != null && (
                matrikkeladresse.postnummer != null ||
                matrikkeladresse.kommunenummer != null ||
                matrikkeladresse.koordinater != null));
    }
    private static Boolean hasUkjentBosted(PDL_UkjentBosted ukjentBosted){
        return (ukjentBosted?.bostedskommune != null);
    }
    private static Boolean hasUtenlandskAdresse(PDL_UtenlandskAdresse utenlandskAdresse){
        return (utenlandskAdresse?.landkode != null);
    }
    private static void setOppholdsadresse(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.oppholdsadresse == null){
            return;
        }
        for(PDL_Oppholdsadresse oa : response.data.hentPerson.oppholdsadresse){
            if(oa.metadata?.historisk != true){
                if(hasVegadresse(oa.vegadresse)){
                    person.INT_TemporaryAddress__c = addressCreator(
                        new List<String>{
                            oa.vegadresse.adressenavn,
                            oa.vegadresse.husnummer,
                            oa.vegadresse.husbokstav
                        }
                    );
                    person.INT_TemporaryZipCode__c = oa.vegadresse.postnummer;
                    person.INT_TemporaryMunicipalityNumber__c = oa.vegadresse.kommunenummer;
                    person.INT_TemporaryCoordinates__c = JSON.serialize(oa.vegadresse.koordinater);
                }else if(hasMatrikkeladresse(oa.matrikkeladresse)){
                    person.INT_TemporaryZipCode__c = oa.matrikkeladresse.postnummer;
                    person.INT_TemporaryMunicipalityNumber__c = oa.matrikkeladresse.kommunenummer;
                    person.INT_TemporaryCoordinates__c = JSON.serialize(oa.matrikkeladresse.koordinater);
                }else if(hasUtenlandskAdresse(oa.utenlandskAdresse)){
                    person.INT_TemporaryAddress__c = addressCreator(
                        new List<String>{
                            oa.utenlandskAdresse.adressenavnNummer,
                            oa.utenlandskAdresse.bygningEtasjeLeilighet,
                            oa.utenlandskAdresse.postboksNummerNavn,
                            oa.utenlandskAdresse.postkode,
                            oa.utenlandskAdresse.bysted,
                            oa.utenlandskAdresse.regionDistriktOmraade
                        }
                    ); // max 255 symbols might be an issue
                    person.INT_TemporaryCountryCode__c = oa.utenlandskAdresse.landkode.left(3);
                }
            }
        }
        
    }
    
    private static String getSikkerhetstiltakJSON(PDL_API_Response response){
        if(response.data?.hentPerson?.sikkerhetstiltak != null){
            return JSON.serialize(response.data.hentPerson.sikkerhetstiltak);
        }
        return  null;
    }
    private static void setUtflytting(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.utflyttingFraNorge != null){
            for(PDL_UtflyttingFraNorge utt : response.data.hentPerson.utflyttingFraNorge){
                if(utt.metadata?.historisk != true){
                    person.INT_MovedToCountry__c = getCountryIdFromIso(utt.tilflyttingsland);
                    person.INT_MovedToPlace__c = utt.tilflyttingsstedIUtlandet;
                    return;
                }
            }
        }    
        return;
    }
    private static void setInnflytting(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.innflyttingTilNorge != null){
            for(PDL_InnflyttingTilNorge inn : response.data.hentPerson.innflyttingTilNorge){
                if(inn.metadata?.historisk != true){
                    person.INT_MovedFromCountry__c = getCountryIdFromIso(inn.fraflyttingsland);
                    person.INT_MovedFromPlace__c = inn.fraflyttingsstedIUtlandet;
                    return;
                }
            }
        }    
        return;
    }

    private static String getAdressebeskyttelse(PDL_API_Response response){
        if(response.data?.hentPerson?.adressebeskyttelse != null){
            for(PDL_Adressebeskyttelse ab : response.data.hentPerson.adressebeskyttelse){
                if(ab.metadata?.historisk != true){
                    return ab.gradering?.name();
                }
            }
        }
        return null;
    }
    private static String getFolkeregisterpersonstatus(PDL_API_Response response){
        if(response.data?.hentPerson?.folkeregisterpersonstatus != null){
            for(PDL_Folkeregisterpersonstatus frstatus : response.data.hentPerson.folkeregisterpersonstatus){
                if(frstatus.metadata?.historisk != true){
                    return frstatus.status;
                }
            }
        }
        return null;
    }
    private static String getFoedselsdato(PDL_API_Response response){
        return response.data?.hentPerson?.foedsel[0]?.foedselsdato?.format();
    }
    private static void setNavn(Person__c person, PDL_API_Response response){
        if(response.data?.hentPerson?.navn != null){
            for(PDL_Navn navn : response.data.hentPerson.navn){
                if(navn.metadata?.historisk != true){
                    person.INT_FirstName__c = validateString(navn.fornavn);
                    person.INT_MiddleName__c = validateString(navn.mellomnavn);
                    person.INT_LastName__c = validateString(navn.etternavn);
                    return;
                }
            }
        }
        return;
    }

    private static String getForelderBarnRelasjonJSON(PDL_API_Response response){
        if(response.data?.hentPerson?.forelderBarnRelasjon != null && !response.data.hentPerson.forelderBarnRelasjon.isEmpty()){
            return JSON.serialize(response.data.hentPerson.forelderBarnRelasjon);
        }
        return null;
    }
    /**
     * Safely transform collection into string compatible with multipicklist-fields.
     * @param stringsToJoin Collection of strings to join
     * @return Null or strings joined with ';'
     */
    @TestVisible
    private static String safelyJoinMultiPicklistString(List<String> stringsToJoin) {
        if (stringsToJoin == null || stringsToJoin.size() == 0) {
            return null;
        } else {
            return String.join(stringsToJoin, ';');
        }
    }
    private static String validateString(String stringToCheck) {
        return String.isBlank(stringToCheck) ? null : stringToCheck.left(255);
    }

    private static String addressCreator(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (validateString(addressField) != null) {
                addressString += validateString(addressField) + ' ';
            }
        }
        addressString = addressString.removeEnd(' ');
        return String.isBlank(addressString) ? null : addressString;
    }
    /**
     * @param citizenships ISO countrycodes (list)
     *
     * @return country names joined with ';'
     */
    @TestVisible
    private static String crateCitizenshipString(List<String> citizenships) {
        String citizenshipReturnString = '';
        for (String citizenship : citizenships) {
            citizenshipReturnString = citizenshipReturnString + (getCountryNameFromIso(citizenship)) + ';';
        }

        return citizenshipReturnString.removeEnd(';');
    }
    /**
     * Takes ISO code value and gives country name in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static String getCountryNameFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country?.Name;
    }
    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static Id getCountryIdFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country?.Id;
    }
    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static Common_Code__c getCountryFromIso(String isoCode) {
        if (String.isBlank(isoCode)) {
            return null;
        }
        if (ISO_MAP.containsKey(isoCode)) {
            return ISO_MAP.get(isoCode);
        } else {
            //throw new isoCodeNotFoundException('No country was found for the ISO code \'' + isoCode + '\'.');
            return null;
        }
    }
    /**
     * Create map from ISO country codes to English Country Label
     * @param commonCodeList List Common_Code__c records
     * @return map from ISO code to country in English
     */
    @TestVisible
    private static Map<String, Common_Code__c> createIsoMap(List<Common_Code__c> commonCodeList) {
        Map<String, Common_Code__c> isoMap = new Map<String, Common_Code__c>();
        for (Common_Code__c ccl : commonCodeList) {
            isoMap.put(ccl.CRM_Code__c, ccl);
        }
        return isoMap;
    }
    public class IsoCodeNotFoundException extends Exception {
    }
    public static String Ansvarssubjekt(String ident){
        /*
        return '{"query": "query($ident: ID!){ hentPerson(ident: $ident)'
        +' {navn(historikk: false) {fornavn mellomnavn etternavn}}}",'
        +'"variables": {"ident":"' + ident + '"}}';
        */
        
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.foreldreansvar.ansvarssubjekt = true;

        return query.build();

        /* GQLVariable VarIdent = new GQLVariable('ident',new GQLVariableType('ID!'));
        Map<String,String> variables = new Map<String,String>{ VarIdent.getName() => ident};
        GQLQuery q = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(GQLOperationType_e.QUERY),
                '', //noname
                new GQLVariableDefinitions().addVariable(VarIdent),
                new GQLSelectionSet().addItem(
                    new GQLField(
                        'hentPerson',
                        new GQLArguments().addArgument(
                            new GQLArgument(
                                'ident',
                                new GQLValue(VarIdent)
                            )
                        ),
                        new GQLSelectionSet().addItem(
                            new GQLField('foreldreansvar',
                                new GQLArguments().addArgument(
                                    new GQLArgument(
                                        'historikk',
                                        new GQLValue(false)
                                    )
                                ),
                                new GQLSelectionSet().addItem(
                                    new GQLField('ansvarssubjekt')
                                )
                            )
                        )
                    )
                )
            ),
            variables
        );

        String s = q.build();
        System.debug(s);
        return s; */
    }

    public static String allFields(String ident){
        PDL_API_QueryHelper query = new PDL_API_QueryHelper(ident);
        query.hentPerson.selectAll(true);
        query.hentIdenter.selectAll();
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.AKTORID);
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.FOLKEREGISTERIDENT);
        query.addIdentGruppe(PDL_API_IdentGruppeQuery.NPID);

        return query.build();
    }

    public static String testJsonString = '{"data":{"hentPerson":{"adressebeskyttelse":[],"bostedsadresse":' +
                                '[{"angittFlyttedato":"1965-10-12","gyldigFraOgMed":"1965-10-12T00' +
                                ':00","gyldigTilOgMed":null,"coAdressenavn":null,"vegadresse":{"ma' +
                                'trikkelId":130534152,"husnummer":"1","husbokstav":null,"bruksenhe' +
                                'tsnummer":null,"adressenavn":"Plassavegen","kommunenummer":"1557",' +
                                '"bydelsnummer":null,"tilleggsnavn":null,"postnummer":"6636","koord' +
                                'inater":{"x":453529.0,"y":6974511.0,"z":0.0,"kvalitet":null}},"mat' +
                                'rikkeladresse":null,"utenlandskAdresse":null,"ukjentBosted":null,"' +
                                'folkeregistermetadata":{"ajourholdstidspunkt":"2021-09-02T10:17:35' +
                                '","gyldighetstidspunkt":"1965-10-12T00:00","opphoerstidspunkt":nul' +
                                'l,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opply' +
                                'sningsId":"53a9f29d-0980-42a3-8e18-13ae0b01b3d7","master":"FREG","' +
                                'endringer":[{"type":"OPPRETT","registrert":"2021-09-02T10:17:35","' +
                                'registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Doll' +
                                'y"}],"historisk":false}}],"deltBosted":[],"doedfoedtBarn":[],"doed' +
                                'sfall":[],"falskIdentitet":null,"foedsel":[{"foedselsaar":1965,"fo' +
                                'edselsdato":"1965-10-12","foedeland":"NOR","foedested":"Fødested i' +
                                '/på Gjemnes","foedekommune":null,"folkeregistermetadata":{"ajourho' +
                                'ldstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09' +
                                '-02T10:17:35","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":nu' +
                                'll,"sekvens":null},"metadata":{"opplysningsId":"20e8b676-568e-4eee' +
                                '-b5ce-b57156f850f5","master":"FREG","endringer":[{"type":"OPPRETT"' +
                                ',"registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregistere' +
                                't","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"fo' +
                                'lkeregisteridentifikator":[{"identifikasjonsnummer":"12106519356",' +
                                '"status":"I_BRUK","type":"FNR","folkeregistermetadata":{"ajourhold' +
                                'stidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09-0' +
                                '2T10:17:35","opphoerstidspunkt":null,"kilde":"srvdolly","aarsak":n' +
                                'ull,"sekvens":null},"metadata":{"opplysningsId":"33be3e25-ccd5-4f9' +
                                '7-8f21-bbac3c444877","master":"FREG","endringer":[{"type":"OPPRETT"' +
                                ',"registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret' +
                                '","systemkilde":"FREG","kilde":"srvdolly"}],"historisk":false}}],"f' +
                                'olkeregisterpersonstatus":[{"status":"bosatt","forenkletStatus":"bo' +
                                'sattEtterFolkeregisterloven","folkeregistermetadata":{"ajourholdsti' +
                                'dspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09-02T10' +
                                ':17:35","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sek' +
                                'vens":null},"metadata":{"opplysningsId":"affd81b7-665c-4e82-88fb-a3' +
                                '6181b6cb65","master":"FREG","endringer":[{"type":"OPPRETT","registr' +
                                'ert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret","systemk' +
                                'ilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"forelderBarnRel' +
                                'asjon":[{"relatertPersonsIdent":"02091379875","relatertPersonsRolle"' +
                                ':"BARN","minRolleForPerson":"FAR","folkeregistermetadata":{"ajourhol' +
                                'dstidspunkt":"2021-09-02T10:17:36","gyldighetstidspunkt":"2021-09-02' +
                                'T10:17:36","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"s' +
                                'ekvens":null},"metadata":{"opplysningsId":"8c713184-ebe2-4dbe-8c6e-c' +
                                'ff4760273d6","master":"FREG","endringer":[{"type":"OPPRETT","registr' +
                                'ert":"2021-09-02T10:17:36","registrertAv":"Folkeregisteret","systemk' +
                                'ilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"foreldreansvar"' +
                                ':[{"ansvar":"far","ansvarlig":null,"ansvarssubjekt":"02091379875","a' +
                                'nsvarligUtenIdentifikator":null,"folkeregistermetadata":{"ajourholds' +
                                'tidspunkt":"2021-09-02T10:17:37","gyldighetstidspunkt":"2021-09-02T10' +
                                ':17:37","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekv' +
                                'ens":null},"metadata":{"opplysningsId":"4b47f1b0-9316-49bf-820b-3c5b' +
                                '0080b895","master":"FREG","endringer":[{"type":"OPPRETT","registrert' +
                                '":"2021-09-02T10:17:37","registrertAv":"Folkeregisteret","systemkild' +
                                'e":"FREG","kilde":"Dolly"}],"historisk":false}}],"fullmakt":[],"iden' +
                                'titetsgrunnlag":[],"kjoenn":[{"kjoenn":"MANN","folkeregistermetadata' +
                                '":{"ajourholdstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt"' +
                                ':"2021-09-02T10:17:35","opphoerstidspunkt":null,"kilde":"Dolly","aar' +
                                'sak":null,"sekvens":null},"metadata":{"opplysningsId":"6be1bb25-2731' +
                                '-489b-ac15-49a93730ea8e","master":"FREG","endringer":[{"type":"OPPRE' +
                                'TT","registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregister' +
                                'et","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"kon' +
                                'taktadresse":[],"kontaktinformasjonForDoedsbo":[],"navn":[{"fornavn"' +
                                ':"VAKKER","mellomnavn":"SLØVENDE","etternavn":"SNERK","forkortetNavn' +
                                '":"SNERK VAKKER SLØVENDE","originaltNavn":null,"gyldigFraOgMed":"202' +
                                '1-09-02","folkeregistermetadata":{"ajourholdstidspunkt":"2021-09-02T' +
                                '10:17:35","gyldighetstidspunkt":"2021-09-02T10:17:35","opphoerstidsp' +
                                'unkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":' +
                                '{"opplysningsId":"c38343b4-2781-4bff-aa26-dc78bc46ee4d","master":"FR' +
                                'EG","endringer":[{"type":"OPPRETT","registrert":"2021-09-02T10:17:35' +
                                '","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dol' +
                                'ly"}],"historisk":false}}],"opphold":[],"oppholdsadresse":[],"sikker' +
                                'hetstiltak":[],"sivilstand":[{"type":"UGIFT","gyldigFraOgMed":null,"' +
                                'relatertVedSivilstand":null,"bekreftelsesdato":null,"folkeregisterme' +
                                'tadata":{"ajourholdstidspunkt":"2021-09-02T10:17:36","gyldighetstids' +
                                'punkt":"2021-09-02T10:17:36","opphoerstidspunkt":null,"kilde":"Dolly' +
                                '","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"6978919' +
                                '5-317e-42f7-8c28-c2cdda73901f","master":"FREG","endringer":[{"type":' +
                                '"OPPRETT","registrert":"2021-09-02T10:17:36","registrertAv":"Folkere' +
                                'gisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}' +
                                '],"statsborgerskap":[{"land":"NOR","bekreftelsesdato":null,"gyldigFr' +
                                'aOgMed":"1965-10-12","gyldigTilOgMed":null,"folkeregistermetadata":{' +
                                '"ajourholdstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"1' +
                                '965-10-12T00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":n' +
                                'ull,"sekvens":null},"metadata":{"opplysningsId":"dd35688f-febd-4626-' +
                                'a9b4-39ed732ad69a","master":"FREG","endringer":[{"type":"OPPRETT","r' +
                                'egistrert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret","s' +
                                'ystemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"telefonnu' +
                                'mmer":[],"tilrettelagtKommunikasjon":[],"utenlandskIdentifikasjonsnu' +
                                'mmer":[],"vergemaalEllerFremtidsfullmakt":[]}' +
                                ',"hentIdenter":{"identer":[{"ident":"12106519356","historisk":false,"' +
                                'gruppe":"FOLKEREGISTERIDENT"},{"ident":"2762473496911","historisk":f' +
                                'alse,"gruppe":"AKTORID"}]}' +
                                '}}';
}
