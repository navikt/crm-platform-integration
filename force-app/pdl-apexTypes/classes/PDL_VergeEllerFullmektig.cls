public with sharing class PDL_VergeEllerFullmektig {

    @TestVisible
    public PDL_Personnavn navn{ get;}
    @TestVisible
    public String motpartsPersonident{ get;}
    @TestVisible
    public String omfang{ get;}
    @TestVisible
    public Boolean omfangetErInnenPersonligOmraade{ get;}
    public PDL_IdentInformasjon identifiserendeInformasjon { get;}
    public PDL_Tjenesteomraade tjenesteomraade { get;}

    public PDL_VergeEllerFullmektig() {

    }
}
