/**
 * Created by ohuuse on 22/10/2020.
 */

public without sharing class KafkaPDLHandler_2 implements IKafkaMessageConsumer {

    private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';
    private static final Map<String, Integer> ADR_BESKYTTELSES_GRADERING = New Map<String, Integer>{'STRENGT_FORTROLIG'=>4, 'STRENGT_FORTROLIG_UTLAND'=>3, 'FORTROLIG'=>2, 'UGRADERT'=>1};
    // assumption: we want the Norwegian written form and we use alfa-3-koder
//    private static final Map<String, String> alfa3KodeMap = New Map<String, String>{ 'ABW'=>'Aruba', 'AFG'=>'Afghanistan', 'AGO'=>'Angola', 'AIA'=>'Anguilla', 'ALA'=>'Åland', 'ALB'=>'Albania', 'AND'=>'Andorra', 'ARE'=>'De forente arabiske emirater', 'ARG'=>'Argentina', 'ARM'=>'Armenia', 'ASM'=>'Amerikansk Samoa', 'ATA'=>'Antarktis', 'ATF'=>'De franske sørterritorier', 'ATG'=>'Antigua og Barbuda', 'AUS'=>'Australia', 'AUT'=>'Østerrike', 'AZE'=>'Aserbajdsjan', 'BDI'=>'Burundi', 'BEL'=>'Belgia', 'BEN'=>'Benin', 'BES'=>'Bonaire, Sint Eustatius og Saba', 'BFA'=>'Burkina Faso', 'BGD'=>'Bangladesh', 'BGR'=>'Bulgaria', 'BHR'=>'Bahrain', 'BHS'=>'Bahamas', 'BIH'=>'Bosnia-Hercegovina', 'BLM'=>'Saint-Barthélemy', 'BLR'=>'Hviterussland', 'BLZ'=>'Belize', 'BMU'=>'Bermuda', 'BOL'=>'Bolivia', 'BRA'=>'Brasil', 'BRB'=>'Barbados', 'BRN'=>'Brunei', 'BTN'=>'Bhutan', 'BVT'=>'Bouvetøya', 'BWA'=>'Botswana', 'CAF'=>'Den sentralafrikanske republikk', 'CAN'=>'Canada', 'CCK'=>'Kokosøyene', 'CHE'=>'Sveits', 'CHL'=>'Chile', 'CHN'=>'Kina', 'CIV'=>'Elfenbenskysten', 'CMR'=>'Kamerun', 'COD'=>'Den demokratiske republikken Kongo', 'COG'=>'Republikken Kongo', 'COK'=>'Cookøyene', 'COL'=>'Colombia', 'COM'=>'Komorene', 'CPV'=>'Kapp Verde', 'CRI'=>'Costa Rica', 'CUB'=>'Cuba', 'CUW'=>'Curaçao', 'CXR'=>'Christmasøya', 'CYM'=>'Caymanøyene', 'CYP'=>'Kypros', 'CZE'=>'Tsjekkia', 'DEU'=>'Tyskland', 'DJI'=>'Djibouti', 'DMA'=>'Dominica', 'DNK'=>'Danmark', 'DOM'=>'Den dominikanske republikk', 'DZA'=>'Algerie', 'ECU'=>'Ecuador', 'EGY'=>'Egypt', 'ERI'=>'Eritrea', 'ESH'=>'Vest-Sahara', 'ESP'=>'Spania', 'EST'=>'Estland', 'ETH'=>'Etiopia', 'FIN'=>'Finland', 'FJI'=>'Fiji', 'FLK'=>'Falklandsøyene', 'FRA'=>'Frankrike', 'FRO'=>'Færøyene', 'FSM'=>'Mikronesiaføderasjonen', 'GAB'=>'Gabon', 'GBR'=>'Storbritannia', 'GEO'=>'Georgia', 'GHA'=>'Ghana', 'GIB'=>'Gibraltar', 'GIN'=>'Guinea', 'GLP'=>'Guadeloupe', 'GMB'=>'Gambia', 'GNB'=>'Guinea-Bissau', 'GNQ'=>'Ekvatorial-Guinea', 'GRC'=>'Hellas', 'GRD'=>'Grenada', 'GRL'=>'Grønland', 'GTM'=>'Guatemala', 'GUF'=>'Fransk Guyana', 'GUM'=>'Guam', 'GUY'=>'Guyana', 'HKG'=>'Hongkong', 'HMD'=>'Heard- og McDonaldøyene', 'HND'=>'Honduras', 'HRV'=>'Kroatia', 'HTI'=>'Haiti', 'HUN'=>'Ungarn', 'IDN'=>'Indonesia', 'IMN'=>'Man', 'IND'=>'India', 'IOT'=>'Det britiske territoriet i Indiahavet', 'IRL'=>'Irland', 'IRN'=>'Iran', 'IRQ'=>'Irak', 'ISL'=>'Island', 'ISR'=>'Israel', 'ITA'=>'Italia', 'JAM'=>'Jamaica', 'JEY'=>'Jersey', 'JPN'=>'Japan', 'JOR'=>'Jordan', 'KAZ'=>'Kasakhstan', 'KEN'=>'Kenya', 'KGZ'=>'Kirgisistan', 'KHM'=>'Kambodsja', 'KIR'=>'Kiribati', 'KNA'=>'Saint Kitts og Nevis', 'KOR'=>'Sør-Korea', 'KWT'=>'Kuwait', 'LAO'=>'Laos', 'LBN'=>'Libanon', 'LBR'=>'Liberia', 'LBY'=>'Libya', 'LCA'=>'Saint Lucia', 'LIE'=>'Liechtenstein', 'LKA'=>'Sri Lanka', 'LSO'=>'Lesotho', 'LTU'=>'Litauen', 'LUX'=>'Luxembourg', 'LVA'=>'Latvia', 'MAC'=>'Macao', 'MAF'=>'Saint-Martin', 'MAR'=>'Marokko', 'MCO'=>'Monaco', 'MDA'=>'Moldova', 'MDG'=>'Madagaskar', 'MDV'=>'Maldivene', 'MEX'=>'Mexico', 'MHL'=>'Marshalløyene', 'MKD'=>'Nord-Makedonia', 'MLI'=>'Mali', 'MLT'=>'Malta', 'MMR'=>'Myanmar', 'MNE'=>'Montenegro', 'MNG'=>'Mongolia', 'MNP'=>'Nord-Marianene', 'MOZ'=>'Mosambik', 'MRT'=>'Mauritania', 'MSR'=>'Montserrat', 'MTQ'=>'Martinique', 'MUS'=>'Mauritius', 'MWI'=>'Malawi', 'MYS'=>'Malaysia', 'MYT'=>'Mayotte', 'NAM'=>'Namibia', 'NCL'=>'Ny-Caledonia', 'NER'=>'Niger', 'NFK'=>'Norfolkøya', 'NGA'=>'Nigeria', 'NIC'=>'Nicaragua', 'NIU'=>'Niue', 'NLD'=>'Nederland', 'NOR'=>'Norge', 'NPL'=>'Nepal', 'NRU'=>'Nauru', 'NZL'=>'Ny-Zealand', 'OMN'=>'Oman', 'PAK'=>'Pakistan', 'PAN'=>'Panama', 'PCN'=>'Pitcairnøyene', 'PER'=>'Peru', 'PHL'=>'Filippinene', 'PLW'=>'Palau', 'PNG'=>'Papua Ny-Guinea', 'POL'=>'Polen', 'PRI'=>'Puerto Rico', 'PRK'=>'Nord-Korea', 'PRT'=>'Portugal', 'PRY'=>'Paraguay', 'PSE'=>'De palestinske territoriene', 'PYF'=>'Fransk Polynesia', 'QAT'=>'Qatar', 'REU'=>'Réunion', 'ROU'=>'Romania', 'RUS'=>'Russland', 'RWA'=>'Rwanda', 'SAU'=>'Saudi-Arabia', 'SDN'=>'Sudan', 'SEN'=>'Senegal', 'SGP'=>'Singapore', 'SGS'=>'Sør-Georgia og Sør-Sandwichøyene', 'SHN'=>'St. Helena, Ascension og Tristan da Cunha', 'SJM'=>'Svalbard og Jan Mayen', 'SLB'=>'Salomonøyene', 'SLE'=>'Sierra Leone', 'SLV'=>'El Salvador', 'SMR'=>'San Marino', 'SOM'=>'Somalia', 'SPM'=>'Saint-Pierre og Miquelon', 'SRB'=>'Serbia', 'SSD'=>'Sør-Sudan', 'STP'=>'São Tomé og Príncipe', 'SUR'=>'Surinam', 'SVK'=>'Slovakia', 'SVN'=>'Slovenia', 'SWE'=>'Sverige', 'SWZ'=>'Swaziland', 'SXM'=>'Sint Maarten', 'SYC'=>'Seychellene', 'SYR'=>'Syria', 'TCA'=>'Turks- og Caicosøyene', 'TCD'=>'Tsjad', 'TGO'=>'Togo', 'THA'=>'Thailand', 'TJK'=>'Tadsjikistan', 'TKL'=>'Tokelau', 'TKM'=>'Turkmenistan', 'TLS'=>'Øst-Timor', 'TON'=>'Tonga', 'TTO'=>'Trinidad og Tobago', 'TUN'=>'Tunisia', 'TUR'=>'Tyrkia', 'TUV'=>'Tuvalu', 'TWN'=>'Taiwan', 'TZA'=>'Tanzania', 'UGA'=>'Uganda', 'UKR'=>'Ukraina', 'UMI'=>'USAs ytre småøyer', 'URY'=>'Uruguay', 'USA'=>'USA', 'UZB'=>'Usbekistan', 'VAT'=>'Vatikanstaten', 'VCT'=>'Saint Vincent og Grenadinene', 'VEN'=>'Venezuela', 'VGB'=>'De britiske Jomfruøyer', 'VIR'=>'De amerikanske Jomfruøyer', 'VNM'=>'Vietnam', 'VUT'=>'Vanuatu', 'WLF'=>'Wallis- og Futunaøyene', 'WSM'=>'Samoa', 'YEM'=>'Jemen', 'ZAF'=>'Sør-Afrika', 'ZMB'=>'Zambia', 'ZWE'=>'Zimbabwe' };
    private static final List<CountryISOCodeMapping__mdt> isoCodeMappingList = new List<CountryISOCodeMapping__mdt>([SELECT Id, ISO2__c, ISO3__c, Country__c FROM CountryISOCodeMapping__mdt]);
    private final Map<String, String> iso2Map = createIsoMap(isoCodeMappingList, '2');
    private final Map<String, String> iso3Map = createIsoMap(isoCodeMappingList, '3');

    private static final Map<String, String> sexMap = New Map<String, String>{'MANN'=>'Male', 'KVINNE'=>'Female', 'UKJENT'=>'Unknown'};

    public void processMessages(List<KafkaMessage__c> messages) {
        List<Person__c> personsToUpsert = new List<Person__c>();
        // Errors are caught and saved on each KafkaMessage record
        for (KafkaMessage__c msg : getUniqueMessagesByKey(messages)) {
            try {
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                personsToUpsert.add(createPersonRecords(msg));
            } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }

        // Errors from DML will be caught by calling context and saved on the related AsyncRequest record
        upsert personsToUpsert INT_ActorId__c;
    }

    /** Deduplicate messages by returning a single Kafka Message for each unique CRM_Key__c value.
     * If multiple records are detected, the newest Kafka Message is kept
     * @param messages Set of Kafka Messages in scope
     * @return Deduplicated set of Kafka Message
     */
    private static List<KafkaMessage__c> getUniqueMessagesByKey(List<KafkaMessage__c> messages) {
        Map<String, KafkaMessage__c> deduplicatedMessagesByKey = new Map<String, KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            if(!deduplicatedMessagesByKey.containsKey(msg.CRM_Key__c)) {
                deduplicatedMessagesByKey.put(msg.CRM_Key__c, msg);
                continue;
            }

            if(deduplicatedMessagesByKey.get(msg.CRM_Key__c).CreatedDate < msg.CreatedDate) {
                deduplicatedMessagesByKey.get(msg.CRM_Key__c).CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                deduplicatedMessagesByKey.put(msg.CRM_Key__c, msg);
            }
        }
        System.debug(deduplicatedMessagesByKey.values());
        return(deduplicatedMessagesByKey.values());
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for each KafkaMessage
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    private Person__c createPersonRecords(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPerson_2 kafkaPerson = KafkaPerson_2.parse(decodedValue);
        validateValues(kafkaPerson);
        validateListSizes(kafkaPerson);
        Person__c person = new Person__c();
        person = mapFieldValues(person, kafkaPerson);
        // TODO: here we also need to return security measure list I think
        return person;
    }

    /**
     * Transform and map fields from PDL data structure to Person__c SObject
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a person from PDL
     * @return Person Account with initialized fields
     */
    private Person__c mapFieldValues(Person__c person, KafkaPerson_2 kafkaPerson) {

        person.INT_ActorId__c = kafkaPerson.aktoerId;
        person.Name = kafkaPerson.folkeregisterId;
        // Navn
        if (kafkaPerson.Navn.size()>0) {
            person.INT_FirstName__c = stringValidator(kafkaPerson.Navn[0].fornavn);
            person.INT_MiddleName__c = stringValidator(kafkaPerson.Navn[0].mellomnavn);
            person.INT_LastName__c = stringValidator(kafkaPerson.Navn[0].etternavn);
        }
        // familierelasjoner

        // folkeregisterpersonstatus
        // person.INT_LegalStatus__c = safelyJoinMultiPicklistString(kafkaPerson.folkeregisterpersonstatus);    Not mapping to this field yet (NKS 23.09)

        // InnflytningTilNorge
        if (kafkaPerson.innflyttingTilNorge.size()>0) {
            person.INT_MovedFromCountry__c = getCountryFromIso(kafkaPerson.innflyttingTilNorge[0].fraflyttingsland);
            person.INT_MovedFromPlace__c = stringValidator(kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet);
        }

        // adressebeskyttelse
        person.INT_Confidential__c = clearanceLevel(kafkaPerson.adressebeskyttelse);

        // sikkerhetstiltak
        person.INT_SecurityMeasures__c = '{"sikkerhetstiltak":'+JSON.serialize(kafkaPerson.sikkerhetstiltak)+'}';
//         TODO: find out how to set sm.INT_Person__c on these records. need to insert Person__c first
//        List<SecurityMeasure__c> securityMeasures = new List<SecurityMeasure__c>();
//        for (KafkaPerson_2.Sikkerhetstiltak ks : kafkaPerson.sikkerhetstiltak) {
//            SecurityMeasure__c sm = new SecurityMeasure__c();
//             sm.INT_Person__c = this person.Id
//            sm.INT_ValidFromDate__c = Date.valueOf(ks.gyldigFraOgMed);
//            sm.INT_ValidToDate__c = Date.valueOf(ks.gyldigTilOgMed);
//            sm.INT_NAVContactId__c = stringValidator(ks.kontaktPersonId);
//             TODO: find out how we can test this (not allowed to set INT_NAVUnit__c (Invalid id)
//            sm.INT_NAVUnit__c = stringValidator(ks.kontaktPersonEnhet);
//            securityMeasures.add(sm);
//        }

        // bostedsadresser
        // assumption: vegadresse has first pri, then ukjentbosted
        if (kafkaPerson.bostedsadresse.vegadresse.size()>0) {
            person.INT_ResidentialAddress__c = kafkaPerson.bostedsadresse.vegadresse[0].adressenavn + ' ' + kafkaPerson.bostedsadresse.vegadresse[0].husnummer + ' ' + kafkaPerson.bostedsadresse.vegadresse[0].husbokstav;
            person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.vegadresse[0].postnummer;
            // TODO: is this a decision we should take. -- use coordinate data format with decimals. INT_Coordinates
//            person.INT_Coordinates__Latitude__s = Double.valueOf(getSubString(kafkaPerson.bostedsadresse.vegadresse[0].koordinater, 0));
//            person.INT_Coordinates__Longitude__s = Double.valueOf(getSubString(kafkaPerson.bostedsadresse.vegadresse[0].koordinater, 1));
        } else if (kafkaPerson.bostedsadresse.ukjentBosted.size()>0) {
            person.INT_MunicipalityNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune : '';
        }

        // oppholdsadresser
        // assumption: vegadresse has first pri, then utlandsAdresse, then ukjentbosted
        if (kafkaPerson.oppholdsadresse.vegadresse.size()>0) {
            person.INT_TemporaryAddress__c = kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn + ' ' + kafkaPerson.oppholdsadresse.vegadresse[0].husnummer + ' ' + kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav;
            person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresse.vegadresse[0].postnummer;
            person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer;
        } else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size()>0) {
            person.INT_TemporaryAddress__c = kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer
                    + ' ' + kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet
                    + ' ' + kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn
                    + ' ' + kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode
                    + ' ' + kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted
                    + ' ' + kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade;                                      // max 255 symbols might be an issue
            person.INT_TemporaryCountryCode__c = kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode;
        } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size()>0) {
            person.INT_TemporaryMunicipalityNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune : '';
        }

        // statsborgerskap
        person.INT_Citizenships__c = safelyJoinMultiPicklistString(kafkaPerson.statsborgerskap);                                // format: NOR;SVE. is this ok?

        // sivilstand
        if (kafkaPerson.sivilstand.size()>0) {
            person.INT_MaritalStatus__c = kafkaPerson.sivilstand[0].type;
            person.INT_MaritalStatusDate__c = dateCreator(kafkaPerson.sivilstand[0].gyldigFraOgMed);
//        person.INT_External_Reference__c = kafkaPerson.sivilstand[0].relatertVedSivilstand;                               // field not in sf INT_External_Reference__c. This field will probably be on the relation "object" (might be a json in rich text field)
        }

        if (kafkaPerson.kommunenummerFraGt != PDL_ERROR_STRING) {
            person.INT_MunicipalityNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.kommunenummerFraGt.left(4) : '';
        } else if (kafkaPerson.kommunenummerFraAdresse != PDL_ERROR_STRING) {
            person.INT_MunicipalityNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.kommunenummerFraAdresse.left(4) : '';
        }
        if (kafkaPerson.bydelsnummerFraGt != PDL_ERROR_STRING) {
            person.INT_RegionNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.bydelsnummerFraGt.left(2) : '';
        } else if (kafkaPerson.bydelsnummerFraAdresse != PDL_ERROR_STRING) {
            person.INT_RegionNumber__c = person.INT_Confidential__c == 'FORTROLIG' || person.INT_Confidential__c == 'UGRADERT' ? kafkaPerson.bydelsnummerFraAdresse.left(2) : '';
        }
        // kjoenn
        if (kafkaPerson.kjoenn.size()>0) {
            person.INT_Sex__c = sexTranslator(kafkaPerson.kjoenn[0]);
        }
        // doedsfall
        if (kafkaPerson.doedsfall.size()>0) {
            person.INT_DateOfDeath__c = kafkaPerson.doedsfall[0].doedsdato == '0' ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato);
            person.INT_IsDeceased__c = kafkaPerson.doedsfall[0].doedsdato != null ? true : false;
        }

        // telefonnummer
        for (KafkaPerson_2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            person.INT_Phone1__c = tlf.prioritet == '1' ?  tlf.landskode + tlf.nummer : '';
            person.INT_Phone2__c = tlf.prioritet == '2' ?  tlf.landskode + tlf.nummer : '';
        }

        // utflyttingFraNorge
        if (kafkaPerson.utflyttingFraNorge.size()>0) {
            person.INT_MovedToCountry__c = getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland);
            person.INT_MovedToPlace__c = stringValidator(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet);
        }

        // talesspraaktolk
        person.INT_SpokenLanguageIntepreter__c = safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk);

        // Ensure that a System User is set as Owner if even if message processing is manually retried by an administrator user
        if (KafkaIntegrationCustomSetting.integrationUserId != null) {
            person.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
        }
        return person;
    }

    /**
     * Safely transform collection into string compatible with multipicklist-fields.
     * @param stringsToJoin Collection of strings to join
     * @return Null or strings joined with ';'
     */
    @TestVisible private static String safelyJoinMultiPicklistString(List<String> stringsToJoin) {
        if (stringsToJoin == null || stringsToJoin.size() == 0) {
            return null;
        } else {
            return String.join(stringsToJoin, ';');
        }
    }

    /**
     * Check that field size limitations of 255 signs is followed and allow empty string
     * @param stringToCheck String to check
     * @return Empty String checked string with maximum 255 symbols
     */
    private String stringValidator(String stringToCheck) {
        return String.isBlank(stringToCheck) ? '' : stringToCheck.left(255);
    }


    /**
     * Check that date has a value (not null or '')
     * @param dateToCheck Date to check
     * @return Date
     */
    private Date dateCreator(String dateToCheck) {
        return !String.isBlank(dateToCheck) ? Date.valueOf(dateToCheck) : null;
    }

    /**
     * @param longString            the string to split
     * @param stringPosition    what substring to return
     *
     * @return a part of the original string divided in parts by ','
     */
    private String getSubString(String longString, Integer stringPosition) {

        return longString.split(',')[stringPosition];

    }

    /**
     * Check that date has a value (not null or '')
     * @param sexToCheck Date to check
     * @return Date
     */
    private String sexTranslator(String sexToCheck) {
        return sexMap.containsKey(sexToCheck) ? sexMap.get(sexToCheck) : sexMap.get('UKJENT');
    }

    /**
     * Validate field values and if errors are found, throw error to store on the relevant Kafka Message
     * @param kafkaPerson Kafka person to validate
     */
    private void validateValues(KafkaPerson_2 kafkaPerson) {
        List<String> fieldValuesToCheck = new List<String>
        {
                kafkaPerson.bydelsnummerFraAdresse
                , kafkaPerson.bostedsadresse.vegadresse.size()>0 ? kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer : ''
                , kafkaPerson.bostedsadresse.matrikkeladresse.size()>0 ? kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer : ''
                , kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer
                , kafkaPerson.oppholdsadresse.matrikkeladresse.size()>0 ? kafkaPerson.oppholdsadresse.matrikkeladresse[0].kommunenummer : ''
        };
        if (containsPDLErrorString(fieldValuesToCheck)) {
            throw new InvalidPDLValueException('"' + PDL_ERROR_STRING + '" found in payload');
        }
    }

    /**
     * Check if the PDL placeholder error string is found in any relevant field.
     * @param values
     * @return Indication of whether the PDL Error String is found in any field
     */
    private Boolean containsPDLErrorString(List<String> values) {
        for (String s : values) {
            if (s.contains(PDL_ERROR_STRING)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Find the adressebeskyttelse with the strictest security criteria
     * @param values
     * @return The list value with the strictest security criteria
     */
    private String clearanceLevel(List<String> values) {
        Integer grade = 0;
        String returnGrade = '';
        for (String s : values) {
            if (ADR_BESKYTTELSES_GRADERING.containsKey(s) && ADR_BESKYTTELSES_GRADERING.get(s) > grade) {
                grade = ADR_BESKYTTELSES_GRADERING.get(s);
                returnGrade = s;
            }
        }
        return returnGrade;
    }


    /**
     * Validate list sizes and if errors are found, throw error to store on the relevant Kafka Message
     * @param kafkaPerson Kafka person to validate
     */
    private void validateListSizes(KafkaPerson_2 kafkaPerson) {
        if (kafkaPerson.navn.size()>1
                || kafkaPerson.innflyttingTilNorge.size()>1
                || kafkaPerson.bostedsadresse.vegadresse.size()>1
                || kafkaPerson.bostedsadresse.matrikkeladresse.size()>1
                || kafkaPerson.bostedsadresse.utenlandskAdresse.size()>1
                || kafkaPerson.bostedsadresse.ukjentBosted.size()>1
                || kafkaPerson.sivilstand.size()>1
                || kafkaPerson.doedsfall.size()>1
                || kafkaPerson.telefonnummer.size()>1
                || kafkaPerson.utflyttingFraNorge.size()>1
                ) {
            // TODO: what shoul be returned here? a different error string? e.g. "PDL object containing too many objects"
            throw new InvalidPDLValueException('"' + PDL_ERROR_STRING + '" found in payload');
        }
    }

    /**
     * Create map from ISO country codes to English Country Label
     * @param isoList List of all CountryISOCodeMapping__mdt records
     * @param iso what ISO to create map for. allowed values: '1' and '2'
     * @return map from ISO code to country in English
     */
    private Map<String, String> createIsoMap(List<CountryISOCodeMapping__mdt> isoList, String iso) {
        Map<String, String> isoMap = new Map<String, String>();
        if (iso == '2') {
            for (CountryISOCodeMapping__mdt c : isoList) {
                isoMap.put(c.ISO2__c, c.Country__c);
            }
        } else if (iso == '3') {
            for (CountryISOCodeMapping__mdt c : isoList) {
                isoMap.put(c.ISO3__c, c.Country__c);
            }
        }
        return isoMap;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    private String getCountryFromIso(String isoCode) {
        if (isoCode.length() == 2) {
            return iso2Map.get(isoCode);
        }
        else if (isoCode.length() == 3) {
            return iso3Map.get(isoCode);
        }
        return '';
    }


    public class InvalidPDLValueException extends Exception {
    }
}