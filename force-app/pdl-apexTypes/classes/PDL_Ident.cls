public with sharing class PDL_Ident {
    public enum IdentGruppe {
        FOLKEREGISTERIDENT,
        AKTORID,
        NPID
    }

    public string ident;
    public Boolean historisk;
    public IdentGruppe gruppe;
}
