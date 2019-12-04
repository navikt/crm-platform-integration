public with sharing class KafkaMessageService {

    private Map<String, IKafkaMessageConsumer> handlerBindings = new Map<String, IKafkaMessageConsumer>();
    private List<KafkaMessage__c> messages;

    public KafkaMessageService(List<KafkaMessage__c> messages) {
        this.messages = messages;
        for (KafkaMessageHandlerBinding__mdt binding : [SELECT Id, Topic__c, ApexClass__c FROM KafkaMessageHandlerBinding__mdt]) {
            handlerBindings.put(binding.Topic__c, (IKafkaMessageConsumer) Type.forName(binding.ApexClass__c).newInstance());
        }
    }

    public void handleMessages() {
        Map<String, List<KafkaMessage__c>> messagesByTopic = new Map<String, List<KafkaMessage__c>>();
        for (KafkaMessage__c msg : messages) {
            if (messagesByTopic.containsKey(msg.Topic__c)) {
                messagesByTopic.get(msg.Topic__c).add(msg);
            } else {
                messagesByTopic.put(msg.Topic__c, new List<KafkaMessage__c>{
                        msg
                });
            }
        }

        for (String topic : messagesByTopic.keySet()) {
            if (handlerBindings.containsKey(topic)) {
                handlerBindings.get(topic).processMessages(messagesByTopic.get(topic));
            } else {
                for (KafkaMessage__c msg : messagesByTopic.get(topic)) {
                    msg.Error__c = 'No topic binding found';
                }
            }
        }
    }

}