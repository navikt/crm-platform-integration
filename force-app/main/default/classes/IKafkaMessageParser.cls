public interface IKafkaMessageParser {

    void processMessage(String jsonString);

}