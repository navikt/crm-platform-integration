public with sharing class NKS_PostAddressService {
    private static final String API_CONFIG_NAME = 'Regoppslag_API';
    private static final String SERVICE_NAME = 'POST_REGOPPSLAG_API';
    private static final String SERVICE_AUTH_HEADER = 'Regoppslag';
    public static NKS_PostAddressResponse getPostAddress(String ident) {
        HttpResponse httpResponse = regoppsalgService(ident);
        NKS_PostAddressResponse response = new NKS_PostAddressResponse();
        if (httpResponse.getStatusCode() == 200) {
            response = (NKS_PostAddressResponse) JSON.deserialize(
                httpResponse.getBody(),
                NKS_PostAddressResponse.class
            );
        } else {
            LoggerUtility logger = new LoggerUtility('Regoppslag');
            logger.httpError(
                'Failed to get Post address from Regoppslag',
                httpResponse,
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
        }
        response.status = String.valueOf(httpResponse.getStatusCode());
        return response;
    }
    public static HttpResponse regoppsalgService(String ident) {
        String query = '{"ident": "' + ident + '","tema": "GEN"}';
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, SERVICE_NAME);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(query);
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }
    public class NKS_PostAddressResponse {
        public String navn;
        public NKS_PostAddressAddress adresse;
        public String status;
    }
    public class NKS_PostAddressAddress {
        public String type;
        public String adresselinje1;
        public String adresselinje2;
        public String adresselinje3;
        public String postnummer;
        public String poststed;
        public String landkode;
        public String land;
    }
}
