public inherited sharing class KRP_Konto {
    @AuraEnabled
    public String kontohaver;
    @AuraEnabled
    public String kontonummer;
    @AuraEnabled
    public UtenlandskKontoInfo utenlandskKontoInfo;
    @AuraEnabled
    public String gyldigFom;
    @AuraEnabled
    public String gyldigTom;
    @AuraEnabled
    public String endretAv;
    @AuraEnabled
    public String opprettetAv;
    @AuraEnabled
    public String kilde;


    public class UtenlandskKontoInfo {
        @AuraEnabled
        public String banknavn;
        @AuraEnabled
        public String bankkode;
        @AuraEnabled
        public String bankLandkode;
        @AuraEnabled
        public String valutakode;
        @AuraEnabled
        public String swiftBicKode;
        @AuraEnabled
        public String bankadresse1;
        @AuraEnabled
        public String bankadresse2;
        @AuraEnabled
        public String bankadresse3;
    }
}
