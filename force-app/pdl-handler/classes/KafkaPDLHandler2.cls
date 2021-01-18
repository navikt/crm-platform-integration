public without sharing class KafkaPDLHandler2 implements IKafkaMessageConsumer {

    @TestVisible private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';
    @TestVisible private static final Map<String, Integer> ADR_BESKYTTELSES_GRADERING = New Map<String, Integer>{
            'STRENGT_FORTROLIG' => 4, 'STRENGT_FORTROLIG_UTLAND' => 3, 'FORTROLIG' => 2, 'UGRADERT' => 1
    };
    private static final Map<String, Common_Code__c> isoMap = createIsoMap([SELECT Name, CRM_Code__c FROM Common_Code__c WHERE CRM_Active__c = TRUE AND CRM_Code_Set__c IN ('Landkoder', 'LandkoderISO2')]);

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
        KafkaPerson2 kafkaPerson = KafkaPerson2.parse(decodedValue);
        validateListSizes(kafkaPerson);
        Person__c person = new Person__c();
        emptyPersonFieldValues(person);
        person = mapFieldValues(person, kafkaPerson);
        person = setTombstoneFlag(person, message);
        return person;
    }

    /**
     * Transform and map fields from PDL data structure to Person__c SObject
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a person from PDL
     * @return Person Account with initialized fields
     */
    private Person__c mapFieldValues(Person__c person, KafkaPerson2 kafkaPerson) {


        person.INT_ActorId__c = kafkaPerson.aktoerId;
        if (kafkaPerson.folkeregisterId.size() > 0) {
            person.Name = kafkaPerson.folkeregisterId[0];
        }
        if (kafkaPerson.foedselsdato.size()>0) {
            person.INT_DateOfBirth__c = kafkaPerson.foedselsdato[0];
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
        person.INT_LegalStatus__c = kafkaPerson.folkeregisterpersonstatus[0];

        // InnflytningTilNorge
        person = setInnflyttingtilNorge(person, kafkaPerson.innflyttingTilNorge);

        // adressebeskyttelse
        person.INT_Confidential__c = setClearanceLevel(kafkaPerson.adressebeskyttelse);

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
                person.INT_AddressMunicipalityNumber__c = kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer;
//                person.INT_RegionNumber__c = getRegion(kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer, kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer);
                person.INT_AddressDistrictNumber__c = kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer;
                person.INT_Coordinates__c = kafkaPerson.bostedsadresse.vegadresse[0].koordinater;
            } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 0) {
                person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer;
                person.INT_AddressMunicipalityNumber__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer;
//                person.INT_RegionNumber__c = getRegion(kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer, kafkaPerson.bostedsadresse.matrikkeladresse[0].bydelsnummer);
                person.INT_AddressDistrictNumber__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].bydelsnummer;
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
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].kommunenummer;
                person.INT_TemporaryCoordinates__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater;
            } else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 0) {
                person.INT_TemporaryAddress__c = addressCreator(new List<String>{
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted, kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade
                });                                      // max 255 symbols might be an issue
                person.INT_TemporaryCountryCode__c = kafkaPerson.oppholdsadresse.utenlandskAdresse[0].landkode.left(3);
            } else if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 0) {
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.ukjentBosted[0].bostedskommune;
            }
        }

        // Set GT Municipality and District numbers
        if (kafkaPerson.kommunenummerFraGt != PDL_ERROR_STRING) {
            person.INT_GTMunicipalityNumber__c = kafkaPerson.kommunenummerFraGt;
            person.INT_RegionNumber__c = kafkaPerson.kommunenummerFraGt.left(2);
        }
        if (kafkaPerson.bydelsnummerFraGt != PDL_ERROR_STRING) {
            person.INT_RegionNumber__c = kafkaPerson.bydelsnummerFraGt.left(2);
            person.INT_GTDistrictNumber__c = kafkaPerson.bydelsnummerFraGt;
        }

        // Set Municipality and District from GT if available, otherwise from Bostedsaddresse
        if (person.INT_GTMunicipalityNumber__c != null) {
            person.INT_MunicipalityNumber__c = person.INT_GTMunicipalityNumber__c;
        } else if (person.INT_AddressMunicipalityNumber__c != null) {
            person.INT_MunicipalityNumber__c = person.INT_AddressMunicipalityNumber__c;
        }
        if (person.INT_GTDistrictNumber__c != null) {
            person.INT_DistrictNumber__c = person.INT_GTDistrictNumber__c;
        } else if (person.INT_AddressDistrictNumber__c != null) {
            person.INT_DistrictNumber__c = person.INT_AddressDistrictNumber__c;
        }

        // statsborgerskap
        person.INT_Citizenships__c = crateCitizenshipString(kafkaPerson.statsborgerskap);

        // sivilstand
        person = setMaritialStatus(person, kafkaPerson.sivilstand);

        // kjoenn
        if (kafkaPerson.kjoenn.size() > 0) {
            person.INT_Sex__c = kafkaPerson.kjoenn[0];
        }
        // doedsfall
        if (kafkaPerson.doedsfall.size() > 0) {
            person.INT_DateOfDeath__c = kafkaPerson.doedsfall[0].doedsdato == null ? null : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato);
            person.INT_IsDeceased__c = kafkaPerson.doedsfall[0].doedsdato != null ? true : false;
        }

        // telefonnummer
        for (KafkaPerson2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            if(tlf.prioritet == '1') {
                person.INT_Phone1__c = tlf.landskode + tlf.nummer;
            }
            if(tlf.prioritet == '2') {
                person.INT_Phone2__c = tlf.landskode + tlf.nummer;
            }
        }

        // utflyttingFraNorge
        person = setUtflyttingFraNorge(person, kafkaPerson.utflyttingFraNorge);

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

    private Person__c setTombstoneFlag(Person__c person, KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Key__c).toString();
        Key key = (KafkaPDLHandler2.Key) System.JSON.deserialize(decodedValue, KafkaPDLHandler2.Key.class);
        person.INT_IsHasTombstone__c = key.tombstone;
        return person;
    }

    /**
     * Set maritial status on Person__c
     * If the list only contain one status, use this.
     * If the list contain multiple statuses, select the one with the newest date, skip those without date.
     * @param person the Person__c to update with marital status
     * @param maritialStatuses list of KafkaPerson2.Sivilstand elements
     * @return person
     */
    @TestVisible
    private Person__c setMaritialStatus(Person__c person, List<KafkaPerson2.Sivilstand> maritialStatuses) {
        if(null == maritialStatuses) { return person; }

        Integer nmbOfStatuses = maritialStatuses.size();

        for(KafkaPerson2.Sivilstand maritialStatus : maritialStatuses) {
            //If more than one element, skip those without date
            if(1 < nmbOfStatuses && String.isBlank(maritialStatus.gyldigFraOgMed)) { continue; }
            
            Date maritalStatusDate = dateCreator(maritialStatus.gyldigFraOgMed);
            
            if(nmbOfStatuses == 1 || person.INT_MaritalStatusDate__c == null || person.INT_MaritalStatusDate__c < maritalStatusDate) {
                person.INT_MaritalStatus__c = maritialStatus.type;
                person.INT_MaritalStatusDate__c = maritalStatusDate;
                person.INT_MaritalRelation__c = maritialStatus.relatertVedSivilstand;
            }

        }
        
        return person;
    }

    /**
     * Set the first element as moved from
     * @param person
     * @param innflyttinger list of KafkaPerson2.InnflyttingTilNorge
     * @return person
     */
    @TestVisible private Person__c setInnflyttingtilNorge(Person__c person, List<KafkaPerson2.InnflyttingTilNorge> innflyttinger) {
        if(null == innflyttinger || innflyttinger.isEmpty()) { return person; }

        if(String.isNotBlank(innflyttinger[0].fraflyttingsland)) {
            person.INT_MovedFromCountry__c = getCountryFromIso(innflyttinger[0].fraflyttingsland).Id;
            person.INT_MovedFromPlace__c = stringValidator(innflyttinger[0].fraflyttingsstedIUtlandet);
        }

        return person;
    }

    /**
     * Set the first element as moved to
     * @param person
     * @param utflyttinger list of KafkaPerson2.UtflyttingFraNorge
     * @return person
     */
    @TestVisible private Person__c setUtflyttingFraNorge(Person__c person, List<KafkaPerson2.UtflyttingFraNorge> utflyttinger) {
        if(null == utflyttinger || utflyttinger.isEmpty()) { return person; }

        if(String.isNotBlank(utflyttinger[0].tilflyttingsland)) {
            person.INT_MovedToCountry__c = getCountryFromIso(utflyttinger[0].tilflyttingsland).Id;
            person.INT_MovedToPlace__c = stringValidator(utflyttinger[0].tilflyttingsstedIUtlandet);
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
    private String setClearanceLevel(List<String> values) {
        Integer grade = 0;
        String returnGrade = 'UGRADERT';
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
    private void validateListSizes(KafkaPerson2 kafkaPerson) {
        List<String> objectsFailingValidation = new List<String>();
        if (kafkaPerson.folkeregisterId.size() == 0) throw new pdlMissingEntryException('No folkeregisterId found');
        if (kafkaPerson.navn.size() == 0) throw new pdlMissingEntryException('No folkeregisterId found');
        if (kafkaPerson.folkeregisterpersonstatus.size() == 0) throw new pdlMissingEntryException('No folkeregisterpersonstatus found');

        if (kafkaPerson.folkeregisterId.size() > 1) objectsFailingValidation.add('folkeregisterId');
        if (kafkaPerson.foedselsdato.size() > 1) objectsFailingValidation.add('foedselsdato');
        if (kafkaPerson.navn.size() > 1) objectsFailingValidation.add('navn');
        if (kafkaPerson.folkeregisterpersonstatus.size() > 1) objectsFailingValidation.add('folkeregisterpersonstatus');
        if (kafkaPerson.innflyttingTilNorge.size() > 1 && countNumberOfUniqueContriesForInnflyttingTilNorge(kafkaPerson) > 1) objectsFailingValidation.add('innflyttingTilNorge');
        if (kafkaPerson.bostedsadresse.vegadresse.size() > 1) objectsFailingValidation.add('bostedsadresse.vegadresse');
        if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 1) objectsFailingValidation.add('bostedsadresse.matrikkeladresse');
        if (kafkaPerson.bostedsadresse.utenlandskAdresse.size() > 1) objectsFailingValidation.add('bostedsadresse.utenlandskAdresse');
        if (kafkaPerson.bostedsadresse.ukjentBosted.size() > 1) objectsFailingValidation.add('bostedsadresse.ukjentBosted');
        if (kafkaPerson.oppholdsadresse.vegadresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.vegadresse');
        if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.matrikkeladresse');
        if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 1) objectsFailingValidation.add('oppholdsadresse.utenlandskAdresse');
        if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 1) objectsFailingValidation.add('oppholdsadresse.ukjentBosted');
        if (kafkaPerson.kjoenn.size() > 1) objectsFailingValidation.add('kjoenn');
        if (kafkaPerson.doedsfall.size() > 1) objectsFailingValidation.add('doedsfall');
        if (kafkaPerson.utflyttingFraNorge.size() > 1 && countNumberOfUniqueContriesForUtlyttingFraNorge(kafkaPerson) > 1) objectsFailingValidation.add('utflyttingFraNorge');
        if (objectsFailingValidation.size() > 0) {
            throw new pdlListContainsTooManyEntriesException('Multiple objects received for ' + String.join(objectsFailingValidation, ','));
        }

        if (kafkaPerson.navn[0].etternavn == null) throw new pdlMissingEntryException('No etternavn found');
    }

     /**
     * Count number of unique countires for utlyttingFraNorge, to check if same country is listed several times.
     * @param kafkaPerson Kafka person to validate
     */
     private Integer countNumberOfUniqueContriesForUtlyttingFraNorge(KafkaPerson2 kafkaPerson){
        Set<String> uniqueCountries=new Set<String>();
        for(KafkaPerson2.UtflyttingFraNorge element:kafkaPerson.utflyttingFraNorge){
            uniqueCountries.add(element.tilflyttingsland);
        }
        return uniqueCountries.size();
     }

     /**
     * Count number of unique countires for innflyttingFraNorge, to check if same country is listed several times.
     * @param kafkaPerson Kafka person to validate
     */
    private Integer countNumberOfUniqueContriesForInnflyttingTilNorge(KafkaPerson2 kafkaPerson){
        Set<String> uniqueCountries=new Set<String>();
        for(KafkaPerson2.InnflyttingTilNorge element:kafkaPerson.innflyttingTilNorge){
            uniqueCountries.add(element.fraflyttingsland);
        }
        return uniqueCountries.size();
     }


    /**
     * Create map from ISO country codes to English Country Label
     * @param commonCodeList List Common_Code__c records
     * @return map from ISO code to country in English
     */
    private static Map<String, Common_Code__c> createIsoMap(List<Common_Code__c> commonCodeList) {
        Map<String, Common_Code__c> isoMap = new Map<String, Common_Code__c>();
        for (Common_Code__c ccl : commonCodeList) {
            isoMap.put(ccl.CRM_Code__c, ccl);
        }
        return isoMap;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible private static Common_Code__c getCountryFromIso(String isoCode) {
        if (isoCode == null || isoCode == '') {
            return null;
        } else if (isoMap.containsKey(isoCode)) {
            return isoMap.get(isoCode);
        } else throw new isoCodeNotFoundException('No country was found for the ISO code \'' + isoCode + '\'.');
    }

    /**
     * @param kommunenummer String containing kommunenummer
     * @param bydelsnummer String containing bydelsnummer
     * @return 2 most left character of (pri 1) kommunenummer or (pri 2) bydelsnummer. if both are empty, empty string is returned
     */
    @TestVisible private static String getRegion(String kommunenummer, String bydelsnummer) {
        return kommunenummer == '' || kommunenummer == null ? bydelsnummer == '' || bydelsnummer == null ? '' : bydelsnummer.left(2) : kommunenummer.left(2);
    }

    /**
     * @param citizenships ISO countrycodes (list)
     *
     * @return country names joined with ';'
     */
    @TestVisible private static String crateCitizenshipString(List<String> citizenships) {
        String citizenshipReturnString = '';
        for (String citizenship : citizenships) {
            citizenshipReturnString = citizenshipReturnString + (getCountryFromIso(citizenship).Name) + ';';

        }

        return citizenshipReturnString.removeEnd(';');
    }

    /**
     * Sets empty value for all Person__c fields
     * @param person record to modify
     */
    private static void emptyPersonFieldValues(Person__c person) {
        List<String> intFields = new List<String>{
                'INT_Citizenships__c',
                'INT_Confidential__c',
                'INT_Coordinates__c',
                'INT_DateOfBirth__c',
                'INT_DateOfDeath__c',
                'INT_DistrictNumber__c',
                'INT_FamilyRelations__c',
                'INT_FirstName__c',
                'INT_LastName__c',
                'INT_LegalStatus__c',
                'INT_MaritalRelation__c',
                'INT_MaritalStatus__c',
                'INT_MaritalStatusDate__c',
                'INT_MiddleName__c',
                'INT_MovedFromCountry__c',
                'INT_MovedFromPlace__c',
                'INT_MovedToCountry__c',
                'INT_MovedToPlace__c',
                'INT_MunicipalityNumber__c',
                'INT_Phone1__c',
                'INT_Phone2__c',
                'INT_RegionNumber__c',
                'INT_ResidentialAddress__c',
                'INT_ResidentialZipCode__c',
                'INT_SecurityMeasures__c',
                'INT_Sex__c',
                'INT_SpokenLanguageIntepreter__c',
                'INT_TemporaryAddress__c',
                'INT_TemporaryCoordinates__c',
                'INT_TemporaryCountryCode__c',
                'INT_TemporaryMunicipalityNumber__c',
                'INT_TemporaryZipCode__c'
        };
        for (String intField : intFields) {
            Person.put(intField, null);
        }

    }

    private class Key {
        Boolean tombstone;
    }

    public class pdlListContainsTooManyEntriesException extends Exception {
    }

    public class pdlMissingEntryException extends Exception {
    }

    public class isoCodeNotFoundException extends Exception {

    }

}