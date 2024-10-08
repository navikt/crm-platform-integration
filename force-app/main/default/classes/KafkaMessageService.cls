public with sharing class KafkaMessageService {
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_PROCESSED = 'Processed';
    public static final String STATUS_ERROR = 'Error';
    public static final String STATUS_WARNING = 'Warning';

    private Map<String, IKafkaMessageConsumer> handlerBindings = new Map<String, IKafkaMessageConsumer>();
    private List<KafkaMessage__c> messages;
    private final static Boolean IS_SANDBOX = [SELECT IsSandbox FROM Organization][0].IsSandbox;

    // Before Insert constructor - takes a list of Kafka Messages that don't yet have a record id
    public KafkaMessageService(List<KafkaMessage__c> messages) {
        this.messages = messages;
    }

    /**
     * Maps each topic to its appropriate consumer.
     * In prod, map every Topic__c.
     * In dev, when the topic differs from that in prod, e.g. foo.bar-q2 instead
     * of foo.bar, this topic is specified in SandboxOverrideTopic__c, which
     * then takes precedence.
     */
    private void setupHandlerBindings() {
        for (KafkaMessageHandlerBinding__mdt binding : [
            SELECT Id, Topic__c, SandboxOverrideTopic__c, ApexClass__c
            FROM KafkaMessageHandlerBinding__mdt
        ]) {
            if (IS_SANDBOX && String.isNotBlank(binding.SandboxOverrideTopic__c)) {
                handlerBindings.put(
                    binding.SandboxOverrideTopic__c,
                    (IKafkaMessageConsumer) Type.forName(binding.ApexClass__c).newInstance()
                );
            } else {
                handlerBindings.put(
                    binding.Topic__c,
                    (IKafkaMessageConsumer) Type.forName(binding.ApexClass__c).newInstance()
                );
            }
        }
    }

    /**
     * Sorts messages into their respective topics. Resets the status and error
     * fields, which honestly should probably already be pending and '',
     * respectively.
     */
    private Map<String, List<KafkaMessage__c>> getMessagesByTopic() {
        Map<String, List<KafkaMessage__c>> messagesByTopic = new Map<String, List<KafkaMessage__c>>();
        for (KafkaMessage__c msg : messages) {
            // Reset processing status fields
            msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
            msg.CRM_ErrorMessage__c = '';
            // Build map of messages by topic
            if (messagesByTopic.containsKey(msg.CRM_Topic__c)) {
                messagesByTopic.get(msg.CRM_Topic__c).add(msg);
            } else {
                messagesByTopic.put(msg.CRM_Topic__c, new List<KafkaMessage__c>{ msg });
            }
        }
        return messagesByTopic;
    }

    public void handleMessages() {
        setupHandlerBindings();
        Map<String, List<KafkaMessage__c>> messagesByTopic = getMessagesByTopic();
        List<KafkaMessage__c> messagesToUpdate = new List<KafkaMessage__c>();

        for (String topic : messagesByTopic.keySet()) {
            if (handlerBindings.containsKey(topic)) {
                handlerBindings.get(topic).processMessages(messagesByTopic.get(topic));
            } else {
                for (KafkaMessage__c msg : messagesByTopic.get(topic)) {
                    msg.CRM_ErrorMessage__c = 'No topic binding found';
                    msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
                    messagesToUpdate.add(msg);
                }
            }
        }

        update messages;
    }
}
