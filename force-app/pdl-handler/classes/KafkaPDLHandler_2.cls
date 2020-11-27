public without sharing class KafkaPDLHandler_2 implements IKafkaMessageConsumer {

    @TestVisible private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';
    @TestVisible private static final Map<String, Integer> ADR_BESKYTTELSES_GRADERING = New Map<String, Integer>{
            'STRENGT_FORTROLIG' => 4, 'STRENGT_FORTROLIG_UTLAND' => 3, 'FORTROLIG' => 2, 'UGRADERT' => 1
    };
    private static final Map<String, String> isoMap = createIsoMap([SELECT Name, CRM_Code__c FROM Common_Code__c WHERE CRM_Active__c = TRUE AND CRM_Code_Set__c IN ('Landkoder', 'LandkoderISO2')]);

    private static final Map<String, String> genderMap = New Map<String, String>{
            'MANN' => 'Male', 'KVINNE' => 'Female', 'UKJENT' => 'Unknown'
    };

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

    /**
     * Deduplicate messages by returning a single Kafka Message for each unique CRM_Key__c value.
     * If multiple records are detected, the newest Kafka Message is kept
     * @param messages Set of Kafka Messages in scope
     * @return Deduplicated set of Kafka Message
     */
    private static List<KafkaMessage__c> getUniqueMessagesByKey(List<KafkaMessage__c> messages) {
        Map<String, KafkaMessage__c> deduplicatedMessagesByKey = new Map<String, KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            if (!deduplicatedMessagesByKey.containsKey(msg.CRM_Key__c)) {
                deduplicatedMessagesByKey.put(msg.CRM_Key__c, msg);
                continue;
            }

            if (deduplicatedMessagesByKey.get(msg.CRM_Key__c).CreatedDate < msg.CreatedDate) {
                deduplicatedMessagesByKey.get(msg.CRM_Key__c).CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                deduplicatedMessagesByKey.put(msg.CRM_Key__c, msg);
            }
        }
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
        validateListSizes(kafkaPerson);
        Person__c person = new Person__c();
        emptyPersonFieldValues(person);
        person = mapFieldValues(person, kafkaPerson);
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
        if (kafkaPerson.folkeregisterId.size() > 0) {
            person.Name = kafkaPerson.folkeregisterId[0];
        }
        // Navn
        if (kafkaPerson.Navn.size() > 0) {
            person.INT_FirstName__c = stringValidator(kafkaPerson.Navn[0].fornavn);
            person.INT_MiddleName__c = stringValidator(kafkaPerson.Navn[0].mellomnavn);
            person.INT_LastName__c = stringValidator(kafkaPerson.Navn[0].etternavn);
        }
        // familierelasjoner
        person.INT_FamilyRelations__c = JSON.serialize(kafkaPerson.familierelasjoner);

        // folkeregisterpersonstatus
        // person.INT_LegalStatus__c = safelyJoinMultiPicklistString(kafkaPerson.folkeregisterpersonstatus);    Not mapping to this field yet (NKS 23.09)

        // InnflytningTilNorge
        if (kafkaPerson.innflyttingTilNorge.size() > 0) {
            person.INT_MovedFromCountry__c = getCountryFromIso(kafkaPerson.innflyttingTilNorge[0].fraflyttingsland);
            person.INT_MovedFromPlace__c = stringValidator(kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet);
        }

        // adressebeskyttelse
        person.INT_Confidential__c = clearanceLevel(kafkaPerson.adressebeskyttelse);

        // sikkerhetstiltak
        person.INT_SecurityMeasures__c = JSON.serialize(kafkaPerson.sikkerhetstiltak);

        if (ADR_BESKYTTELSES_GRADERING.get(person.INT_Confidential__c) <= 2) {
            // bostedsadresser
            // assumption: vegadresse has first pri, then ukjentbosted
            if (kafkaPerson.bostedsadresse.vegadresse.size() > 0) {
                person.INT_ResidentialAddress__c = addressCreator(new List<String>{
                        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn, kafkaPerson.bostedsadresse.vegadresse[0].husnummer, kafkaPerson.bostedsadresse.vegadresse[0].husbokstav
                });
                person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.vegadresse[0].postnummer;
                person.INT_Coordinates__c = kafkaPerson.bostedsadresse.vegadresse[0].koordinater;
            } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 0) {
                person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer;
                person.INT_Coordinates__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].koordinater;
            }

            // oppholdsadresser
            // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
            if (kafkaPerson.oppholdsadresse.vegadresse.size() > 0) {
                person.INT_TemporaryAddress__c = addressCreator(new List<String>{
                        kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn, kafkaPerson.oppholdsadresse.vegadresse[0].husnummer, kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav
                });
                person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresse.vegadresse[0].postnummer;
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer;
                person.INT_TemporaryCoordinates__c = kafkaPerson.oppholdsadresse.vegadresse[0].koordinater;
            } else if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 0) {
                person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].postnummer;
                person.INT_TemporaryCoordinates__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater;
            } else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 0) {
                person.INT_TemporaryAddress__c = addressCreator(new List<String>{
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade
                });                                      // max 255 symbols might be an issue
                person.INT_TemporaryCountryCode__c = kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode.left(3);
            } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 0) {
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.bostedsadresse.ukjentBosted[0].bostedskommune;
            }


            if (kafkaPerson.kommunenummerFraGt != PDL_ERROR_STRING) {
                person.INT_MunicipalityNumber__c = kafkaPerson.kommunenummerFraGt;
                person.INT_RegionNumber__c = kafkaPerson.kommunenummerFraGt.left(2);
            } else if (kafkaPerson.kommunenummerFraAdresse != PDL_ERROR_STRING) {
                person.INT_MunicipalityNumber__c = kafkaPerson.kommunenummerFraAdresse;
                person.INT_RegionNumber__c = kafkaPerson.kommunenummerFraAdresse.left(2);
            }
            if (kafkaPerson.bydelsnummerFraGt != PDL_ERROR_STRING) {
                person.INT_RegionNumber__c = kafkaPerson.bydelsnummerFraGt.left(2);
            } else if (kafkaPerson.bydelsnummerFraAdresse != PDL_ERROR_STRING) {
                person.INT_RegionNumber__c = kafkaPerson.bydelsnummerFraAdresse.left(2);
            }

        }

        // statsborgerskap
        person.INT_Citizenships__c = safelyJoinMultiPicklistString(kafkaPerson.statsborgerskap);

        // sivilstand
        if (kafkaPerson.sivilstand.size() > 0) {
            person.INT_MaritalStatus__c = kafkaPerson.sivilstand[0].type;
            person.INT_MaritalStatusDate__c = dateCreator(kafkaPerson.sivilstand[0].gyldigFraOgMed);
            person.INT_MaritalRelation__c = kafkaPerson.sivilstand[0].relatertVedSivilstand;
        }

        // kjoenn
        if (kafkaPerson.kjoenn.size() > 0) {
            person.INT_Sex__c = genderTranslator(kafkaPerson.kjoenn[0]);
        }
        // doedsfall
        if (kafkaPerson.doedsfall.size() > 0) {
            person.INT_DateOfDeath__c = kafkaPerson.doedsfall[0].doedsdato == '0' ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato);
            person.INT_IsDeceased__c = kafkaPerson.doedsfall[0].doedsdato != null ? true : false;
        }

        // telefonnummer
        for (KafkaPerson_2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            person.INT_Phone1__c = tlf.prioritet == '1' ? tlf.landskode + tlf.nummer : '';
            person.INT_Phone2__c = tlf.prioritet == '2' ? tlf.landskode + tlf.nummer : '';
        }

        // utflyttingFraNorge
        if (kafkaPerson.utflyttingFraNorge.size() > 0) {
            person.INT_MovedToCountry__c = getCountryFromIso(kafkaPerson.utflyttingFraNorge[0].tilflyttingsland);
            person.INT_MovedToPlace__c = stringValidator(kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet);
        }

        // talesspraaktolk
        person.INT_SpokenLanguageIntepreter__c = safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk);

        // fullmakt
        if (kafkaPerson.fullmakt.size() > 0) {
            person.INT_PowerOfAttorney__c = JSON.serialize(kafkaPerson.fullmakt);
        }

        // vergemaalEllerFremtidsfullmakt
        if (kafkaPerson.vergemaalEllerFremtidsfullmakt.size() > 0) {
            person.INT_GuardianshipOrFuturePowerOfAttorney__c = JSON.serialize(kafkaPerson.vergemaalEllerFremtidsfullmakt);
        }

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
    @TestVisible private static String stringValidator(String stringToCheck) {
        return String.isBlank(stringToCheck) || stringToCheck == null ? '' : stringToCheck.left(255);
    }

    /**
     * Check that date has a value (not null or '')
     * @param dateToCheck Date to check
     * @return Date
     */
    @TestVisible private static Date dateCreator(String dateToCheck) {
        return !String.isBlank(dateToCheck) ? Date.valueOf(dateToCheck) : null;
    }

    /**
     * Check that date has a value (not null or '')
     * @param sexToCheck Date to check
     * @return Date
     */
    @TestVisible private static String genderTranslator(String sexToCheck) {
        return genderMap.containsKey(sexToCheck) ? genderMap.get(sexToCheck) : genderMap.get('UKJENT');
    }

    @TestVisible private static String addressCreator(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (stringValidator(addressField) != '') {
                addressString += stringValidator(addressField) + ' ';
            }
        }
        return addressString.removeEnd(' ');
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
        List<String> objectsFailingValidation = new List<String>();
        if (kafkaPerson.folkeregisterId.size() > 1) objectsFailingValidation.add('folkeregisterId');
        if (kafkaPerson.navn.size() > 1) objectsFailingValidation.add('navn');
        if (kafkaPerson.innflyttingTilNorge.size() > 1) objectsFailingValidation.add('innflyttingTilNorge');
        if (kafkaPerson.bostedsadresse.vegadresse.size() > 1) objectsFailingValidation.add('bostedsadresse.vegadresse');
        if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 1) objectsFailingValidation.add('bostedsadresse.matrikkeladresse');
        if (kafkaPerson.bostedsadresse.utenlandskAdresse.size() > 1) objectsFailingValidation.add('bostedsadresse.utenlandskAdresse');
        if (kafkaPerson.bostedsadresse.ukjentBosted.size() > 1) objectsFailingValidation.add('bostedsadresse.ukjentBosted');
        if (kafkaPerson.oppholdsadresse.vegadresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.vegadresse');
        if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.matrikkeladresse');
        if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.utenlandskAdresse');
        if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 1) objectsFailingValidation.add('oppholdsadresse.ukjentBosted');
        if (kafkaPerson.sivilstand.size() > 1) objectsFailingValidation.add('sivilstand');
        if (kafkaPerson.kjoenn.size() > 1) objectsFailingValidation.add('kjoenn');
        if (kafkaPerson.doedsfall.size() > 1) objectsFailingValidation.add('doedsfall');
        if (kafkaPerson.utflyttingFraNorge.size() > 1) objectsFailingValidation.add('utflyttingFraNorge');
        if(objectsFailingValidation.size() > 0) {
            throw new pdlListContainsTooManyEntriesException('Multiple objects received for ' + String.join(objectsFailingValidation, ','));
        }
    }

    /**
     * Create map from ISO country codes to English Country Label
     * @param commonCodeList List Common_Code__c records
     * @return map from ISO code to country in English
     */
    private static Map<String, String> createIsoMap(List<Common_Code__c> commonCodeList) {
        Map<String, String> isoMap = new Map<String, String>();
        for (Common_Code__c ccl : commonCodeList) {
            isoMap.put(ccl.CRM_Code__c, ccl.Name);
        }
        return isoMap;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible private static String getCountryFromIso(String isoCode) {
        if (isoMap.containsKey(isoCode)) {
            return isoMap.get(isoCode);
        } else return '';
    }

    /**
     * Sets empty value for all Person__c fields
     * @param person record to modify
     */
    private static void emptyPersonFieldValues(Person__c person) {
        List<String> intFields = new List<String>{
                'INT_ActorId__c', 'INT_Citizenships__c', 'INT_Confidential__c', 'INT_Coordinates__c', 'INT_Country__c', 'INT_DateOfDeath__c', 'INT_District__c', 'INT_FamilyRelations__c', 'INT_FirstName__c', 'INT_KrrEmail__c', 'INT_KrrIntegrationStatus__c', 'INT_KrrMobilePhone__c', 'INT_LastName__c', 'INT_LastUpdatedFromKRR__c', 'INT_LegalStatus__c', 'INT_MaritalRelation__c', 'INT_MaritalStatus__c', 'INT_MaritalStatusDate__c', 'INT_MiddleName__c', 'INT_MovedFromCountry__c', 'INT_MovedFromPlace__c', 'INT_MovedToCountry__c', 'INT_MovedToPlace__c', 'INT_MunicipalityNumber__c', 'INT_Phone1__c', 'INT_Phone2__c', 'INT_RegionNumber__c', 'INT_ResidentialAddress__c', 'INT_ResidentialZipCode__c', 'INT_SecurityMeasures__c', 'INT_Sex__c', 'INT_SpokenLanguageIntepreter__c', 'INT_TemporaryAddress__c', 'INT_TemporaryCoordinates__c', 'INT_TemporaryCountryCode__c', 'INT_TemporaryMunicipalityNumber__c', 'INT_TemporaryZipCode__c'
        };
        for (String intField : intFields) {
            Person.put(intField, null);
        }

    }

    public class pdlListContainsTooManyEntriesException extends Exception {
    }

}