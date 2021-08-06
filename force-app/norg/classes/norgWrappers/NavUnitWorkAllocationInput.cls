public with sharing class NavUnitWorkAllocationInput {
    @AuraEnabled
    public String behandlingstema;
    @AuraEnabled
    public String behandlingstype;
    @AuraEnabled
    public String diskresjonskode;
    @AuraEnabled
    public String enhetNummer;
    @AuraEnabled
    public String geografiskOmraade;
    @AuraEnabled
    public String oppgavetype;
    @AuraEnabled
    public Boolean skjermet;
    @AuraEnabled
    public String tema;
    @AuraEnabled
    public String temagruppe;

    public NavUnitWorkAllocationInput() {
        this.behandlingstema = null;
        this.behandlingstype = null;
        this.diskresjonskode = null;
        this.enhetNummer = null;
        this.geografiskOmraade = null;
        this.oppgavetype = null;
        this.skjermet = false;
        this.tema = null;
        this.temagruppe = null;
    }
}
