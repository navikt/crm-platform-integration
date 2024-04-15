public with sharing class PdlKontaktinformasjonfordoedsbo extends PdlObject {

    public PDL_KontaktinformasjonForDoedsboSkifte skifteform{ get;}
    public Date attestutstedelsesdato{ get;}
    public PDL_KontaktinformasjonForDoedsboPerson personSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboAdvokat advokatSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboOrg organisasjonSomKontakt{ get;}
    public PDL_KontaktinformasjonForDoedsboAdresse adresse{ get;}
    public PDL_Folkeregistermetadata folkeregistermetadata{ get;}

    public PdlKontaktinformasjonfordoedsbo() {
    }
}
