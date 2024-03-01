/**
 * all the gt-related fields factored out from the previous implementation,
 * KafkaPDLHandler2 ,
 * since they now arrive in separate kafka messages.
 */
public without sharing class KafkaPdlGtHandler implements IKafkaMessageConsumer {

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

        // TODO obviously expand this
        PdlGeografiskTilknytning gt = kafkaPerson.geografiskTilknytning;
        person.INT_GTMunicipalityNumber__c = gt.gtKommune;

        // Ensure that a System User is set as Owner if even if message processing is manually retried by an administrator user
        if (KafkaIntegrationCustomSetting.integrationUserId != null) {
            person.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
        }
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
        List<Person__c> persons = new List<Person__c>();
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Status__c == KafkaMessageService.STATUS_PENDING) {
                Person__c p = createPersonRecord(msg);
                persons.add(p);
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
            }
        }
        List<Database.UpsertResult> urList = Database.upsert(persons, Person__c.INT_ActorId__c, false);
        // TODO check for errors, set status to error if so
    }

    public class PdlGtException extends Exception {
    }
}
