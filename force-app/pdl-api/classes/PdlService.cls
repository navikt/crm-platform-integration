public with sharing class PdlService{

    public static HttpResponse queryData(String query){
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('PDL_API','POST_PDL_API');
        apiCtrl.addServiceAuthHeader('PdlApi').addHeader('Content-Type', 'application/json').addHeader('Tema','GEN');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();
        
        return apiCtrl.getResponse();
    }

}
