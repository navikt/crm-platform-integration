public inherited sharing class KafkaMessageParsingService {

    private IKafkaMessageHandler parser { get; set; }

    public void parseMessage(IKafkaMessageHandler parser, List<KafkaMessage__c> messages) {
        this.parser = parser;
        this.parser.processMessage(messages);
    }

}