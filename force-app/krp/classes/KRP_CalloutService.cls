public inherited sharing class KRP_CalloutService extends ApiController {
    private final string CONFIG_NAME = 'KRP_API';
    private final string SERVICE_AUTH_HEADER = 'Krp';


    public KRP_CalloutService() {
        LoggerUtility logger = new LoggerUtility('Krp');
        setLogCategory('Krp').
        setLogger(logger).
        setLogCalloutRequest().
        setLogDomain(CRM_ApplicationDomain.Domain.CRM);
    }

    public enum SERVICES {
        POST_HENT_AKTIV_KONTO
    }

    public HttpResponse getBankAccount(String ident) {
        initRequest(CONFIG_NAME, SERVICES.POST_HENT_AKTIV_KONTO.name());
        addServiceAuthHeader(SERVICE_AUTH_HEADER);
        setBody(JSON.serialize(new Map<String, String> {'kontohaver' => ident}));
        
        //Generate transaction id
        String transactionId = new Uuid().getValue();
        setLogUuid(transactionId);
        setHeaders(new Map<String, String>{
            'nav-call-id' => transactionId,
            'Content-Type' => 'application/json',
            'accept' => 'application/json'
        });

        doCallout();
        return getResponse();
    }
}
