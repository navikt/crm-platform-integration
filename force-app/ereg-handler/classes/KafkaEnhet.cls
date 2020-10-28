public with sharing class KafkaEnhet {

    public String organisasjonsnummer;
    public String navn;
    public Organisasjonsform organisasjonsform;
    public String registreringsdatoEnhetsregisteret;
    public Boolean registrertIMvaregisteret;
    public Naeringskode1 naeringskode1;
    public Naeringskode1 naeringskode2;
    public Naeringskode1 naeringskode3;
    public Integer antallAnsatte;
    public Forretningsadresse forretningsadresse;
    public Beliggenhetsadresse beliggenhetsadresse;
    public Naeringskode1 institusjonellSektorkode;
    public Boolean registrertIForetaksregisteret;
    public Boolean registrertIStiftelsesregisteret;
    public Boolean registrertIFrivillighetsregisteret;
    public Boolean konkurs;
    public Boolean underAvvikling;
    public Boolean underTvangsavviklingEllerTvangsopplosning;
    public String maalform;
    public String overordnetEnhet;
    public String hjemmeside;

    public class Organisasjonsform {
        public String kode;
        public String beskrivelse;
    }

    public class Forretningsadresse {
        public String land;
        public String landkode;
        public String postnummer;
        public String poststed;
        public List<String> adresse;
        public String kommune;
        public String kommunenummer;
    }

    public class Beliggenhetsadresse {
        public String land;
        public String landkode;
        public String postnummer;
        public String poststed;
        public List<String> adresse;
        public String kommune;
        public String kommunenummer;
    }

    public class Naeringskode1 {
        public String beskrivelse;
        public String kode;
    }

    public class Naeringskode2 {
        public String beskrivelse;
        public String kode;
    }

    public class Naeringskode3 {
        public String beskrivelse;
        public String kode;
    }

    public static KafkaEnhet parse(String json) {
        return (KafkaEnhet) System.JSON.deserialize(json, KafkaEnhet.class);
    }
}
