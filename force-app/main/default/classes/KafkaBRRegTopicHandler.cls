public inherited sharing class KafkaBRRegTopicHandler implements IKafkaMessageHandler {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<BRRegFormat> brRegFormats = new List<BRRegFormat>();
        for (KafkaMessage__c msg : messages) {
            BRRegFormat brreg = (BRRegFormat) JSON.deserialize(msg.Message__c, BRRegFormat.class);
            brreg.key = msg.Topic__c;
            brRegFormats.add(brreg);
        }
        System.debug(brRegFormats);
    }


    private class BRRegFormat {
        String key;
        Value value;
    }

    private class Value {
        String name;
    }
}