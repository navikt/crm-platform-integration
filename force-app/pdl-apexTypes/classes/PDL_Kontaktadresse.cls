public with sharing class PDL_Kontaktadresse extends PDL_AdresseType {

    public Datetime gyldigFraOgMed{ get;}
    public Datetime gyldigTilOgMed{ get;}
    public PDL_KontaktadresseType type{ get;}
    public String coAdressenavn{ get;}
    public PDL_Postboksadresse postboksadresse{ get;}
    // public PDL_Vegadresse vegadresse{ get;}
    public PDL_PostadresseIFrittFormat postadresseIFrittFormat{ get;}
    // public PDL_UtenlandskAdresse utenlandskAdresse{ get;}
    public PDL_UtenlandskAdresseIFrittFormat utenlandskAdresseIFrittFormat{ get;}
    // public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    // public PDL_Metadata metadata{ get;}

    public PDL_Kontaktadresse() {

    }
    public enum PDL_KontaktadresseType {
        Innland,
        Utland
    }
}
