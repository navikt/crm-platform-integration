public with sharing class PDL_Vegadresse {

    public Long matrikkelId{ get;}
    @TestVisible
    public String husnummer{ get;}
    @TestVisible
    public String husbokstav{ get;}
    public String bruksenhetsnummer{ get;}
    @TestVisible
    public String adressenavn{ get;}
    @TestVisible
    public String kommunenummer{ get;}
    @TestVisible
    public String bydelsnummer{ get;}
    public String tilleggsnavn{ get;}
    @TestVisible
    public String postnummer{ get;}
    @TestVisible
    public PDL_Koordinater koordinater{ get;}

    public PDL_Vegadresse() {

    }
}
