public with sharing class PdlApi {

    public static void testQuery() {
        ApiController apiCtrl = new ApiController();
        
        String ident = '1234567890';

        apiCtrl.initRequest('PDL_API','GET_PDL_API');
        apiCtrl.setBody(PDL_API_Query.Ansvarssubjekt(ident));
        apiCtrl.doCallout();

        HttpResponse r = apiCtrl.getResponse();

        System.debug(r.toString());

        PDL_API_HentPersonResponse pdl_r = PDL_API_HentPersonResponse.makeFromJson(r.getBody());
        System.debug(pdl_r.getFornavn());
        System.debug(pdl_r.getAnsvarssubjektList());
    }
    
    private static PDL_API_HentPersonResponse queryData(String query){
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('PDL_API','GET_PDL_API');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();
        PDL_API_HentPersonResponse r = 
            PDL_API_HentPersonResponse.makeFromJson(apiCtrl.getResponse().getBody());
        if(r.hasError()){
            // TODO: do something usefull: logging and/or throwing
            System.debug(r.getError());
        }
        return r;
    }

    public static List<String> getAnsvarssubjekList(String ident){
        return queryData(
            PDL_API_Query.Ansvarssubjekt(ident)
        ).getAnsvarssubjektList();
    }

    public static String getName(String ident){
        return queryData(PDL_API_Query.Navn(ident)).getFornavn();
    }

}
