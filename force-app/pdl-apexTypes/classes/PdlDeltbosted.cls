public with sharing class PdlDeltbosted extends PdlObject {
    public Date startdatoForKontrakt{ get;}
    public Date sluttdatoForKontrakt{ get;}
    public String coAdressenavn{ get;}
    public PDL_Vegadresse vegadresse{ get;}
    public PDL_Matrikkeladresse matrikkeladresse{ get;}
    public PDL_UtenlandskAdresse utenlandskAdresse{ get;}
    public PDL_UkjentBosted ukjentBosted{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlDeltbosted() {
    }
}
