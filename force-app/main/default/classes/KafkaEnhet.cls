public with sharing class KafkaEnhet {
    public String organisasjonsnummer;
    public String navn;
    public Organisasjonsform organisasjonsform;
    public String registreringsdatoEnhetsregisteret;
    public Boolean registrertIMvaregisteret;
    public Naeringskode1 naeringskode1;
    public Integer antallAnsatte;
    public String overordnetEnhet;
    public String oppstartsdato;
    public Beliggenhetsadresse beliggenhetsadresse;

    public class Organisasjonsform {
        public String kode;
        public String beskrivelse;
    }

    public class Beliggenhetsadresse {
        public String land;
        public String landkode;
        public String postnummer;
        public String poststed;
        public String kommune;
        public String kommunenummer;
    }

    public class Naeringskode1 {
        public String beskrivelse;
        public String kode;
    }

    public static List<KafkaEnhet> parse(String json) {
        return (List<KafkaEnhet>) System.JSON.deserialize(json, List<KafkaEnhet>.class);
    }
}