/**
 * all the geographic affiliation related fields factored out from the previous
 * implementation, KafkaPDLHandler2 , since they now arrive on separate kafka
 * topics.
 */
public without sharing class KafkaPdlGtHandler implements IKafkaMessageConsumer {

    public static String GT_TOPIC = KafkaMessageHandlerBinding__mdt.getInstance('PdlGeografiskTilknytning').Topic__c;

    private LoggerUtility logger = new LoggerUtility('PDL');

    private void assignIdent(Person__c p, String s) {
        if(s.length() == 13) {
            p.INT_ActorId__c = s;
        } else if(s.length() == 11) {
            if(Integer.valueOf(s.left(1)) >= 4) {
                p.INT_dnr__c = s;
            } else {
                p.INT_fnr__c = s;
            }
            p.Name = s; // flows to Account.INT_PersonIdent__c
        } else {
            throw new PdlGtException('Unrecognised ident.');
        }
    }

    /**
     * Nulls what may have been set before.
     */
    private static void nullOutFields(Person__c p) {
        p.INT_GTDistrictNumber__c = null;
        p.INT_GTMunicipalityNumber__c = null;
        p.INT_DistrictNumber__c = null;
        p.INT_MunicipalityNumber__c = null;
        p.INT_RegionNumber__c = null;
    }

    /**
     * District includes all the data we need.
     */
    private static void setFieldsFromDistrict(Person__c p, PdlGeografiskTilknytning gt) {
        p.INT_GTDistrictNumber__c = gt.gtBydel;
        p.INT_GTMunicipalityNumber__c = gt.gtBydel.left(4);
        p.INT_DistrictNumber__c = p.INT_GTDistrictNumber__c;
        p.INT_MunicipalityNumber__c = p.INT_GTMunicipalityNumber__c;
        p.INT_RegionNumber__c = gt.gtBydel.left(2);
    }

    /**
     * Municipality does not set the district.
     */
    private static void setFieldsFromMunicipality(Person__c p, PdlGeografiskTilknytning gt) {
        p.INT_GTMunicipalityNumber__c = gt.gtKommune;
        p.INT_MunicipalityNumber__c = p.INT_GTMunicipalityNumber__c;
        p.INT_RegionNumber__c = gt.gtKommune.left(2);
    }

    /**
     * Transform and map fields from PDL data structure to Person__c SObject
     * @param person New Person__c SObject record
     * @param kafkaPerson deserialized object representing a person from PDL
     * @return Person Account with initialized fields
     */
    private Person__c personFromKafkaPerson(KafkaPersonGT kafkaPerson) {
        Person__c person = new Person__c();
        for(String s : kafkaPerson.identer) {
            assignIdent(person, s);
        }
        nullOutFields(person);
        PdlGeografiskTilknytning gt = kafkaPerson.geografiskTilknytning;
        if (gt.gtType == 'BYDEL') {
            // TODO: figure out exactly what sort of granularity we want when
            // logging branching
            logger.info('Setting GT from district', null);
            setFieldsFromDistrict(person, gt);
        } else if (gt.gtType == 'KOMMUNE') {
            logger.info('Setting GT from municipality, clearing district fields', null);
            setFieldsFromMunicipality(person, gt);
        } else if (gt.gtType == 'UDEFINERT') {
            logger.info('Not setting GT from UDEFINERT, clearing all GT fields', null);
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
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPersonGT kafkaPerson = KafkaPersonGT.parse(decodedValue);
        Person__c person = personFromKafkaPerson(kafkaPerson);
        person.INT_LastUpdatedFromPDL__c = message.createdDate;
        return person;
    }

    private void setMessageError(String errorMsg, KafkaMessage__c message, String status) {
        message.CRM_ErrorMessage__c = errorMsg.mid(0, 255);
        message.CRM_Status__c = status;
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
        Map<String, Person__c> personFromActorId = new Map<String, Person__c>();
        Map<String, KafkaMessage__c> messageFromActorId = new Map<String, KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                Person__c p = createPersonRecord(msg);
                // Ensure that a System User is set as Owner if even if message
                // processing is manually retried by an administrator user
                if (KafkaIntegrationCustomSetting.integrationUserId != null) {
                    p.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
                }
                personFromActorId.put(msg.CRM_Key__c, p);
                messageFromActorId.put(msg.CRM_Key__c, msg);
                // set to processed; to be changed if upsert fails
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
            }
        }
        // lists of persons to be upserted and their associated kafka messages
        Person__c[] persons = new List<Person__c>();
        KafkaMessage__c[] finalMessages = new List<KafkaMessage__c>();
        for (String actorId : personFromActorId.keySet()) {
            persons.add(personFromActorId.get(actorId));
            finalMessages.add(messageFromActorId.get(actorId));
        }
        upsertResult(persons, finalMessages);
        logger.publish();
    }

    public class PdlGtException extends Exception {
    }
}
