public with sharing class PDL_Sikkerhetstiltak {

    @TestVisible
    public String tiltakstype{ get;}
    @TestVisible
    public String beskrivelse{ get;}
    @TestVisible
    public PDL_SikkerhetstiltakKontaktperson kontaktperson{ get;}
    @TestVisible
    public Date gyldigFraOgMed{ get;}
    @TestVisible
    public Date gyldigTilOgMed{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_Sikkerhetstiltak() {

    }
}
