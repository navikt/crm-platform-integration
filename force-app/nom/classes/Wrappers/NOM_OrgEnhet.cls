public with sharing class NOM_OrgEnhet {

    public String id;
    public String agressoId;
    public String orgNiv;
    public String remedyEnhetId;
    public String agressoOrgenhetType;
    public String navn;
    public Date gyldigFom;
    public Date gyldigTom;
    public List<NOM_Organisering> organiseringer;
    public List<NOM_OrgEnhetsLeder> leder;
    public List<NOM_OrgEnhetsKobling> koblinger;
    public NOM_OrgEnhetsKategori nomNivaa;
    public NOM_Kode type;
    public NOM_OrgEnhetsType orgEnhetsType;


    public NOM_OrgEnhet() {

    }
}