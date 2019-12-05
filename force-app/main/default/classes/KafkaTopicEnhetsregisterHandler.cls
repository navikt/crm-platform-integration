public inherited sharing class KafkaTopicEnhetsregisterHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<ERegPayload> ERegPayloads = new List<ERegPayload>();
        for (KafkaMessage__c msg : messages) {
            // Parse JSON payload
            try {
                ERegPayload ereg = (ERegPayload) JSON.deserialize(msg.Message__c, ERegPayload.class);
                ereg.key = msg.Topic__c;
                ERegPayloads.add(ereg);
                msg.IsProcessed__c = true; // TODO: Move this down to actual processing
            } catch (Exception e) {
                msg.Error__c = e.getMessage();
            }
            // TODO: Do actual processing, e.g. create/update Accounts
        }
    }


    private class ERegPayload {
        String key;
        Value value;
    }

    private class Value {
        String name;
    }
}