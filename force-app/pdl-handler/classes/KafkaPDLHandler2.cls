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

    private Set<String> existingActors;

    private LoggerUtility logger;

    public void processMessages(List<KafkaMessage__c> messages) {
        logger = new LoggerUtility('PDL');
        Map<String, Person__c> personMap = new Map<String, Person__c>();
        existingActors = new Set<String>();
        Map<String, KafkaMessage__c> messageMap = new Map<String, KafkaMessage__c>();

        //If we have a message where the created date is older than last updated, set it to error so that we can investigate it.
        //If we have a tombstone without a person in Salesforce, set it to processed.
        checkLastUpdatedAndTombStones(messages);

        // Errors are caught and saved on each KafkaMessage record
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                try {
                    Person__c person = createPersonRecords(msg);
                    personMap.put(person.INT_ActorId__c, person);
                    messageMap.put(person.INT_ActorId__c, msg);
                    msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } catch (PdlIdentException e) {
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg, KafkaMessageService.STATUS_ERROR);
                    logger.error(
                        'Error creatign Person__c from PDL Kafka message. ' +
                        '\n ' +
                        e.getMessage() +
                        '\n Kafka key reference: ' +
                        msg.CRM_Key__c,
                        null,
                        CRM_ApplicationDomain.domain.NKS
                    );
                } catch (Exception e) {
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg);
                    if (msg.CRM_Status__c == KafkaMessageService.STATUS_ERROR) {
                        logger.error(
                            'Error creatign Person__c from PDL Kafka message. ' +
                            '\n Kafka key reference: ' +
                            msg.CRM_Key__c,
                            null,
                            CRM_ApplicationDomain.domain.NKS
                        );
                    } else if (msg.CRM_Status__c == KafkaMessageService.STATUS_WARNING) {
                        logger.warning(
                            'Warning creatign Person__c from PDL Kafka message. ' +
                            '\n Kafka key reference: ' +
                            msg.CRM_Key__c,
                            null,
                            CRM_ApplicationDomain.domain.NKS
                        );
                    }
                }
            }
        }
        List<Person__c> personList = new List<Person__c>();
        List<KafkaMessage__c> messageList = new List<KafkaMessage__c>();
        for (String actorId : personMap.keySet()) {
            personList.add(personMap.get(actorId));
            messageList.add(messageMap.get(actorId));
        }
        // Errors from DML will set all messages to failed.
        // try {
        List<Database.UpsertResult> urList = Database.upsert(personList, Person__c.INT_ActorId__c, false);
        for (Integer i = 0; i < urList.size(); i++) {
            if (false == urList[i].isSuccess()) {
                String errorMsg = 'Upsert error:';
                for (Database.Error error : urList[i].getErrors()) {
                    errorMsg += ' * ' + error.getMessage();
                }
                setMessageError(errorMsg, messageList[i]);
                if (messageList[i].CRM_Status__c == KafkaMessageService.STATUS_ERROR) {
                    logger.error(
                        'Error updating Person__c.' +
                        '\n Kafka key reference: ' +
                        messageList[i].CRM_Key__c,
                        null,
                        CRM_ApplicationDomain.domain.NKS
                    );
                } else if (messageList[i].CRM_Status__c == KafkaMessageService.STATUS_WARNING) {
                    logger.warning(
                        'Warning updating Person__c.' +
                        '\n Kafka key reference: ' +
                        messageList[i].CRM_Key__c,
                        null,
                        CRM_ApplicationDomain.domain.NKS
                    );
                }
            }
        }
        logger.publish();
    }

    /**
     * Validates that the Kafka Message is not older than the last PDL Update on the Person
     * If a new person is a tombstone, do not import it
     * @param messages Set of Kafka Messages in scope
     * @return Deduplicated set of Kafka Message
     */
    @TestVisible
    private void checkLastUpdatedAndTombStones(List<KafkaMessage__c> messages) {
        List<String> idList = new List<String>();
        List<Boolean> tombList = new List<Boolean>();
        Set<String> tombSet = new Set<String>();
        Set<String> personTombSet = new Set<String>();
        List<String> personIdList = new List<String>();
        List<Datetime> updatedList = new List<Datetime>();
        Map<String, Datetime> updatedMap = new Map<String, Datetime>();
        Set<String> split = new Set<String>();

        for (KafkaMessage__c msg : messages) {
            Key k = getKeyFromBase64(msg.CRM_Key__c);
            //Lists of key values wich match order of kafka messages
            idList.add(k.aktoer_id);
            tombList.add(k.tombstone);
            //A Set of idents with tombstones from kafka messages
            if (k.tombstone == true) {
                tombSet.add(k.aktoer_id);
            }
        }
        for (Person__c p : [
            SELECT INT_ActorId__c, INT_LastUpdatedFromPDL__c, INT_IsHasTombstone__c
            FROM Person__c
            WHERE INT_ActorId__c IN :idList
        ]) {
            if (p.INT_IsHasTombstone__c) {
                //A Set of idents wich already has tombstones
                personTombSet.add(p.INT_ActorId__c);
            }
            //A List with ident for existing persons
            personIdList.add(p.INT_ActorId__c);
            //A List of Update Datetime values (same order as personIdList)
            updatedList.add(p.INT_LastUpdatedFromPDL__c);
        }
        for (Integer i = 0; i < personIdList.size(); i++) {
            System.debug('for: ' + personIdList[i]);
            if (!personTombSet.contains(personIdList[i]) && !split.contains(personIdList[i])) {
                if (!updatedMap.containsKey(personIdList[i])) {
                    //A Map with ident as a key and LastUpdate as a value for existing persons
                    updatedMap.put(personIdList[i], updatedList[i]);
                } else {
                    //in case if there are several persons with same actorId making a list for it
                    split.add(personIdList[i]);
                    updatedMap.remove(personIdList[i]);
                }
            }
        }
        existingActors = updatedMap.keySet();

        for (Integer i = 0; i < messages.size(); i++) {
            if (split.contains(idList[i])) {
                //when a few person records with same actor id exists
                setMessageError(
                    'There exists more than one records for Id.(split/merge)',
                    messages[i],
                    KafkaMessageService.STATUS_ERROR
                );
            } else if (personTombSet.contains(idList[i])) {
                //when person already exists and has tombstone
                setMessageError('Trying update Tombstone.', messages[i], KafkaMessageService.STATUS_WARNING);
            } else if (updatedMap.containsKey(idList[i]) && (messages[i].createdDate < updatedMap.get(idList[i]))) {
                //when person exists and has more recent update
                setMessageError(
                    'Trying update a newer record. Skip update.',
                    messages[i],
                    KafkaMessageService.STATUS_WARNING
                );
            } else if (!tombList[i] && tombSet.contains(idList[i])) {
                //when there is update and tombstone messages for same person in the list
                setMessageError(
                    'There is a Tombstone message for person. Skip update.',
                    messages[i],
                    KafkaMessageService.STATUS_WARNING
                );
            } else if (!updatedMap.containsKey(idList[i]) && tombList[i]) {
                setMessageError(
                    'Trying insert Tombstone. Skip insert.',
                    messages[i],
                    KafkaMessageService.STATUS_PROCESSED
                );
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

        //If tombstone and no payload, clear data for person except idents.
        if (true == person.INT_IsHasTombstone__c && String.isBlank(message.CRM_Value__c)) {
            emptyTombstonePerson(person);
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
        if (kafkaPerson.identer != null && kafkaPerson.identer.isEmpty() == false) {
            setIdents(kafkaPerson, person);
            setName(kafkaPerson, person);
        } else {
            person.INT_ActorId__c = kafkaPerson.aktoerId;
            if (kafkaPerson.folkeregisterId.size() > 0) {
                person.Name = kafkaPerson.folkeregisterId[0];
            }
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

        // folkeregisterpersonstatus
        if (kafkaPerson.folkeregisterpersonstatus.size() > 0) {
            person.INT_LegalStatus__c = kafkaPerson.folkeregisterpersonstatus[0];
        }

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

        // adresse
        setAddress(person, kafkaPerson);

        setMunicipalityAndGT(person, kafkaPerson);

        // statsborgerskap
        person.INT_Citizenships__c = crateCitizenshipString(kafkaPerson.statsborgerskap);

        // sivilstand
        if (kafkaPerson.sivilstand.size() > 0) {
            person.INT_MaritalStatus__c = kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1].type.name();
            // person.INT_MaritalStatusDate__c = dateCreator(
            //     kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1].gyldigFraOgMed
            // );
            person.INT_MaritalStatusDate__c = kafkaPerson.sivilstand[kafkaPerson.sivilstand.size() - 1].gyldigFraOgMed;
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

    @TestVisible
    private void setAddress(Person__c person, KafkaPerson2 kafkaPerson) {
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
    }

    @TestVisible
    private void setMunicipalityAndGT(Person__c person, KafkaPerson2 kafkaPerson) {
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
        
        
        if(kafkaPerson.identer == null) {
            if (kafkaPerson.folkeregisterId.size() == 0) { throw new pdlMissingEntryException('No folkeregisterId found'); }
            if (kafkaPerson.folkeregisterpersonstatus.size() == 0) { throw new pdlMissingEntryException('No folkeregisterpersonstatus found'); }
        } else {
            if (kafkaPerson.identer.size() == 0) { throw new pdlMissingEntryException('No idents found'); }
        }

        if (kafkaPerson.navn.size() == 0) { throw new pdlMissingEntryException('No name found'); }
        if (kafkaPerson.navn[0].etternavn == null) {throw new pdlMissingEntryException('No etternavn found'); }

        // Check for list sizes greater than one
        if (kafkaPerson.bostedsadresse.vegadresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.vegadresse'); }
        if (kafkaPerson.bostedsadresse.matrikkeladresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.matrikkeladresse'); }
        if (kafkaPerson.bostedsadresse.utenlandskAdresse.size() > 1) { objectsFailingValidation.add('bostedsadresse.utenlandskAdresse'); }
        if (kafkaPerson.bostedsadresse.ukjentBosted.size() > 1) { objectsFailingValidation.add('bostedsadresse.ukjentBosted'); }
        if (kafkaPerson.oppholdsadresse.vegadresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.vegadresse'); }
        if (kafkaPerson.oppholdsadresse.matrikkeladresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.matrikkeladresse'); }
        if (kafkaPerson.oppholdsadresse.utenlandskAdresse.size() > 1) { objectsFailingValidation.add('oppholdsadresse.utenlandskAdresse'); }
        if (kafkaPerson.oppholdsadresse.ukjentBosted.size() > 1) { objectsFailingValidation.add('oppholdsadresse.ukjentBosted'); }
        
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
    private String getCountryNameFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country == null ? isoCode : country.Name;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private Id getCountryIdFromIso(String isoCode) {
        Common_Code__c country = getCountryFromIso(isoCode);
        return country == null ? null : country.Id;
    }

    /**
     * Takes ISO code value and gives country value in return
     * @param isoCode ISO-code. either ISO 2 or ISO 3 standard
     * @return country in English
     */
    @TestVisible
    private Common_Code__c getCountryFromIso(String isoCode) {
        if (ISO_MAP.containsKey(isoCode)) {
            return ISO_MAP.get(isoCode);
        }

        if (String.isNotBlank(isoCode)) {
            logger.error(
                'Error getting country from ISO Code.' +
                '\n ISO Code: ' +
                isoCode,
                null,
                CRM_ApplicationDomain.domain.NKS
            );
        }
        return null;
    }

    /**
     * @param citizenships ISO countrycodes (list)
     *
     * @return country names joined with ';'
     */
    @TestVisible
    private String crateCitizenshipString(List<String> citizenships) {
        String citizenshipReturnString = '';
        for (String citizenship : citizenships) {
            citizenshipReturnString = citizenshipReturnString + (getCountryNameFromIso(citizenship)) + ';';
        }

        return citizenshipReturnString.removeEnd(';');
    }

    @TestVisible
    private static void setIdents(KafkaPerson2 kafkaPerson, Person__c person) {
        person.INT_NPID__c = Pdl_IdentUtility.getIdentsFromList(kafkaPerson.identer).npid;
        setFolkeregisterIdents(kafkaPerson.folkeregisteridentifikator, person);
    }

    private static void setFolkeregisterIdents(
        PDL_FolkeregisterIdentifikator[] folkeregisterIdentifikator,
        Person__c person
    ) {
        for (PDL_FolkeregisterIdentifikator identifikator : folkeregisterIdentifikator) {
            if (String.isBlank(identifikator.identifikasjonsnummer)) {
                continue;
            }

            switch on identifikator.type {
                when DNR {
                    if (String.isBlank(person.INT_dnr__c) || identifikator.metadata.historisk == false) {
                        person.INT_dnr__c = identifikator.identifikasjonsnummer;
                    }
                    continue;
                }
                when FNR {
                    if (identifikator.metadata.historisk == false && identifikator.status == PDL_IdentStatus.I_BRUK) {
                        person.INT_fnr__c = identifikator.identifikasjonsnummer;
                    }
                    continue;
                }
            }
        }
    }
    /**
     * Sets the Name field to one of valid idents with priority: FOLKEREGISTERIDENT, NPID, AKTORID
     * if the list does not include valid idents - throwing exception
     */
    @TestVisible
    private static void setName(KafkaPerson2 kfkPerson, Person__c person) {
        List<PDL_IdentInformasjon> identer = new List<PDL_IdentInformasjon>(kfkPerson.identer);
        String flkId;
        String npId;
        for (PDL_IdentInformasjon ident : identer) {
            if (ident.historisk == false) {
                switch on ident.gruppe {
                    when FOLKEREGISTERIDENT {
                        flkId = ident.ident;
                    }
                    when NPID {
                        npId = ident.ident;
                    }
                }
            }
        }
        person.Name = (String.isNotBlank(flkId)) ? flkId : ((String.isNotBlank(npId) ? npId : null));
        if (String.isBlank(person.Name))
            throw new PdlIdentException('Not able to set any person idents from Kafka');
    }

    /**
     * Sets empty value for all Person__c fields
     * @param person record to modify
     */
    @TestVisible
    private static void emptyPersonFieldValues(Person__c person) {
        List<String> intFields = new List<String>{
            'INT_AddressDistrictNumber__c',
            'INT_AddressMunicipalityNumber__c',
            'INT_Citizenships__c',
            'INT_Confidential__c',
            'INT_Coordinates__c',
            'INT_DateOfBirth__c',
            'INT_DateOfDeath__c',
            'INT_DistrictNumber__c',
            'INT_dnr__c',
            'INT_FamilyRelations__c',
            'INT_FirstName__c',
            'INT_fnr__c',
            'INT_GTDistrictNumber__c',
            'INT_GTMunicipalityNumber__c',
            'INT_GuardianshipOrFuturePowerOfAttorney__c',
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
            'INT_npid__c',
            'INT_Phone1__c',
            'INT_Phone2__c',
            'INT_PowerOfAttorney__c',
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
            person.put(intField, null);
        }

        //Set field value to false
        for (String boolField : new List<String>{ 'INT_IsDeceased__c' }) {
            person.put(boolField, false);
        }
    }

    /**
     * Sets empty value for all Person__c fields except idents
     * @param person record to modify
     */
    @TestVisible
    private static void emptyTombstonePerson(Person__c person) {
        List<String> intFields = new List<String>{
            'INT_AddressDistrictNumber__c',
            'INT_AddressMunicipalityNumber__c',
            'INT_BankAccountNumber__c',
            'INT_BankAccountNumberLastModified__c',
            'INT_Citizenships__c',
            'INT_Confidential__c',
            'INT_Coordinates__c',
            'INT_DateOfBirth__c',
            'INT_DateOfDeath__c',
            'INT_DistrictNumber__c',
            'INT_FamilyRelations__c',
            'INT_FirstName__c',
            'INT_GTDistrictNumber__c',
            'INT_GTMunicipalityNumber__c',
            'INT_GuardianshipOrFuturePowerOfAttorney__c',
            'INT_KrrEmail__c',
            'INT_KrrIntegrationStatus__c',
            'INT_KrrMobilePhone__c',
            'INT_LastName__c',
            'INT_LastUpdatedFromKRR__c',
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
            'INT_NavEmployeeFromDateTime__c',
            'INT_NavEmployeeToDateTime__c',
            'INT_Phone1__c',
            'INT_Phone2__c',
            'INT_PowerOfAttorney__c',
            'INT_RegionNumber__c',
            'INT_ResidentialAddress__c',
            'INT_ResidentialZip__c',
            'INT_ResidentialZipCode__c',
            'INT_SecurityMeasures__c',
            'INT_Sex__c',
            'INT_SpokenLanguageIntepreter__c',
            'INT_TemporaryAddress__c',
            'INT_TemporaryCoordinates__c',
            'INT_TemporaryCountryCode__c',
            'INT_TemporaryMunicipalityNumber__c',
            'INT_TemporaryZipCode__c',
            'INT_VerifiedFromKRR__c'
        };
        for (String intField : intFields) {
            person.put(intField, null);
        }

        //Set field value to false
        for (
            String boolField : new List<String>{ 'INT_IsDeceased__c', 'INT_IsNavEmployee__c', 'INT_KRR_Reservation__c' }
        ) {
            person.put(boolField, false);
        }
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Key__c).toString();
        Key key = (KafkaPDLHandler2.Key) System.JSON.deserialize(decodedValue, KafkaPDLHandler2.Key.class);

        if (existingActors != null && existingActors.contains(key.aktoer_id)) {
            setMessageError(errorMsg, message, KafkaMessageService.STATUS_ERROR);
        } else {
            setMessageError(errorMsg, message, KafkaMessageService.STATUS_WARNING);
        }
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message, String status) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = status;
    }

    private Key getKeyFromBase64(String encodedString) {
        return (Key) System.JSON.deserialize(
            KafkaMessageUtils.base64ULSafeDecode(encodedString).toString(),
            KafkaPDLHandler2.Key.class
        );
    }

    private class Key {
        final String aktoer_id;
        final Boolean tombstone;
    }

    public class PdlListContainsTooManyEntriesException extends Exception {
    }

    public class PdlMissingEntryException extends Exception {
    }

    public class PdlIdentException extends Exception {
    }
}
