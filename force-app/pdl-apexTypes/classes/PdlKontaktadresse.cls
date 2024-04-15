public with sharing class PdlKontaktadresse extends PdlObject {

    public enum PDL_KontaktadresseType {
        Innland,
        Utland
    }

    public Datetime gyldigFraOgMed{ get;}
    public Datetime gyldigTilOgMed{ get;}
    public PDL_KontaktadresseType type{ get;}
    public String coAdressenavn{ get;}
    public PDL_Postboksadresse postboksadresse{ get;}
    public PDL_Vegadresse vegadresse{ get;}
    public PDL_PostadresseIFrittFormat postadresseIFrittFormat{ get;}
    public PDL_UtenlandskAdresse utenlandskAdresse{ get;}
    public PDL_UtenlandskAdresseIFrittFormat utenlandskAdresseIFrittFormat{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlKontaktadresse() {
    }
}
