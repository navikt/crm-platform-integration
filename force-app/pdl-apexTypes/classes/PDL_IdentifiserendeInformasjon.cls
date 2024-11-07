public with sharing class PDL_IdentifiserendeInformasjon {

    @TestVisible
    public PDL_Navn navn { get;}
    @TestVisible
    public String kjoenn { get;}
    @TestVisible
    public Date foedselsdato { get;}
    @TestVisible
    public String[] statsborgerskap { get;}

    public PDL_IdentifiserendeInformasjon() {
    }
}