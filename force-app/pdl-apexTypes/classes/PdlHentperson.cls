/**
 * Identical to PDL_HentPerson except its attributes inherit metadata
 */
public with sharing class PdlHentperson {
    @TestVisible
    public PdlAdressebeskyttelse[] adressebeskyttelse{ get;}
    @TestVisible
    public PdlBostedsadresse[] bostedsadresse{ get;}
    @TestVisible
    public PdlDeltbosted[] deltBosted{ get;}
    @TestVisible
    public PdlDoedfoedtbarn[] doedfoedtBarn{ get;}
    @TestVisible
    public PdlDoedsfall[] doedsfall{ get;}
    @TestVisible
    public PdlFalskidentitet falskIdentitet{ get;}
    @TestVisible
    public PdlFoedsel[] foedsel{ get;}
    @TestVisible
    public PdlFolkeregisteridentifikator[] folkeregisteridentifikator{ get;}
    @TestVisible
    public PdlFolkeregisterpersonstatus[] folkeregisterpersonstatus{ get;}
    @TestVisible
    public PdlForelderbarnrelasjon[] forelderBarnRelasjon{ get;}
    @TestVisible
    public PdlForeldreansvar[] foreldreansvar{ get;}
    @TestVisible
    public PdlFullmakt[] fullmakt{ get;}
    @TestVisible
    public PdlIdentitetsgrunnlag[] identitetsgrunnlag{ get;}
    @TestVisible
    public PdlInnflyttingtilnorge[] innflyttingTilNorge{ get;}
    @TestVisible
    public PdlKjoenn[] kjoenn{ get;}
    @TestVisible
    public PdlKontaktadresse[] kontaktadresse{ get;}
    @TestVisible
    public PdlKontaktinformasjonfordoedsbo[] kontaktinformasjonForDoedsbo{ get;}
    @TestVisible
    public PdlNavn[] navn{ get;}
    @TestVisible
    public PdlOpphold[] opphold{ get;}
    @TestVisible
    public PdlOppholdsadresse[] oppholdsadresse{ get;}
    @TestVisible
    public PdlSikkerhetstiltak[] sikkerhetstiltak{ get;}
    @TestVisible
    public PdlSivilstand[] sivilstand{ get;}
    @TestVisible
    public PdlStatsborgerskap[] statsborgerskap{ get;}
    @TestVisible
    public PdlTelefonnummer[] telefonnummer{ get;}
    @TestVisible
    public PdlTilrettelagtkommunikasjon[] tilrettelagtKommunikasjon{ get;}
    @TestVisible
    public PdlUtenlandskidentifikasjonsnummer[] utenlandskIdentifikasjonsnummer{ get;}
    @TestVisible
    public PdlUtflyttingfranorge[] utflyttingFraNorge{ get;}
    @TestVisible
    public PdlVergemaalellerfremtidsfullmakt[] vergemaalEllerFremtidsfullmakt{ get;}

    public PdlHentperson() {
    }
}
