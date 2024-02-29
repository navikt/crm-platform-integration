public with sharing class PDL_Oppholdsadresse {

    public Datetime gyldigFraOgMed{ get;}
    public Datetime gyldigTilOgMed{ get;}
    public String coAdressenavn{ get;}
    public PDL_UtenlandskAdresse utenlandskAdresse{ get;}
    @TestVisible
    public PDL_Vegadresse vegadresse{ get;}
    public PDL_Matrikkeladresse matrikkeladresse{ get;}
    public String oppholdAnnetSted{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_Oppholdsadresse() {

    }
}
