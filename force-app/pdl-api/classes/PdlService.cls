/**
 * Service class for querying PDL API.
 * Callers must supply their approved behandlingsnummer explicitly.
 */
public with sharing class PdlService {
    /**
     * Queries the PDL API using the specified behandlingsnummer and query.
     * See official PDL API documentation for details and usage examples.
     * @param behandlingsnummer The behandlingsnummer to use in the PDL API query.
     * @param query The graphQl query string to send to the PDL API.
     * @return HttpResponse from the PDL API call.
     */
    public static HttpResponse queryData(String behandlingsnummer, String query) {
        if (String.isBlank(behandlingsnummer)) {
            throw new IllegalArgumentException('behandlingsnummer is required for PDL queries.');
        }
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('PDL_API', 'POST_PDL_API');
        apiCtrl.addServiceAuthHeader('PdlApi')
            .addHeader('Content-Type', 'application/json')
            .addHeader('Tema', 'GEN')
            .addHeader('behandlingsnummer', behandlingsnummer);
        apiCtrl.setBody(query);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }
}
