/**
 * Created by ohuuse on 22/10/2020.
 */

public without sharing class KafkaPDLHandler_2 implements IKafkaMessageConsumer {

    private static final String PDL_ERROR_STRING = '<UKJENT_FRA_PDL>';
    private static final Map<String, Integer> ADR_BESKYTTELSES_GRADERING = New Map<String, Integer>{'STRENGT_FORTROLIG'=>4, 'STRENGT_FORTROLIG_UTLAND'=>3, 'FORTROLIG'=>2, 'UGRADERT'=>1};

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
        person.INT_FirstName__c = stringValidator(kafkaPerson.Navn[0].fornavn);
        person.INT_MiddleName__c = stringValidator(kafkaPerson.Navn[0].mellomnavn);
        person.INT_LastName__c = stringValidator(kafkaPerson.Navn[0].etternavn);

        // familierelasjoner

        // folkeregisterpersonstatus
        // person.INT_LegalStatus__c = safelyJoinMultiPicklistString(kafkaPerson.folkeregisterpersonstatus);    Not mapping to this field yet (NKS 23.09)

        // InnflytningTilNorge
        person.INT_MovedFromCountry__c = kafkaPerson.innflyttningTilNorge[0].fraflyttingsland;
        person.INT_MovedFromPlace__c = stringValidator(kafkaPerson.innflyttningTilNorge[0].fraflyttingsstedIUtlandet);

        // adressebeskyttelse
        person.INT_Confidential__c = clearanceLevel(kafkaPerson.adressebeskyttelse);

        // sikkerhetstiltak
        // this will be created as a custom object (K64).
//        person.INT_SecurityMeasures__c = safelyJoinMultiPicklistString(kafkaPerson.sikkerhetstiltak[0].beskrivelse);          this is multipicklist values
//        person.INT_SecurityMeasures__c = safelyJoinMultiPicklistString(kafkaPerson.sikkerhetstiltak[0].tiltaksType);          no mapping for tiltaksType
//        person.INT_ValidFromDate__c = stringValidator(kafkaPerson.sikkerhetstiltak[0].gyldigFraOgMed);                        sf field missing INT_ValidFromDate__c
//        person.INT_ValidToDate__c = stringValidator(kafkaPerson.sikkerhetstiltak[0].gyldigTilOgMed);                          sf field missing INT_ValidToDate__c
//        person.INT_NAVContactId__c = stringValidator(kafkaPerson.sikkerhetstiltak[0].kontaktPersonId);                        sf field missing INT_NavContactId__c
//        person.INT_NAVUnit__c = stringValidator(kafkaPerson.sikkerhetstiltak[0].kontaktPersonEnhet);                          sf field missing INT_NAVUnit__c

        // bostedsadresser
        if (kafkaPerson.bostedsadresser.vegadresse.size()>0) {
            person.INT_ResidentialAddress__c = kafkaPerson.bostedsadresser.vegadresse[0].adressenavn + ' ' + kafkaPerson.bostedsadresser.vegadresse[0].husnummer + ' ' + kafkaPerson.bostedsadresser.vegadresse[0].husbokstav;
            person.INT_ResidentialZipCode__c = kafkaPerson.bostedsadresser.vegadresse[0].postnummer;
            person.INT_MunicipalityNumber__c = kafkaPerson.bostedsadresser.vegadresse[0].kommunenummer;                         // something with INT_RegionNumber__c here (G13)?
        } else if (kafkaPerson.bostedsadresser.matrikkeladresse.size()>0) {
            // should we have mapping here? nothing in the PDL_SF mapping i think
        }
//        person.INT_Coordinates__c = kafkaPerson.bostedsadresser.vegadresse[0].koordinater;      missing field INT_Coordinates__c
        person.INT_MunicipalityNumber__c = kafkaPerson.bostedsadresser.ukjentBosted[0].kommunenummer;        //this is grouped with bostedsadresser in the mapping (not an issue but...)

        // oppholdsadresser
        if (kafkaPerson.oppholdsadresser.vegadresse.size()>0) {
            person.INT_TemporaryAddress__c = kafkaPerson.oppholdsadresser.vegadresse[0].adressenavn + ' ' + kafkaPerson.oppholdsadresser.vegadresse[0].husnummer + ' ' + kafkaPerson.oppholdsadresser.vegadresse[0].husbokstav;
            person.INT_TemporaryZipCode__c = kafkaPerson.oppholdsadresser.vegadresse[0].postnummer;
            person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresser.vegadresse[0].kommunenummer;
        } else if (kafkaPerson.oppholdsadresser.utlendskAdresse.size()>0) {
            person.INT_TemporaryAddress__c = kafkaPerson.oppholdsadresser.utlendskAdresse[0].adressenavnNummer
                    + ' ' + kafkaPerson.oppholdsadresser.utlendskAdresse[0].bygningEtasjeLeilighet
                    + ' ' + kafkaPerson.oppholdsadresser.utlendskAdresse[0].postboksNummerNavn
                    + ' ' + kafkaPerson.oppholdsadresser.utlendskAdresse[0].postkode
                    + ' ' + kafkaPerson.oppholdsadresser.utlendskAdresse[0].bysted
                    + ' ' + kafkaPerson.oppholdsadresser.utlendskAdresse[0].regionDistriktOmraade;                                      // max 255 symbols might be an issue
            person.INT_TemporaryCountryCode__c = kafkaPerson.oppholdsadresser.utlendskAdresse[0].landkode;
//            person.INT_TemporaryMunicipalityNumber__c = kafkaPerson.oppholdsadresser.ukjentBosted[0].bostedskommune;            pdl value bostedskommune does not exist. should it be bostedsKommune?
        }

        // statsborgerskap
        person.INT_Citizenships__c = safelyJoinMultiPicklistString(kafkaPerson.statsborgerskap);                                // format: NOR;SVE. is this ok?

        // sivilstand
        person.INT_MaritalStatus__c = kafkaPerson.sivilstand[0].type;
        person.INT_MaritalStatusDate__c = (Date)kafkaPerson.sivilstand[0].gyldigFraOgMed;
//        person.INT_External_Reference__c = kafkaPerson.sivilstand[0].relatertVedSivilstand;                               // field not in sf INT_External_Reference__c

        // kjoenn
        person.INT_Sex__c = kafkaPerson.kjoenn[0];

        // doedsfall
        person.INT_DateOfDeath__c = kafkaPerson.doedsfall[0].doedsdato.length()<2 ? NULL : Date.valueOf(kafkaPerson.doedsfall[0].doedsdato);
        person.INT_IsDeceased__c = kafkaPerson.doedsfall[0].doedsdato != '' ? true : false;

        // telefonnummer
        for (KafkaPerson_2.telefonnummer tlf : kafkaPerson.telefonnummer) {
            person.INT_Phone1__c = tlf.prioritet == '1' ?  tlf.landskode + tlf.nummer : '';
            person.INT_Phone2__c = tlf.prioritet == '2' ?  tlf.landskode + tlf.nummer : '';
        }

        // utflyttingFraNorge
//        person.INT_MovedToCountry__c = kafkaPerson.utflyttingFraNorge[0].tilflyttingsland;                            not sure what we should do if we get multiple list values here. pick the first one?
//        person.INT_MovedToPlace__c = kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet;                         not sure what we should do if we get multiple list values here. pick the first one?

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
    private String safelyJoinMultiPicklistString(List<String> stringsToJoin) {
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
     * Validate field values and if errors are found, throw error to store on the relevant Kafka Message
     * @param kafkaPerson Kafka person to validate
     */
    private void validateValues(KafkaPerson_2 kafkaPerson) {
        List<String> fieldValuesToCheck = new List<String>{
                kafkaPerson.region, kafkaPerson.kommunenummer
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
                || kafkaPerson.innflyttningTilNorge.size()>1
                || kafkaPerson.sikkerhetstiltak.size()>1
                || kafkaPerson.bostedsadresser.vegadresse.size()>1
                || kafkaPerson.bostedsadresser.matrikkeladresse.size()>1
                || kafkaPerson.bostedsadresser.utlendskAdresse.size()>1
                || kafkaPerson.bostedsadresser.ukjentBosted.size()>1
                || kafkaPerson.sivilstand.size()>1
                || kafkaPerson.doedsfall.size()>1
                || kafkaPerson.telefonnummer.size()>1
                || kafkaPerson.utflyttingFraNorge.size()>1
                ) {
            throw new InvalidPDLValueException('"' + PDL_ERROR_STRING + '" found in payload');
        }
    }


    public class InvalidPDLValueException extends Exception {
    }
}