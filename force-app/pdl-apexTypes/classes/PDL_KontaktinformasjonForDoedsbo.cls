public with sharing class PDL_KontaktinformasjonForDoedsbo {

    public PDL_KontaktinformasjonForDoedsboSkifteform skifteform{ get;}
    public Date attestutstedelsesdato{ get;}
    public PDL_KontaktinformasjonForDoedsboPersonSomKontakt personSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboAdvokatSomKontakt advokatSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboOrganisasjonSomKontakt organisasjonSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboAdresse adresse{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}
    public PDL_Metadata metadata{ get;}

    public PDL_KontaktinformasjonForDoedsbo() {

    }

    public enum PDL_KontaktinformasjonForDoedsboSkifteform{
        OFFENTLIG,
        ANNET
    }
}
