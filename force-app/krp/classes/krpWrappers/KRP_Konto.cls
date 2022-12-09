public inherited sharing class KRP_Konto {
    public String kontohaver;
    public String kontonummer;
    public UtenlandskKontoInfo utenlandskKontoInfo;
    public String gyldigFom;
    public String gyldigTom;
    public String endretAv;
    public String opprettetAv;
    public String kilde;


    public class UtenlandskKontoInfo {
        public String banknavn;
        public String bankkode;
        public String bankLandkode;
        public String valutakode;
        public String swiftBicKode;
        public String bankadresse1;
        public String bankadresse2;
        public String bankadresse3;
    }
}
