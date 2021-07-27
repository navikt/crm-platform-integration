public with sharing class NavUnit {
    @AuraEnabled
    public String enhetId;
    @AuraEnabled
    public String navn;
    @AuraEnabled
    public String enhetNr;
    @AuraEnabled
    public Integer antallRessurser;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public String orgNivaa;
    @AuraEnabled
    public String type;
    @AuraEnabled
    public String organisasjonsnummer;
    @AuraEnabled
    public Date underEtableringDato;
    @AuraEnabled
    public Date aktiveringsdato;
    @AuraEnabled
    public Date underAvviklingDato;
    @AuraEnabled
    public Date nedleggelsesdato;
    @AuraEnabled
    public Boolean oppgavebehandler;
    @AuraEnabled
    public Integer versjon;
    @AuraEnabled
    public String sosialeTjenester;
    @AuraEnabled
    public String kanalstrategi;
    @AuraEnabled
    public String orgNrTilKommunaltNavKontor;

    public NavUnit() {
        this.enhetId = null;
        this.navn = null;
        this.enhetNr = null;
        this.antallRessurser = null;
        this.status = null;
        this.orgNivaa = null;
        this.type = null;
        this.organisasjonsnummer = null;
        this.underEtableringDato = null;
        this.aktiveringsdato = null;
        this.underAvviklingDato = null;
        this.nedleggelsesdato = null;
        this.oppgavebehandler = false;
        this.versjon = null;
        this.sosialeTjenester = null;
        this.kanalstrategi = null;
        this.orgNrTilKommunaltNavKontor = null;
    }
}
