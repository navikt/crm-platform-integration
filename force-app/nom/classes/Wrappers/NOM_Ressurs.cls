public with sharing class NOM_Ressurs {

    public String navident;
    public String personident;
    public List<NOM_RessursOrgTilknytning> orgTilknytning;
    public List<NOM_LederOrgEnhet> lederFor;
    public List<NOM_RessursLeder> ledere;
    public NOM_FolkeregisterPerson folkeregisterPerson;
    public String epost;
    public String visningsnavn;
    public String fornavn;
    public String etternavn;
    public List<NOM_Telefon> telefon;
    public List<NOM_Sektor> sektor;

    public NOM_Ressurs() {

    }
}