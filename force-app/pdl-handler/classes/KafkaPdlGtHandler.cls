/**
 * all the geographic affiliation related fields factored out from the previous
 * implementation, KafkaPDLHandler2 , since they now arrive on separate kafka
 * topics.
 */
public without sharing class KafkaPdlGtHandler implements IKafkaMessageConsumer {

    public final static String GT_TOPIC = KafkaMessageHandlerBinding__mdt.getInstance('PdlGeografiskTilknytning').Topic__c;

    private LoggerUtility logger = new LoggerUtility('PDL');

    /**
     * Handle the idents passed in the kafka message.
     * There is no information on what is historical or not, so:
     *   - ignore actor ids; use the message key instead
     *   - use FNR or DNR to fill in the required Name field
     */
    private void assignIdent(Person__c person, String ident) {
        if(ident.length() == 11) {
            person.Name = ident; // flows to Account.INT_PersonIdent__c
        }
    }

    /**
     * Nulls what may have been set before.
     */
    private static void nullOutAddressFields(Person__c person) {
        person.INT_GTDistrictNumber__c = null;
        person.INT_GTMunicipalityNumber__c = null;
        person.INT_DistrictNumber__c = null;
        person.INT_MunicipalityNumber__c = null;
        person.INT_RegionNumber__c = null;
    }

    /**
     * District includes all the data we need.
     */
    private static void setAddressFromDistrict(Person__c person, PdlGeografiskTilknytning gt) {
        person.INT_GTDistrictNumber__c = gt.gtBydel;
        person.INT_GTMunicipalityNumber__c = gt.gtBydel.left(4);
        person.INT_DistrictNumber__c = person.INT_GTDistrictNumber__c;
        person.INT_MunicipalityNumber__c = person.INT_GTMunicipalityNumber__c;
        person.INT_RegionNumber__c = gt.gtBydel.left(2);
    }

    /**
     * Municipality does not set the district.
     */
    private static void setAddressFromMunicipality(Person__c person, PdlGeografiskTilknytning gt) {
        person.INT_GTMunicipalityNumber__c = gt.gtKommune;
        person.INT_MunicipalityNumber__c = person.INT_GTMunicipalityNumber__c;
        person.INT_RegionNumber__c = gt.gtKommune.left(2);
    }

    /**
     * Transform and map fields from PDL data structure to Person__c SObject
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a person from PDL
     * @return Person Account with initialized fields
     */
    private Person__c personFromKafkaPerson(String actorId, KafkaPersonGT kafkaPerson) {
        Person__c person = new Person__c();
        person.INT_ActorId__c = actorId;
        for(String ident : kafkaPerson.identer) {
            assignIdent(person, ident);
        }
        nullOutAddressFields(person);
        PdlGeografiskTilknytning gt = kafkaPerson.geografiskTilknytning;
        if (gt.gtType == 'BYDEL') {
            // TODO: figure out exactly what sort of granularity we want when
            // logging branching
            setAddressFromDistrict(person, gt);
        } else if (gt.gtType == 'KOMMUNE') {
            setAddressFromMunicipality(person, gt);
        } else if (gt.gtType == 'UDEFINERT') {
        } else if (gt.gtType == 'UTLAND') {
            logger.info('GT from abroad, doing nothing.', null);
        } else {
            logger.error('Not setting GT, unknown gtType.', null);
        }
        //person.INT_GTMunicipalityNumber__c = gt.gtKommune;
        return person;
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for each KafkaMessage
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    @TestVisible
    private Person__c createPersonRecord(KafkaMessage__c message) {
        // This occasionally happens. Seems to be related to historicification
        // of actor ids.
        if (message.CRM_Value__c == null) {
            throw new PdlGtNullValueException('Message value is null.');
        }
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPersonGT kafkaPerson = KafkaPersonGT.parse(decodedValue);
        Person__c person = personFromKafkaPerson(message.CRM_Key__c, kafkaPerson);
        person.INT_LastUpdatedFromPDL__c = message.createdDate;
        return person;
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message, String status) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255);
        message.CRM_Status__c = status;
    }

    /**
     * Fetches Name field of already existing people
     */
    private void rinseNames(Map<String, Person__c> personFromActorid) {
        for (Person__c p : [
                SELECT Name, INT_ActorId__c from Person__c
                WHERE INT_ActorId__c IN :personFromActorid.keySet()
                ]) {
            personFromActorid.get(p.INT_ActorId__c).Name = p.Name;
        }
    }

    /**
     * Save our modified/new persons to the database.
     * May clobber the kafka messages, as they have already been set to
     * Processed, so set them to Error on failure. (Consider doing this the
     * other way around.)
     * @param persons Persons to upsert
     * @param messages references to the messages in the same order as _persons_
     */
    @TestVisible
    private void upsertResult(
        List<Person__c> persons,
        List<KafkaMessage__c> messages
    ) {
        // An error from DML will set only that message to failed,
        // unless the error is caused by a "before insert" hook,
        // in which case the entire batch will fail.
        List<Database.UpsertResult> urList = Database.upsert(persons, Person__c.INT_ActorId__c, false);
        for (Integer i = 0; i < urList.size(); i++) {
            if (!urList[i].isSuccess()) {
                String errorMsg = 'Upsert error:';
                for (Database.Error error : urList[i].getErrors()) {
                    errorMsg += ' * ' + error.getMessage();
                }
                setMessageError(errorMsg, messages[i], KafkaMessageService.STATUS_ERROR);
                logger.error(
                    'Error updating Person__c.\n' +
                    'Kafka key reference: ' +
                    messages[i].CRM_Key__c,
                    null,
                    CRM_ApplicationDomain.domain.CRM
                );
            }
        }
    }

    /**
     * Handle the messages sent.
     * Implements the IKafkaMessageConsumer interface.
     */
    public void processMessages(List<KafkaMessage__c> messages) {
        // see KafkaPdlPersondokumentHandler.processMessages for comments on
        // these maps
        Map<String, Person__c> personFromActorid = new Map<String, Person__c>();
        Map<String, KafkaMessage__c> messageFromActorId = new Map<String, KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                try {
                    Person__c person = createPersonRecord(msg);
                    // If that didn't raise an error, proceed.
                    // Ensure that a System User is set as Owner if even if message
                    // processing is manually retried by an administrator user
                    if (KafkaIntegrationCustomSetting.integrationUserId != null) {
                        person.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
                    }
                    personFromActorid.put(msg.CRM_Key__c, person);
                    messageFromActorId.put(msg.CRM_Key__c, msg);
                    // set to processed; to be changed if upsert fails
                    msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                } catch (Exception e) {
                    // Catch PdlGtNullValueException, PdlGtIdentException, or
                    // whatever else might happen, in order to allow doing the
                    // rest of the batch
                    // Throw Error for now. Consider just raising a warning upon
                    // PdlGtNullValueException.
                    String errorMsg = e.getTypeName() + ': ' + e.getMessage() + ' (' + e.getLineNumber() + ')';
                    setMessageError(errorMsg, msg, KafkaMessageService.STATUS_ERROR);
                    logger.error(
                            'Failed to create person from GT.\n' +
                            'Kafka key reference: ' +
                            msg.CRM_Key__c,
                            null,
                            CRM_ApplicationDomain.domain.CRM
                            );
                }
            }
        }
        // our Name fields may be incorrect due to lacking data about what is
        // historical. so fetch the ones that already exist from the database.
        rinseNames(personFromActorid);
        // create lists of persons to be upserted, and associated kafka messages
        Person__c[] persons = new List<Person__c>();
        KafkaMessage__c[] finalMessages = new List<KafkaMessage__c>();
        for (String actorId : personFromActorid.keySet()) {
            persons.add(personFromActorid.get(actorId));
            finalMessages.add(messageFromActorId.get(actorId));
        }
        upsertResult(persons, finalMessages);
        logger.publish();
    }

    public class PdlGtNullValueException extends Exception {
    }

    public class PdlGtIdentException extends Exception {
    }
}
