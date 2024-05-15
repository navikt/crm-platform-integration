/**
 * Handles messages from a filtered pdl-persondokument-{,tagged-}v1 topic.
 * Should do what KafkaPDLHandler2 previously did to the messages posted by
 * the intermediate nks-sf-pdl app.
 */
public without sharing class KafkaPdlPersondokumentHandler implements IKafkaMessageConsumer {

    public static String PD_TOPIC = KafkaMessageHandlerBinding__mdt.getInstance('PdlPersondokumentHandler').Topic__c;

    @TestVisible
    private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';

    /**
     * Get some transformation into an integer, so information can be hidden
     * based on whether or not this integer is greater than some constant.
     * Consider doing something more sensible.
     */
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

    private Set<String> existingActors = new Set<String>();

    private LoggerUtility logger = new LoggerUtility('PDL');

    /**
     * Gets existing INT_GT... fields from the database.
     */
    private void fetchGeografiskTilknytning(
        Map<String, Person__c> gtFromActorId, List<KafkaMessage__c> messages
    ) {
        List<String> idList = new List<String>();
        for (KafkaMessage__c msg : messages) {
            idList.add(msg.CRM_Key__c);
        }
        Person__c[] people = [
            SELECT INT_ActorId__c, INT_GTDistrictNumber__c, INT_GTMunicipalityNumber__c
            FROM Person__c
            WHERE INT_ActorId__c in :idList
        ];
        for (Person__c p : people) {
            gtFromActorId.put(p.INT_ActorId__c, p);
        }
    }

    /**
     * Validates that the Kafka Message is not older than the last PDL Update on
     * the Person.
     * If a new person is a tombstone, mark it not to be imported.
     * Tombstones are not explicitly named in the message key, but are
     * distinguished by a _null_ message value.
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
            String actorId = msg.CRM_Key__c;
            Boolean isTombstone = msg.CRM_Value__c == null;
            // Lists of key values which match order of kafka messages
            idList.add(actorId);
            tombList.add(isTombstone);
            // A Set of idents with tombstones from kafka messages
            if (isTombstone) {
                tombSet.add(actorId);
            }
        }
        for (Person__c p : [
            SELECT INT_ActorId__c, INT_LastUpdatedFromPDL__c, INT_IsHasTombstone__c
            FROM Person__c
            WHERE INT_ActorId__c IN :idList
        ]) {
            if (p.INT_IsHasTombstone__c) {
                // A Set of idents which already has tombstones
                personTombSet.add(p.INT_ActorId__c);
            }
            // A List with ident for existing persons
            personIdList.add(p.INT_ActorId__c);
            // A List of Update Datetime values (same order as personIdList)
            updatedList.add(p.INT_LastUpdatedFromPDL__c);
        }
        for (Integer i = 0; i < personIdList.size(); i++) {
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
                    'There exists more than one record for Id. (Split/merge.)',
                    messages[i],
                    KafkaMessageService.STATUS_ERROR
                );
            } else if (personTombSet.contains(idList[i])) {
                //when person already exists and has tombstone
                setMessageError('Trying update Tombstone.', messages[i], KafkaMessageService.STATUS_WARNING);
            } else if (updatedMap.containsKey(idList[i]) && (messages[i].createdDate < updatedMap.get(idList[i]))) {
                //when person exists and has more recent update
                setMessageError(
                    'Trying to update a newer record. Skip update.',
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
                    'Trying to insert Tombstone. Skip insert.',
                    messages[i],
                    KafkaMessageService.STATUS_PROCESSED
                );
            }
        }
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for
     * each KafkaMessage
     * Quite similar to PDL_API_Query.makePersonFromResponse.
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    private Person__c createPersonRecord(
        KafkaMessage__c message, Person__c gtPerson
    ) {
        Person__c person = new Person__c(
            INT_IsHasTombstone__c = String.isBlank(message.CRM_Value__c),
            INT_ActorId__c = message.CRM_Key__c,
            INT_LastUpdatedFromPDL__c = message.createdDate
            );
        // If tombstone and no payload, clear data for person except idents.
        if (true == person.INT_IsHasTombstone__c && String.isBlank(message.CRM_Value__c)) {
            emptyTombstonePerson(person);
            return person;
        }
        emptyPersonFieldValues(person);
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        // Fail loudly when deserialization goes wrong.
        KafkaPerson3 kafkaPerson;
        try {
            kafkaPerson = KafkaPerson3.parse(decodedValue);
        } catch (JSONException e) {
            throw new PdlIdentException('Failed to parse kafka person: ' +
                e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')');
        }
        validateListSizes(kafkaPerson);
        person = mapFieldValues(person, kafkaPerson, gtPerson);
        return person;
    }

    /**
     * Fetches all non-historical entries.
     * Returns entries where metadata is
     *  - null (implicitly active)
     *  - explicitly not historical
     * Note: seems each element of the returned list has to be cast separately.
     */
    private static PdlObject[] getAllActive(PdlObject[] pos) {
        PdlObject[] ret = new List<PdlObject>();
        for(PdlObject po : pos) {
            if(!(po.metadata?.historisk ?? false)) {
                ret.add(po);
            }
        }
        return ret;
    }

    /**
     * Like getAllActive but returns:
     *   - null instead of an empty list.
     *   - a serialized string instead of a list of objects.
     */
    private static String getSerializedActiveOrNull(PdlObject[] pos) {
        PdlObject[] activePos = getAllActive(pos);
        return activePos.size() > 0 ? JSON.serialize(activePos) : null;
    }

    /**
     * Fetches the first non-historical entry out of a list of entries.
     * Similar to getAllActive, but returns after the first match.
     * Occasionally there may be multiple valid entries, e.g. one from FREG, one
     * from PDL.  Handle that if it becomes necessary.
     */
    private static PdlObject getFirstActiveOrNull(PdlObject[] pos) {
        for(PdlObject po : pos) {
            if(!(po.metadata?.historisk ?? false)) {
                return po;
            }
        }
        return null;
    }

    /**
     * Set date (or year) of birth.
     * Takes Date or Integer, sets String.
     */
    private static void setDateOfBirth(Person__c person, PdlHentperson hentPerson) {
        PdlFoedsel foedsel = (PdlFoedsel)getFirstActiveOrNull(hentPerson.foedsel);
        if (foedsel?.foedselsdato != null) {
            DateTime dob = foedsel.foedselsdato; // hack; Date lacks format
            person.INT_DateOfBirth__c = dob.format('yyyy-MM-dd');
        } else if(foedsel?.foedselsaar != null) {
            person.INT_DateOfBirth__c = '' + foedsel.foedselsaar;
        }
    }

    /**
     * Sets death and optionally date of death.
     * Multiple results from multiple masters possible.
     * No _historisk_ entries should occur, so no need to filter first.
     */
    private static void setDeath(Person__c person, PdlHentperson hentPerson) {
        if (hentPerson.doedsfall.size() > 0) {
            person.INT_DateOfDeath__c = getBestDateOfDeath(hentPerson.doedsfall);
            person.INT_IsDeceased__c = true; //If we got any records return true even if we don't have a date.
        }
    }

    /**
     * Sets up to two phone numbers.
     */
    private static void setPhoneNumbers(Person__c person, PdlHentperson hentPerson) {
        PdlObject[] numbers = getAllActive(hentPerson.telefonnummer);
        for (PdlObject tlfObj : numbers) {
            PdlTelefonnummer tlf = (PdlTelefonnummer)tlfObj;
            if (tlf.prioritet == 1) {
                person.INT_Phone1__c = tlf.landskode + tlf.nummer;
            }
            if (tlf.prioritet == 2) {
                person.INT_Phone2__c = tlf.landskode + tlf.nummer;
            }
        }
    }

    /**
     * Create a readable string from a coordinate object.
     * Note: coordinates are currently useless, but PDL may implement them
     * in the future.
     */
    private String formatCoordinates(PDL_Koordinater k) {
        return String.format('x={0}, y={1}, z={2}', new List<Object>{
                k.x,
                k.y,
                k.z});
    }

    /**
     * Sets the address according to the priority seen within the method. Also
     * sets municipality and district numbers, as long as they would not
     * override these numbers from GT, which has a higher priority.
     */
    @TestVisible
    private void setAddressFortroligOrUgradert(Person__c person, PdlHentperson hentPerson) {
        // bostedsadresser
        // assumption: vegadresse has first pri, then ukjentbosted...
        PdlBostedsadresse bo = (PdlBostedsadresse)getFirstActiveOrNull(hentPerson.bostedsadresse);
        if (bo?.vegadresse != null) {
            person.INT_ResidentialAddress__c = addressCreator(
                new List<String>{
                    bo.vegadresse.adressenavn,
                    bo.vegadresse.husnummer,
                    bo.vegadresse.husbokstav
                }
            );
            person.INT_ResidentialZipCode__c = bo.vegadresse.postnummer;
            person.INT_AddressMunicipalityNumber__c = bo.vegadresse.kommunenummer;
            person.INT_AddressDistrictNumber__c = bo.vegadresse.bydelsnummer;
            person.INT_Coordinates__c = formatCoordinates(bo.vegadresse.koordinater);
        }
        else if (bo?.matrikkeladresse != null) {
            person.INT_ResidentialZipCode__c = bo.matrikkeladresse.postnummer;
            person.INT_AddressMunicipalityNumber__c = bo.matrikkeladresse.kommunenummer;
            person.INT_AddressDistrictNumber__c = bo.matrikkeladresse.bydelsnummer;
            person.INT_Coordinates__c = formatCoordinates(bo.matrikkeladresse.koordinater);
        }
        // ...PDL skal til enhver tid kun ha en gyldig bostedsadresse per
        // person. Hver gang en ny bostedsadresse blir registrert så vil den
        // forrige bli historisk. Norsk bostedsadresse vil alltid ha Freg som
        // master.  Utenlandsk bostedsadresse vil alltid ha PDL som master.
        // Personer som er registrert som døde skal ikke kunne ha en
        // bostedsadresse.
        // ...
        // At PDL har en utenlandsk bostedsadresse betyr at NAV har mottatt en
        // adresse av den typen fra en utenlandsk myndighet. Det betyr ikke at
        // det er gjort en vurdering i NAV av hvor en person skal regnes som
        // bosatt.
        // ...
        // Personer med en gyldig bostedsadresse i Norge, kan ikke bli
        // registrert med en utenlandsk bostedsadresse. Da må den norske
        // adressen først opphøres i Folkeregisteret.
        // ...TODO: pull in the foreign address, probably

        // oppholdsadresser
        // assumption: vegadresse has first pri, then utenlandskAdresse, then ukjentbosted
        PdlOppholdsadresse opphold = (PdlOppholdsadresse)getFirstActiveOrNull(hentPerson.oppholdsadresse);
        if (opphold?.vegadresse != null) {
            person.INT_TemporaryAddress__c = addressCreator(
                new List<String>{
                    opphold.vegadresse.adressenavn,
                    opphold.vegadresse.husnummer,
                    opphold.vegadresse.husbokstav
                }
            );
            person.INT_TemporaryZipCode__c = opphold.vegadresse.postnummer;
            person.INT_TemporaryMunicipalityNumber__c = opphold.vegadresse.kommunenummer;
            person.INT_TemporaryCoordinates__c = formatCoordinates(opphold.vegadresse.koordinater);
        } else if (opphold?.matrikkeladresse != null) {
            person.INT_TemporaryZipCode__c = opphold.matrikkeladresse.postnummer;
            person.INT_TemporaryMunicipalityNumber__c = opphold.matrikkeladresse.kommunenummer;
            person.INT_TemporaryCoordinates__c = formatCoordinates(opphold.matrikkeladresse.koordinater);
        } else if (opphold?.utenlandskAdresse != null) {
            person.INT_TemporaryAddress__c = addressCreator(
                new List<String>{
                    opphold.utenlandskAdresse.adressenavnNummer,
                    opphold.utenlandskAdresse.bygningEtasjeLeilighet,
                    opphold.utenlandskAdresse.postboksNummerNavn,
                    opphold.utenlandskAdresse.postkode,
                    opphold.utenlandskAdresse.bysted,
                    opphold.utenlandskAdresse.regionDistriktOmraade
                }
            ); // max 255 symbols might be an issue
            person.INT_TemporaryCountryCode__c = opphold.utenlandskAdresse.landkode.left(3);
        } else if (opphold?.ukjentBosted != null) {
            person.INT_TemporaryMunicipalityNumber__c = opphold.ukjentBosted.bostedskommune;
        }
    }

    /**
     * Sets the address, if appropriate.
     * If the clearance level has increased, there should be an UDEFINERT
     * message on the geografisk tilknytning topic that lets the GT handler
     * clear whatever GT fields are set.
     */
    @TestVisible
    private void setAddress(Person__c person, PdlHentperson hentPerson, Person__c gtPerson) {
        String clearance = clearanceLevel(getAllActive(hentPerson.adressebeskyttelse));
        if (ADR_BESKYTTELSES_GRADERING.get(clearance) <= 2) {
            setAddressFortroligOrUgradert(person, hentPerson);
            setMunicipalityAndOrDistrict(person, gtPerson);
        }
    }

    /**
     * Sets municipality and/or district number.
     * Prioritize GT, only use the hentPerson address if there is no better
     * source.
     * @param p person to be inserted
     * @param gtPerson existing person, may be null
     */
    private void setMunicipalityAndOrDistrict(Person__c p, Person__c gtPerson) {
        if (gtPerson?.INT_GTDistrictNumber__c != null) {
            logger.info('setting municipality and district from gt district', null);
            p.INT_GTDistrictNumber__c = gtPerson.INT_GTDistrictNumber__c;
            p.INT_DistrictNumber__c = p.INT_GTDistrictNumber__c;
            p.INT_MunicipalityNumber__c = p.INT_GTDistrictNumber__c.left(4);
        }
        else if (gtPerson?.INT_GTMunicipalityNumber__c != null) {
            logger.info('setting municipality from gt municipality', null);
            p.INT_GTMunicipalityNumber__c = gtPerson.INT_GTMunicipalityNumber__c;
            p.INT_MunicipalityNumber__c = p.INT_GTMunicipalityNumber__c;
        }
        else {
            logger.info('setting municipality and district from hentPerson', null);
            p.INT_DistrictNumber__c = p.INT_AddressDistrictNumber__c;
            p.INT_MunicipalityNumber__c = p.INT_AddressMunicipalityNumber__c;
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
     * @param deaths list deaths. _historisk_ is not relevant here. [0]
     * @return Date PDL-date if found, otherwise folkeregister-date, otherwise
     * null.
     */
    @TestVisible
    private static Date getBestDateOfDeath(List<PdlDoedsfall> deaths) {
        Map<String, Date> dateAccordingTo = new Map<String, Date>();
        for (PdlDoedsfall death : deaths) {
            dateAccordingTo.put(death.metadata.master.toUpperCase(), Date.valueOf(death.doedsdato));
        }
        if (dateAccordingTo.containsKey('PDL')) {
            return dateAccordingTo.get('PDL');
        }
        return dateAccordingTo.get('FREG'); // null if key does not exist
    }

    /**
     * Safely transform spoken language interpreter information into string
     * compatible with multipicklist-fields.
     * FKA talespraaktolk. (misleading name, should have been called
     * talespraaktolkbehov.)
     * When non-null, person needs an interpreter, and the non-null value is
     * a list of the languages for which an interpreter is required.
     * @param comms Collection of facilitated communication
     * @return null or strings joined with ';'
     * TODO: write test for multiple of these
     */
    @TestVisible
    private static String interpreterLanguagesString(PdlObject[] comms) {
        String[] interpreterLanguages = new List<String>();
        for (PdlObject commObj : comms) {
            PdlTilrettelagtkommunikasjon comm = (PdlTilrettelagtkommunikasjon)commObj;
            if (comm.talespraaktolk != null) {
                interpreterLanguages.add(comm.talespraaktolk.spraak);
            }
        }
        if (interpreterLanguages.size() == 0) {
            return null;
        }
        return String.join(interpreterLanguages, ';');
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

    /**
     * Joins a list of strings with a single space between each nonempty string.
     * Caps output at 255 symbols.
     */
    @TestVisible
    private static String addressCreator(List<String> addressFields) {
        String addressString = '';
        for (String addressField : addressFields) {
            if (String.isNotBlank(addressField)) {
                addressString += addressField + ' ';
            }
        }
        return addressString.removeEnd(' ').left(255);
    }

    /**
     * Reduce the given list of address protections to just the one with the
     * strictest security criteria. If none is specified, default to UGRADERT.
     * @param values
     * @return The list value with the strictest security criteria
     */
    private String clearanceLevel(List<PdlObject> values) {
        Integer grade, maxGrade = 0;
        String gradeAsString, returnGrade = 'UGRADERT';
        for (PdlObject protObj : values) {
            PdlAdressebeskyttelse protection = (PdlAdressebeskyttelse)protObj;
            gradeAsString = protection.gradering.name();
            grade = ADR_BESKYTTELSES_GRADERING.get(gradeAsString);
            if (grade > maxGrade) {
                maxGrade = grade;
                returnGrade = gradeAsString;
            }
        }
        return returnGrade;
    }

    /**
     * Validate list sizes and if errors are found, throw exception.
     * This prevents the person from being saved, and the exception is caught
     * and stored on the relevant Kafka Message as a warning, info, error,
     * whatever.
     * @param kafkaPerson Kafka person to validate
     */
    private void validateListSizes(KafkaPerson3 kafkaPerson) {
        PdlHentperson hp = kafkaPerson.hentPerson;
        KafkaPerson3.HentIdenter hentIdenter = kafkaPerson.hentIdenter;

        List<String> objectsFailingValidation = new List<String>();
        if(hentIdenter.identer == null) {
            if (hp.folkeregisteridentifikator.size() == 0) { throw new PdlMissingEntryException('No folkeregisteridentifikator found'); }
            if (hp.folkeregisterpersonstatus.size() == 0) { throw new PdlMissingEntryException('No folkeregisterpersonstatus found'); }
        } else {
            if (hentIdenter.identer.size() == 0) { throw new PdlMissingEntryException('No idents found'); }
        }
        if (hp.navn.size() == 0) { throw new PdlMissingEntryException('No name found'); }
        if (hp.navn[0].etternavn == null) {throw new PdlMissingEntryException('No etternavn found'); }
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
                CRM_ApplicationDomain.domain.CRM
            );
        }
        return null;
    }

    /**
     * @param citizenships PdlStatsborgerskap (list)
     *
     * @return country names joined with ';'
     */
    @TestVisible
    private String createCitizenshipString(List<PdlStatsborgerskap> citizenships) {
        String[] citizenshipStrings = new List<String>();
        for (PdlStatsborgerskap citizenship : citizenships) {
            citizenshipStrings.add(getCountryNameFromIso(citizenship.land));
        }
        return String.join(citizenshipStrings, ';');
    }

    @TestVisible
    /**
     * Sets ident based on both HentIdenter and HentPerson:
     * - NPID from HentIdenter
     * - _not_ FNR from HentIdenter, for whatever reason
     * - FNR from HentPerson, overrides the above
     * - DNR from HentPerson
     * Throws error unless ident lists from both HentIdenter and HentPerson
     * exist; they can be empty, but not null.
     */
    private static void setIdents(Person__c person, KafkaPerson3 kp) {
        PDL_IdentInformasjon[] identer = kp.hentIdenter.identer;
        PdlFolkeregisteridentifikator[] fregIdenter = kp.hentPerson?.folkeregisteridentifikator;
        if (identer != null && identer.isEmpty() == false) {
            person.INT_NPID__c = Pdl_IdentUtility.getIdentsFromList(identer).npid;
        } else {
            throw new PdlIdentException('Not able to set person idents from Kafka: Missing identer.');
        }
        if (fregIdenter != null) {
            //person.INT_fnr__c = Pdl_IdentUtility.getIdentsFromList(identer).fnr;
            setFolkeregisterIdents(person, fregIdenter);
        } else {
            throw new PdlIdentException('Not able to set person idents from Kafka: Missing folkeregisteridentifikator.');
        }
    }

    private static void assignFnrIfAppropriate(Person__c p, PdlFolkeregisteridentifikator id) {
        if (id.type == PDL_IdentType.FNR && !id.metadata.historisk && id.status == PDL_IdentStatus.I_BRUK) {
            p.INT_fnr__c = id.identifikasjonsnummer;
        }
    }

    private static void assignDnrIfAppropriate(Person__c p, PdlFolkeregisteridentifikator id) {
        if (id.type == PDL_IdentType.DNR && (String.isBlank(p.INT_dnr__c) || !id.metadata.historisk)) {
            p.INT_dnr__c = id.identifikasjonsnummer;
        }
    }

    /**
     * Sets idents. Based on the same function in KafkaPDLHandler2.
     */
    private static void setFolkeregisterIdents(
        Person__c person,
        PdlFolkeregisteridentifikator[] identifiers
    ) {
        for (PdlFolkeregisteridentifikator id : identifiers) {
            if (String.isNotBlank(id.identifikasjonsnummer)) { // when is this blank?
                assignFnrIfAppropriate(person, id);
                assignDnrIfAppropriate(person, id);
            }
        }
    }

    /**
     * Sets the Name field of the sObject to a valid identifier.
     * Not to be confused with the first name or last name.
     * Priority: FOLKEREGISTERIDENT, NPID
     * See https://confluence.adeo.no/display/PDL/NPID+-+NAVs+personidentifikator
     * If the list does not include valid idents, throws an exception.
     */
    @TestVisible
    private static void setNameField(Person__c person, KafkaPerson3.HentIdenter hentIdenter) {
        List<PDL_IdentInformasjon> identer = new List<PDL_IdentInformasjon>(hentIdenter.identer);
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
            throw new PdlIdentException('Unable to set either folkeregisterident or NPID from Kafka');
    }

    /**
     * Sets empty value for all Person__c fields set by this handler. Ensures
     * that e.g.  INT_DateOfDeath__c is removed when it has previously been
     * erroneously set — and then corrected by creating a person document that
     * does not contain a date of death.
     * @param person record to modify
     * TODO: ensure we haven't missed anything.
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
            // No longer set by this handler:
            //'INT_GTDistrictNumber__c',
            //'INT_GTMunicipalityNumber__c',
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

    /**
     * Let's make errors as complicated as possible. This function sets
     * CRM_Status__c to Error if the actor ID exists, otherwise it sets it to
     * Warning, for some reason.
     */
    private void setMessageError(String errorMsg, KafkaMessage__c message) {
        String aktoer_id = message.CRM_Key__c;
        if (existingActors != null && existingActors.contains(aktoer_id)) {
            setMessageError(errorMsg, message, KafkaMessageService.STATUS_ERROR);
        } else {
            setMessageError(errorMsg, message, KafkaMessageService.STATUS_WARNING);
        }
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message, String status) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255); //Handle if the total error message exceeds 255 characters
        message.CRM_Status__c = status;
    }

    /**
     * Transforms and map fields to Person__c from KafkaPerson3
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a PersonDokument
     * @return Person Account with initialized fields
     */
    private Person__c mapFieldValues(
        Person__c person, KafkaPerson3 kafkaPerson, Person__c gtPerson
    ) {
        KafkaPerson3.HentIdenter hentIdenter = kafkaPerson.hentIdenter;
        PdlHentperson hentPerson = kafkaPerson.hentPerson;
        // Required fields
        setIdents(person, kafkaPerson);
        setNameField(person, hentIdenter);
        // More or less direct mappings. grab the first non-historical field.
        PdlNavn navn = (PdlNavn)getFirstActiveOrNull(hentPerson.navn);
        person.INT_FirstName__c = navn.fornavn ?? '';
        person.INT_MiddleName__c = navn.mellomnavn ?? '';
        person.INT_LastName__c = navn.etternavn ?? '';
        person.INT_LegalStatus__c = ((PdlFolkeregisterpersonstatus)getFirstActiveOrNull(hentPerson.folkeregisterpersonstatus))?.status;
        PdlInnflyttingtilnorge innflytting = (PdlInnflyttingtilnorge)getFirstActiveOrNull(hentPerson.innflyttingTilNorge);
        person.INT_MovedFromCountry__c = getCountryIdFromIso(innflytting?.fraflyttingsland);
        person.INT_MovedFromPlace__c = innflytting?.fraflyttingsstedIUtlandet;
        person.INT_Confidential__c = clearanceLevel(getAllActive(hentPerson.adressebeskyttelse));
        PdlSivilstand sivilstand = (PdlSivilstand)getFirstActiveOrNull(hentPerson.sivilstand);
        person.INT_MaritalStatus__c = sivilstand?.type.name();
        person.INT_MaritalStatusDate__c = sivilstand?.gyldigFraOgMed;
        person.INT_MaritalRelation__c = sivilstand?.relatertVedSivilstand;
        person.INT_Sex__c = ((PdlKjoenn)getFirstActiveOrNull(hentPerson.kjoenn))?.kjoenn.name();
        PdlUtflyttingfranorge emigration = (PdlUtflyttingfranorge)getFirstActiveOrNull(hentPerson.utflyttingFraNorge);
        person.INT_MovedToCountry__c = getCountryIdFromIso(emigration?.tilflyttingsland);
        person.INT_MovedToPlace__c = emigration?.tilflyttingsstedIUtlandet;
        // Serialized fields
        person.INT_SecurityMeasures__c = JSON.serialize(getAllActive(hentPerson.sikkerhetstiltak));
        person.INT_PowerOfAttorney__c = getSerializedActiveOrNull(hentPerson.fullmakt);
        person.INT_GuardianshipOrFuturePowerOfAttorney__c = getSerializedActiveOrNull(
            hentPerson.vergemaalEllerFremtidsfullmakt);
        // Fancy mappings
        setDateOfBirth(person, hentPerson);
        setAddress(person, kafkaPerson.hentPerson, gtPerson);
        person.INT_Citizenships__c = createCitizenshipString(hentPerson.statsborgerskap);
        person.INT_SpokenLanguageIntepreter__c = interpreterLanguagesString(hentPerson.tilrettelagtKommunikasjon);
        setDeath(person, hentPerson);
        setPhoneNumbers(person, hentPerson);
        // Ensure that a System User is set as Owner if even if message processing is manually retried by an administrator user
        if (KafkaIntegrationCustomSetting.integrationUserId != null) {
            person.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
        }
        return person;
    }

    /**
     * Process messages. Catch various exceptions and then warn or error (i.e.
     * set CRM_Status__c on the KafkaMessage__c) according to some criteria
     * which seem to be the following:
     *   - any PdlIdentException should be treated like an error
     *   - any other Exception is:
     *     - error, if person already exists
     *     - warning, if person doesn't exist
     */
    public void processMessages(List<KafkaMessage__c> messages) {
        // map for storing gt info if it already exists
        Map<String, Person__c> gtFromActorId = new Map<String, Person__c>();
        // maps to be set only after successful person creation.
        // if multiple messages in the same batch share an actor id, they are
        // guaranteed™ to be in the correct order, so simply process them in
        // order and map the actor id to the latest message and created person.
        Map<String, Person__c> personFromActorId = new Map<String, Person__c>();
        Map<String, KafkaMessage__c> messageFromActorId = new Map<String, KafkaMessage__c>();
        // If we have a message where the created date is older than last
        // updated, set it to error so that we can investigate it.  If we have a
        // tombstone without a person in Salesforce, set it to processed.
        // clobbers _messages_ in the sense that its CRM_Status__c may change.
        checkLastUpdatedAndTombStones(messages);
        // If we have INT_GT... fields already saved, we would like to keep them.
        fetchGeografiskTilknytning(gtFromActorId, messages);
        for (KafkaMessage__c msg : messages) {
            // exclude the ones modified by checkLastUpdatedAndTombStones
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                try {
                    Person__c person = createPersonRecord(msg, gtFromActorId.get(msg.CRM_Key__c));
                    // if success, then:
                    personFromActorId.put(person.INT_ActorId__c, person);
                    messageFromActorId.put(person.INT_ActorId__c, msg);
                    msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } catch (PdlIdentException e) {
                    // big mistake.
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg, KafkaMessageService.STATUS_ERROR);
                    logger.error(
                        'Caught PdlIdentException when attempting to create Person__c:\n' +
                        e.getMessage() +
                        '\nKafka key reference: ' +
                        msg.CRM_Key__c,
                        null
                    );
                } catch (Exception e) {
                    // big mistake if person already exists, otherwise small mistake.
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg);
                    if (msg.CRM_Status__c == KafkaMessageService.STATUS_ERROR) {
                        logger.error(
                            'Caught unknown exception when attempting to create Person__c.\n' +
                            'Kafka key reference: ' +
                            msg.CRM_Key__c,
                            null,
                            CRM_ApplicationDomain.domain.CRM
                        );
                    } else if (msg.CRM_Status__c == KafkaMessageService.STATUS_WARNING) {
                        logger.warning(
                            'Warning creating Person__c from PDL Kafka message. ' +
                            '\nKafka key reference: ' +
                            msg.CRM_Key__c,
                            null,
                            CRM_ApplicationDomain.domain.CRM
                        );
                    }
                }
            }
        }
        // create person list for upsertion and message list with matching
        // indices
        List<Person__c> personList = new List<Person__c>();
        List<KafkaMessage__c> messageList = new List<KafkaMessage__c>();
        for (String actorId : personFromActorId.keySet()) {
            personList.add(personFromActorId.get(actorId));
            messageList.add(messageFromActorId.get(actorId));
        }
        // An error from DML will set only that message to failed,
        // unless the error is caused by a "before insert" hook,
        // in which case the entire batch will fail.
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
                        CRM_ApplicationDomain.domain.CRM
                    );
                } else if (messageList[i].CRM_Status__c == KafkaMessageService.STATUS_WARNING) {
                    logger.warning(
                        'Warning updating Person__c.' +
                        '\n Kafka key reference: ' +
                        messageList[i].CRM_Key__c,
                        null,
                        CRM_ApplicationDomain.domain.CRM
                    );
                }
            }
        }
        logger.publish();
    }

    public class PdlMissingEntryException extends Exception {
    }

    public class PdlIdentException extends Exception {
    }
}
