public with sharing class KafkaPerson2 {
    public String aktoerId;
    public List<String> folkeregisterId;
    public List<String> foedselsdato;

    public List<PDL_IdentInformasjon> identer;

    public List<PDL_Navn> navn;

    public List<PDL_FolkeregisterIdentifikator> folkeregisteridentifikator;

    public List<ForelderBarnRelasjoner> familierelasjoner; //Backward compability with the old familierelasjoner.
    public List<ForelderBarnRelasjoner> forelderBarnRelasjoner;
    public class ForelderBarnRelasjoner {
        public String relatertPersonsIdent;
        public String relatertPersonsRolle;
        public String minRolleForPerson;
    }

    public List<String> folkeregisterpersonstatus;
    public List<PDL_InnflyttingTilNorge> innflyttingTilNorge;

    public List<String> adressebeskyttelse;
    public List<PersonJSONFieldObjects.Sikkerhetstiltak> sikkerhetstiltak;
    public Adresser bostedsadresse;
    public Adresser oppholdsadresse;
    public class Adresser {
        public List<Vegadresse> vegadresse;
        public List<Matrikkeladresse> matrikkeladresse;
        public List<UtenlandskAdresse> utenlandskAdresse;
        public List<UkjentBosted> ukjentBosted;
    }

    public class Vegadresse {
        public String adressenavn;
        public String husnummer;
        public String husbokstav;
        public String postnummer;
        public String kommunenummer;
        public String bydelsnummer;
        public String koordinater;
    }

    public class Matrikkeladresse {
        public String kommunenummer;
        public String postnummer;
        public String bydelsnummer;
        public String koordinater;
    }

    public class UtenlandskAdresse {
        public String adressenavnNummer;
        public String bygningEtasjeLeilighet;
        public String postboksNummerNavn;
        public String postkode;
        public String bysted;
        public String regionDistriktOmraade;
        public String landkode;
    }

    public class UkjentBosted {
        public String bostedskommune;
    }

    public List<String> statsborgerskap;
    public List<PDL_Sivilstand> sivilstand;

    public String kommunenummerFraGt;
    public String kommunenummerFraAdresse;
    public String bydelsnummerFraGt;
    public String bydelsnummerFraAdresse;
    public List<String> kjoenn;
    public List<Doedsfall> doedsfall;
    public class Doedsfall {
        public String doedsdato;
        public String master;
    }

    public List<Telefonnummer> telefonnummer;
    public class Telefonnummer {
        public String landskode;
        public String nummer;
        public String prioritet;
    }

    public List<PDL_UtflyttingFraNorge> utflyttingFraNorge;

    public List<String> talesspraaktolk;
    public List<PersonJSONFieldObjects.Fullmakt> fullmakt;
    public List<PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt> vergemaalEllerFremtidsfullmakt;

    public static KafkaPerson2 parse(String json) {
        return (KafkaPerson2) System.JSON.deserialize(json, KafkaPerson2.class);
    }
}
