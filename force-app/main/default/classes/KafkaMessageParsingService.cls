public inherited sharing class KafkaMessageParsingService {

    public static void parseMessage(String jsonString) {
        IKafkaMessageParser parser = new BrregParser();
        parser.processMessage(jsonString);
    }




}