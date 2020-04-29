public interface IKafkaMessageConsumer {
    /**
     * Process messages by executing business logic based on the message payload.
     * Unhandled errors will be caught and stored on the originating AsyncRequest record.
     * The caller context will update the passed in messages after the method has been called. To persist errors
     * on individual KafkaMessage records instead of the originating AsyncRequest record, catch errors in this method
     * and store the error in KafkaMessage CRM_Error__c field
     * @param messages records to be processed
     */
    void processMessages(List<KafkaMessage__c> messages);
}