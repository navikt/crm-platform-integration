public with sharing class PdlSikkerhetstiltak extends PdlObject {
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

    public PdlSikkerhetstiltak() {
    }
}