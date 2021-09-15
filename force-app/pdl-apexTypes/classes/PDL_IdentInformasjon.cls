public with sharing class PDL_IdentInformasjon {

    public String ident{get;}
    public PDL_IdentGruppe gruppe{get;}
    public Boolean historisk{get;}

    public PDL_IdentInformasjon() {

    }

    public enum PDL_IdentGruppe {
        AKTORID,
        FOLKEREGISTERIDENT,
        NPID
    }
}
