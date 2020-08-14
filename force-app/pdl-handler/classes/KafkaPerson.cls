public with sharing class KafkaPerson {

    public String aktoer_id;
    public String identifikasjonsnummer;
    public String fornavn;
    public String mellomnavn;
    public String etternavn;
    public String adressebeskyttelse;
    public List<String> sikkerhetstiltak;
    public String kommunenummer;
    public String region;
    public Boolean doed;

    public static KafkaPerson parse(String json) {
        return (KafkaPerson) System.JSON.deserialize(json, KafkaPerson.class);
    }

}