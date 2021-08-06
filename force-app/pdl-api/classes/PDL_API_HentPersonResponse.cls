public with sharing class PDL_API_HentPersonResponse {
    PDL_API_HentPersonData data;
    PDL_API_Error[] errors;
    
    private PDL_API_HentPersonResponse() {

    }
    public static PDL_API_HentPersonResponse makeFromJson(String jsonString){
        return 
            (PDL_API_HentPersonResponse) 
                System.JSON.deserialize(jsonString, PDL_API_HentPersonResponse.class);
    }

    public Boolean isEmpty(){
        return (data == null) && (errors == null);
    }
    public Boolean hasData(){
        return data != null;
    }
    public Boolean hasError(){
        return (errors != null) && !errors.isEmpty();
    }
    public String getError(){
        return System.JSON.serializePretty(errors, true);
    }
    public String getFornavn(){
        return this.data?.hentPerson?.navn[0]?.fornavn;
    }
    private Boolean hasForeldreansvar(){
        mustHaveForeldreanvar();
        if (this.data.hentPerson.foreldreansvar.isEmpty())
            return false;
        return true;
    }
    public Boolean isAnsvarlig(){
        if(!hasForeldreansvar())
            return false;
        for(PDL_API_Foreldreansvar fa : this.data.hentPerson.foreldreansvar){
            if (!String.isEmpty(fa.ansvarssubjekt))
                return true;
        }
        return false;
    }
    private void mustHaveForeldreanvar(){
        // we expecting the field exists in response if it was queried
        if (this.data?.hentPerson?.foreldreansvar == null) throw new MissingExpectedDataException('Unexpected: foreldreansvar==NULL');
    }
    public String[] getAnsvarssubjektList(){
        String[] ansvarssubjektList = new List<String>();
        if (!hasForeldreansvar()) return ansvarssubjektList;

        for(PDL_API_Foreldreansvar fa : this.data.hentPerson.foreldreansvar){
            if (!String.isEmpty(fa.ansvarssubjekt))
                ansvarssubjektList.add(fa.ansvarssubjekt);
        }

        return ansvarssubjektList;
    }

    class PDL_API_HentPersonData{
        PDL_API_Person hentPerson;
    }
    class PDL_API_Person {
        PDL_API_Navn[] navn;
        PDL_API_Foreldreansvar[] foreldreansvar;
        //...
    }
    class PDL_API_Navn{
        String fornavn;
        String mellomnavn;
        String etternavn;
        String forkortetNavn;
        PDL_API_OriginalNavn originalNavn;
        Date gyldigFraOgMed;
    
        // PDL_API_Folkeregistermetadata folkeregistermetadata;
        // PDL_API_Metadata metadata;
    }
    class PDL_API_OriginalNavn{
        String fornavn;
        String mellomnavn;
        String etternavn;
    }
    class PDL_API_Foreldreansvar{
        String ansvar;
        String ansvarlig;
        String ansvarssubjekt;
        //PDL_API_RelatedBiPerson ansvarligUtenIdentifikator;
    
        // PDL_API_Folkeregistermetadata folkeregistermetadata;
        // PDL_API_Metadata metadata;
    }
    class PDL_API_Error{
        String message;
        PDL_API_ErrorLocation[] locations;
        String[] path;
        PDL_API_ErrorExtensions extensions;
    }
    class PDL_API_ErrorLocation {
        Integer line;
        Integer column;
    }
    class PDL_API_ErrorExtensions{
        String code;
        Map<String, String> details;
        String classification;
    }
    public class MissingExpectedDataException extends Exception{}
}
