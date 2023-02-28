public inherited sharing class NOM_Service extends ApiController{
    private static final String API_CONFIG_NAME = 'NOM_API';
    private static final String SERVICE_AUTH_HEADER = 'Nom';
    private static final String DEFAULT_QUERY_API_SERVICE_NAME = 'POST_NOM';

    public NOM_Service() {
        LoggerUtility logger = new LoggerUtility('NOM');
        setLogCategory('NOM').
        setLogger(logger).
        setLogCalloutRequest().
        publishLogAfterCallout().
        setLogDomain(CRM_ApplicationDomain.Domain.CRM);
    }

    public NOM_Service(CRM_ApplicationDomain.Domain domain) {
        LoggerUtility logger = new LoggerUtility('NOM');
        setLogCategory('NOM').
        setLogger(logger).
        setLogCalloutRequest().
        publishLogAfterCallout().
        setLogDomain(domain);
    }

    /**
     * @description query data from NOM
     * @param ident 
     * @return  `HttpResponse`
     */
    public HttpResponse queryData(String query) {
        initRequest(API_CONFIG_NAME, DEFAULT_QUERY_API_SERVICE_NAME);
        addServiceAuthHeader(SERVICE_AUTH_HEADER);
        setBody(query);
        
        //Generate transaction id
        String transactionId = new Uuid().getValue();
        setLogUuid(transactionId);
        setHeaders(new Map<String, String>{
            'Nav-CallId' => transactionId,
            'Content-Type' => 'application/json'
        });

        doCallout();
        return getResponse();
    }
}
