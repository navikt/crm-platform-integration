/**
 * Person with only GeografiskTilknytning
 */
public with sharing class KafkaPersonGt {
    public List<String> identer;
    public PdlGeografiskTilknytning geografiskTilknytning;

    public static KafkaPersonGt parse(String json) {
        return (KafkaPersonGt) System.JSON.deserialize(json, KafkaPersonGt.class);
    }
}
