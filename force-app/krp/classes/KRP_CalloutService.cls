public inherited sharing class KRP_CalloutService extends ApiController {
    private final string CONFIG_NAME = 'KRP_API';

    /**
     * @description Initiate default log settings
     */
    public KRP_CalloutService() {
        LoggerUtility logger = new LoggerUtility('Krp');
        setLogCategory('Krp')
            .setLogger(logger)
            .setLogCalloutRequest()
            .publishLogAfterCallout()
            .setLogDomain(CRM_ApplicationDomain.Domain.NKS);
    }

    public enum SERVICES {
        POST_HENT_AKTIV_KONTO
    }

    /**
     * @description Retrieve the ACTIVE account information from kontoregisteret
     * @param ident
     * @return  `HttpResponse`
     */
    public HttpResponse getBankAccount(String ident) {
        initRequest(CONFIG_NAME, SERVICES.POST_HENT_AKTIV_KONTO.name());
        setSystemContext();
        addSaasProxyServiceAuthHeader();
        setBody(JSON.serialize(new Map<String, String>{ 'kontohaver' => ident }));

        //Generate transaction id
        String transactionId = new Uuid().getValue();
        setLogUuid(transactionId);
        setHeaders(
            new Map<String, String>{
                'nav-call-id' => transactionId,
                'Content-Type' => 'application/json',
                'accept' => 'application/json'
            }
        );

        doCallout();
        return getResponse();
    }
}
