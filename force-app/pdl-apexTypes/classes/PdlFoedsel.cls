public with sharing class PdlFoedsel extends PdlObject {
    public Integer foedselsaar{ get;}
    @TestVisible
    public Date foedselsdato{ get;}
    public String foedeland{ get;}
    public String foedested{ get;}
    public String foedekommune{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlFoedsel() {
    }
}
