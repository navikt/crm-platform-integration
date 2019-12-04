public inherited sharing class KafkaBRRegTopicHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<BRRegFormat> brRegFormats = new List<BRRegFormat>();
        for (KafkaMessage__c msg : messages) {
            // Parse JSON payload
            try {
                BRRegFormat brreg = (BRRegFormat) JSON.deserialize(msg.Message__c, BRRegFormat.class);
                brreg.key = msg.Topic__c;
                brRegFormats.add(brreg);
                msg.IsProcessed__c = true; // TODO: Move this down to actual processing
            } catch (Exception e) {
                msg.Error__c = e.getMessage();
            }
            // TODO: Do actual processing, e.g. create/update Accounts
        }
    }


    private class BRRegFormat {
        String key;
        Value value;
    }

    private class Value {
        String name;
    }
}