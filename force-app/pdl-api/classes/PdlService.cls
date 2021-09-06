public with sharing class PdlService{
    public static void testQuery() {
        ApiController apiCtrl = new ApiController();
        
        String ident = '1234567890';

        apiCtrl.initRequest('PDL_API','GET_PDL_API');
        apiCtrl.setBody(PDL_API_Query.Ansvarssubjekt(ident));
        apiCtrl.doCallout();

        HttpResponse r = apiCtrl.getResponse();

        System.debug(r.toString());

        PDL_API_HentPersonResponse pdl_r = PDL_API_HentPersonResponse.fromHttpResponse(r);
        System.debug(pdl_r.getFornavn());
        System.debug(pdl_r.getAnsvarssubjektList());
    }
    
    public static HttpResponse queryData(String query){
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('PDL_API','GET_PDL_API');
        apiCtrl.addServiceAuthHeader('PdlApi').addHeader('Content-Type', 'application/json').addHeader('Tema','GEN');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();
        
        return apiCtrl.getResponse();
    }

    public static List<String> getAnsvarssubjekList(String ident){
        return PDL_API_HentPersonResponse.fromHttpResponse(queryData(
            PDL_API_Query.Ansvarssubjekt(ident)
        )).getAnsvarssubjektList();
    }

    public static String getName(String ident){
        return PDL_API_HentPersonResponse.fromHttpResponse(queryData(PDL_API_Query.Navn(ident))).getFornavn();
    }

}
