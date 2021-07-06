public without sharing class KafkaPDLHandler2 implements IKafkaMessageConsumer {
    @TestVisible
    private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';

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

    public void processMessages(List<KafkaMessage__c> messages) {
        Map<String, Person__c> personMap = new Map<String, Person__c>();

        //If we have a message where the created date is older than last updated, set it to error so that we can investigate it.
        //If we have a tombstone without a person in Salesforce, set it to processed.
        checkLastUpdatedAndTombStones(messages);

        // Errors are caught and saved on each KafkaMessage record
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                try {
                    Person__c person = createPersonRecords(msg);
                    personMap.put(person.INT_ActorId__c, person);
                    msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } catch (Exception e) {
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg);
                }
            }
        }

        // Errors from DML will set all messages to failed.
        try {
            upsert personMap.values() INT_ActorId__c;
        } catch (Exception e) {
            for (KafkaMessage__c msg : messages) {
                String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                setMessageError(errorMsg, msg);
            }
        }
    }

    /**
     * Validates that the Kafka Message is not older than the last PDL Update on the Person
     * If a new person is a tombstone, do not import it
     * @param messages Set of Kafka Messages in scope
     * @return Deduplicated set of Kafka Message
     */
    @TestVisible
    private void checkLastUpdatedAndTombStones(List<KafkaMessage__c> messages) {
        Map<String, String> keyAktoerMap = new Map<String, String>(); //Key=CRM Key Value:ActorId
        Map<String, Datetime> messageMap = new Map<String, Datetime>();
        Set<String> tombstoneKeySet = new Set<String>();
        Map<String, Datetime> lastUpdatedMap;

        for (KafkaMessage__c msg : messages) {
            String decodedValue = KafkaMessageUtils.base64ULSafeDecode(msg.CRM_Key__c).toString();
            Key key = (KafkaPDLHandler2.Key) System.JSON.deserialize(decodedValue, KafkaPDLHandler2.Key.class);
            messageMap.put(key.aktoer_id, msg.CreatedDate);
            keyAktoerMap.put(msg.CRM_Key__c, key.aktoer_id);
            if (true == key.tombstone) {
                tombstoneKeySet.add(msg.CRM_Key__c);
            }
        }

        lastUpdatedMap = getPersonLastUpdatedMap(keyAktoerMap.values());

        //If Person DOES exist and the message is older than last PDL, set it to Processed
        //If Person DOES NOT exist and the message is marked with Tombstone, set it to Processed (we will NOT import it)
        for (KafkaMessage__c msg : messages) {
            if (lastUpdatedMap.containsKey(keyAktoerMap.get(msg.CRM_Key__c))) {
                DateTime lastUpdated = lastUpdatedMap.get(keyAktoerMap.get(msg.CRM_Key__c));
                if (msg.CreatedDate < lastUpdated) {
                    setMessageError('Message created date is less than Person__c.INT_LastUpdatedFromPDL__c', msg);
                }
            } else if (tombstoneKeySet.contains(msg.CRM_Key__c)) {
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
            }
        }
    }

    private Map<String, Datetime> getPersonLastUpdatedMap(List<String> actorIds) {
        Map<String, Datetime> lastUpdatedMap = new Map<String, Datetime>();

        for (Person__c p : [
            SELECT INT_ActorId__c, INT_LastUpdatedFromPDL__c
            FROM Person__c
            WHERE INT_ActorId__c IN :actorIds
        ]) {
            lastUpdatedMap.put(p.INT_ActorId__c, p.INT_LastUpdatedFromPDL__c);
        }

        return lastUpdatedMap;
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for each KafkaMessage
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    private Person__c createPersonRecords(KafkaMessage__c message) {
        Person__c person = new Person__c();
        person = setTombstoneFlag(person, message);
        person.INT_LastUpdatedFromPDL__c = message.createdDate;

        //If tombstone and no payload, just return minimum values
        if (true == person.INT_IsHasTombstone__c && String.isBlank(message.CRM_Value__c)) {
            return person;
        }

        emptyPersonFieldValues(person);

        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPerson2 kafkaPerson = KafkaPerson2.parse(decodedValue);

        validateListSizes(kafkaPerson);
        person = mapFieldValues(person, kafkaPerson);

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
        if (kafkaPerson.foedselsdato.size() > 0) {
            person.INT_DateOfBirth__c = kafkaPerson.foedselsdato[kafkaPerson.foedselsdato.size() - 1];
        }
        // Navn
        if (kafkaPerson.Navn.size() > 0) {
            person.INT_FirstName__c = stringValidator(kafkaPerson.Navn[kafkaPerson.Navn.size() - 1].fornavn);
            person.INT_MiddleName__c = stringValidator(kafkaPerson.Navn[kafkaPerson.Navn.size() - 1].mellomnavn);
            person.INT_LastName__c = stringValidator(kafkaPerson.Navn[kafkaPerson.Navn.size() - 1].etternavn);
        }
        // familierelasjoner
        person.INT_FamilyRelations__c = JSON.serialize(kafkaPerson.familierelasjoner);

        // folkeregisterpersonstatus
        person.INT_LegalStatus__c = kafkaPerson.folkeregisterpersonstatus[0];

        // InnflytningTilNorge
        if (kafkaPerson.innflyttingTilNorge.size() > 0) {
            person.INT_MovedFromCountry__c = getCountryIdFromIso(
                kafkaPerson.innflyttingTilNorge[kafkaPerson.innflyttingTilNorge.size() - 1].fraflyttingsland
            );
            person.INT_MovedFromPlace__c = kafkaPerson.innflyttingTilNorge[kafkaPerson.innflyttingTilNorge.size() - 1]
                .fraflyttingsstedIUtlandet;
        }

        // adressebeskyttelse
        person.INT_Confidential__c = setClearanceLevel(kafkaPerson.adressebeskyttelse);

        // sikkerhetstiltak
        person.INT_SecurityMeasures__c = JSON.serialize(kafkaPerson.sikkerhetstiltak);

        if (ADR_BESKYTTELSES_GRADERING.get(person.INT_Confidential__c) <= 2) {
            // bostedsadresser
            // assumption: vegadresse has first pri, then ukjentbosted
            if (kafkaPerson.bostedsadresse.vegadresse.size() > 0) {
                person.INT_ResidentialAddress__c = addressCreator(
                    new List<String>{
                        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn,
                        kafkaPerson.bostedsadresse.vegadresse[0].husnummer,
                        kafkaPerson.bostedsadresse.vegadresse[0].husbokstav
                    }
                );
                person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.vegadresse[0].postnummer;
                person.INT_AddressMunicipalityNumber__c = kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer;
                person.INT_AddressDistrictNumber__c = kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer;
                person.INT_Coordinates__c = kafkaPerson.bostedsadresse.vegadresse[0].koordinater;
            } else if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 0) {
                person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].postnummer;
                person.INT_AddressMunicipalityNumber__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].kommunenummer;
                person.INT_AddressDistrictNumber__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].bydelsnummer;
                person.INT_Coordinates__c = kafkaPerson.bostedsadresse.matrikkeladresse[0].koordinater;
            }

            // oppholdsadresser
            // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
            if (kafkaPerson.oppholdsadresse.vegadresse.size() > 0) {
                person.INT_TemporaryAddress__c = addressCreator(
                    new List<String>{
                        kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn,
                        kafkaPerson.oppholdsadresse.vegadresse[0].husnummer,
                        kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav
                    }
                );
                person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresse.vegadresse[0].postnummer;
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer;
                person.INT_TemporaryCoordinates__c = kafkaPerson.oppholdsadresse.vegadresse[0].koordinater;
            } else if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 0) {
                person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].postnummer;
                person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0]
                    .kommunenummer;
                person.INT_TemporaryCoordinates__c = kafkaPerson.oppholdsadresse.matrikkeladresse[0].koordinater;
            } else if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 0) {
                person.INT_TemporaryAddress__c = addressCreator(
                    new List<String>{
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].adressenavnNummer,
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bygningEtasjeLeilighet,
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postboksNummerNavn,
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].postkode,
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].bysted,
                        kafkaPerson.oppholdsadresse.utenlandskAdresse[0].regionDistriktOmraade
                    }
                ); // max 255 symbols might be an issue
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
        if (kafkaPerson.sivilstand.size() > 0) {
            person.INT_MaritalStatus__c = kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1].type;
            person.INT_MaritalStatusDate__c = dateCreator(
                kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1].gyldigFraOgMed
            );
            person.INT_MaritalRelation__c = kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1]
                .relatertVedSivilstand;
        }

        // kjoenn
        if (kafkaPerson.kjoenn.size() > 0) {
            person.INT_Sex__c = kafkaPerson.kjoenn[0];
        }
        // doedsfall
        if (kafkaPerson.doedsfall.size() > 0) {
            person.INT_DateOfDeath__c = getDoedsfall(kafkaPerson.doedsfall);
            person.INT_IsDeceased__c = true; //If we got any records return true even if we don't have a date.
        }

        // telefonnummer
        for (KafkaPerson2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            if (tlf.prioritet == '1') {
                person.INT_Phone1__c = tlf.landskode + tlf.nummer;
            }
            if (tlf.prioritet == '2') {
                person.INT_Phone2__c = tlf.landskode + tlf.nummer;
            }
        }

        // utflyttingFraNorge
        if (kafkaPerson.utflyttingFraNorge.size() > 0) {
            person.INT_MovedToCountry__c = getCountryIdFromIso(
                kafkaPerson.utflyttingFraNorge[kafkaPerson.utflyttingFraNorge.size() - 1].tilflyttingsland
            );
            person.INT_MovedToPlace__c = kafkaPerson.utflyttingFraNorge[kafkaPerson.utflyttingFraNorge.size() - 1]
                .tilflyttingsstedIUtlandet;
        }

        // talesspraaktolk
        person.INT_SpokenLanguageIntepreter__c = safelyJoinMultiPicklistString(kafkaPerson.talesspraaktolk);

        // fullmakt
        person.INT_PowerOfAttorney__c = (kafkaPerson.fullmakt == null ||
            kafkaPerson.fullmakt.size() == 0)
            ? null
            : JSON.serialize(kafkaPerson.fullmakt);

        // vergemaalEllerFremtidsfullmakt
        person.INT_GuardianshipOrFuturePowerOfAttorney__c = (kafkaPerson.vergemaalEllerFremtidsfullmakt == null ||
            kafkaPerson.vergemaalEllerFremtidsfullmakt.size() == 0)
            ? null
            : JSON.serialize(kafkaPerson.vergemaalEllerFremtidsfullmakt);

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
        person.INT_ActorId__c = key.aktoer_id;
        return person;
    }

    /**
     * Return the date of death
     * @param doedsfall list for KafkaPerson2.Doedsfall
     * @return Date the first date we find or NULL
     */
    @TestVisible
    private Date getDoedsfall(List<KafkaPerson2.Doedsfall> doedsfall) {
        Map<String, Date> doedsfallMap = new Map<String, Date>();

        for (KafkaPerson2.Doedsfall element : doedsfall) {
            if (String.isNotBlank(element.doedsdato)) {
                doedsfallMap.put(element.master.toUpperCase(), Date.valueOf(element.doedsdato));
            } else {
                doedsfallMap.put(element.master, null);
            }
        }

        if (doedsfallMap.containsKey('PDL')) {
            return doedsfallMap.get('PDL');
        } else if (doedsfallMap.containsKey('FREG')) {
            return doedsfallMap.get('FREG');
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

    /**
     * Check that field size limitations of 255 signs is followed and allow empty string
     * @param stringToCheck String to check
     * @return Empty String checked string with maximum 255 symbols
     */
    @TestVisible
    private static String stringValidator(String stringToCheck) {
        return String.isBlank(stringToCheck) || stringToCheck == null ? '' : stringToCheck.left(255);
    }

    /**
     * Check that date has a value (not null or '')
     * @param dateToCheck Date to check
     * @return Date
     */
    @TestVisible
    private static Date dateCreator(String dateToCheck) {
        return !String.isBlank(dateToCheck) ? Date.valueOf(dateToCheck) : null;
    }

    @TestVisible
    private static String addressCreator(List<String> addressFields) {
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
    // prettier-ignore
    private void validateListSizes(KafkaPerson2 kafkaPerson) {
        List<String> objectsFailingValidation = new List<String>();
        
        if (kafkaPerson.folkeregisterId.size() == 0) { throw new pdlMissingEntryException('No folkeregisterId found'); }
        if (kafkaPerson.folkeregisterpersonstatus.size() == 0) { throw new pdlMissingEntryException('No folkeregisterpersonstatus found'); }
        if (kafkaPerson.navn.size() == 0) { throw new pdlMissingEntryException('No name found'); }
        if (kafkaPerson.navn[0].etternavn == null) {throw new pdlMissingEntryException('No etternavn found'); }
        
        // Check for list sizes greater than one
        if (kafkaPerson.folkeregisterId.size() > 1) { objectsFailingValidation.add('folkeregisterId'); }
        if (kafkaPerson.folkeregisterpersonstatus.size() > 1) { objectsFailingValidation.add('folkeregisterpersonstatus'); }
        if (kafkaPerson.bostedsadresse.vegadresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.vegadresse'); }
        if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.matrikkeladresse'); }
        if (kafkaPerson.bostedsadresse.utenlandskAdresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.utenlandskAdresse'); }
        if (kafkaPerson.bostedsadresse.ukjentBosted.size() > 1) { objectsFailingValidation.add('bostedsadresse.ukjentBosted'); }
        if (kafkaPerson.oppholdsadresse.vegadresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.vegadresse'); }
        if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.matrikkeladresse'); }
        if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.utenlandskAdresse'); }
        if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 1) { objectsFailingValidation.add('oppholdsadresse.ukjentBosted'); }
        if (kafkaPerson.kjoenn.size() > 1) { objectsFailingValidation.add('kjoenn'); }
        
        if (objectsFailingValidation.size() > 0) {
            throw new pdlListContainsTooManyEntriesException(
                'Multiple objects received for ' +
                String.join(objectsFailingValidation, ',')
            );
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

    /**
     * Takes ISO code value and gives country name in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static String getCountryNameFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country == null ? null : country.Name;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static Id getCountryIdFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country == null ? null : country.Id;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private static Common_Code__c getCountryFromIso(String isoCode) {
        if (isoCode == null || isoCode == '') {
            return null;
        } else if (ISO_MAP.containsKey(isoCode)) {
            return ISO_MAP.get(isoCode);
        } else {
            throw new isoCodeNotFoundException('No country was found for the ISO code \'' + isoCode + '\'.');
        }
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

    private void setMessageError(String errorMsg, KafkaMessage__c message) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
    }

    private class Key {
        final String aktoer_id;
        final Boolean tombstone;
    }

    public class PdlListContainsTooManyEntriesException extends Exception {
    }

    public class PdlMissingEntryException extends Exception {
    }

    public class IsoCodeNotFoundException extends Exception {
    }
}
