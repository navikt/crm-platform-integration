/**
 * Created by ohuuse on 23/10/2020.
 */

public with sharing class KafkaPerson_2 {

    public String aktoerId;
    public String folkeregisterId;
    public List<Navn> navn;
    public class Navn {
        public String fornavn;
        public String mellomnavn;
        public String etternavn;
    }
    public List<Familierelasjoner> familierelasjoner;
    public class Familierelasjoner {
        public String relatertPersonsIdent;
        public String relatertPersonsRolle;
        public String minRolleForPerson;
    }
    public List<String> folkeregisterpersonstatus;
    public List<InnflyttningTilNorge> innflyttningTilNorge;
    public class InnflyttningTilNorge {
        public String fraflyttingsland;
        public String fraflyttingsstedIUtlandet;
    }
    public List<String> adressebeskyttelse;
    public List<Sikkerhetstiltak> sikkerhetstiltak;
    public class Sikkerhetstiltak {
        public String beskrivelse;
        public String tiltaksType;
        public String gyldigFraOgMed;
        public String gyldigTilOgMed;
        public String kontaktPersonId;
        public String kontaktPersonEnhet;
    }

    public Adresser bostedsadresse;
    public Adresser oppholdsadresse;

    public class Adresser {
        public List<Vegadresse> vegadresse;
        public List<Matrikkeladresse> matrikkeladresse;
        public List<UtlendskAdresse> utlendskAdresse;
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
    public class UtlendskAdresse {
        public String adressenavnNummer;
        public String bygningEtasjeLeilighet;
        public String postboksNummerNavn;
        public String postkode;
        public String bysted;
        public String regionDistriktOmraade;
        public String landkode;
    }
    public class UkjentBosted {
        public String bostedskommune ;
    }
    public List<String> statsborgerskap;
    public List<Sivilstand> sivilstand;
    public class Sivilstand {
        public String type;
        public String gyldigFraOgMed;
        public String relatertVedSivilstand;
    }
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
    public List<UtflyttingFraNorge> utflyttingFraNorge;
    public class UtflyttingFraNorge {
        public String tilflyttingsland;
        public String tilflyttingsstedIUtlandet;
    }
    public List<String> talesspraaktolk;















    public static KafkaPerson_2 parse(String json) {
        return (KafkaPerson_2) System.JSON.deserialize(json, KafkaPerson_2.class);
    }

}