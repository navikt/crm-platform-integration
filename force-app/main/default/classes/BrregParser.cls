public inherited sharing class BrregParser implements IKafkaMessageParser{

    public static void processMessage(String jsonString) {
        System.debug('In processJSON');
        System.debug(jsonString);
    }

}