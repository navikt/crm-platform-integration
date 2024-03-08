/**
 * all the gt-related fields factored out from the previous implementation,
 * KafkaPDLHandler2 ,
 * since they now arrive in separate kafka messages.
 */
public without sharing class KafkaPdlGtHandler implements IKafkaMessageConsumer {

    private LoggerUtility logger;

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

    private static void setFieldsFromDistrict(Person__c p, PdlGeografiskTilknytning gt) {
        p.INT_GTDistrictNumber__c = gt.gtBydel;
        p.INT_GTMunicipalityNumber__c = gt.gtBydel.left(4);
        p.INT_DistrictNumber__c = p.INT_GTDistrictNumber__c;
        p.INT_MunicipalityNumber__c = p.INT_GTMunicipalityNumber__c;
        p.INT_RegionNumber__c = gt.gtBydel.left(2);
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
        PdlGeografiskTilknytning gt = kafkaPerson.geografiskTilknytning;
        if (gt.gtType == 'BYDEL') {
            logger.info('Setting GT from district', null);
            setFieldsFromDistrict(person, gt);
        } else {
            logger.error('Not setting GT, wtf?', null);
        }
        //person.INT_GTMunicipalityNumber__c = gt.gtKommune;
        return person;
    }

    /**
     * Orchestrate deserialization, transformation, and Person__c creation for each KafkaMessage
     * @param message integration record inserted by the integration user
     * @return Initialized Person Account ready for DML
     */
    private Person__c createPersonRecord(KafkaMessage__c message) {
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaPersonGT kafkaPerson = KafkaPersonGT.parse(decodedValue);
        Person__c person = personFromKafkaPerson(kafkaPerson);
        person.INT_LastUpdatedFromPDL__c = message.createdDate;
        // ...
        return person;
    }

    public void processMessages(List<KafkaMessage__c> messages) {
        logger = new LoggerUtility('PDL');
        List<Person__c> persons = new List<Person__c>();
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                Person__c p = createPersonRecord(msg);
                // Ensure that a System User is set as Owner if even if message
                // processing is manually retried by an administrator user
                if (KafkaIntegrationCustomSetting.integrationUserId != null) {
                    p.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
                }
                persons.add(p);
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
            }
        }
        List<Database.UpsertResult> urList = Database.upsert(persons, Person__c.INT_ActorId__c, false);
        // TODO check for errors, set status to error if so
        logger.publish();
    }

    public class PdlGtException extends Exception {
    }
}
