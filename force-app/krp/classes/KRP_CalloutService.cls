public inherited sharing class KRP_CalloutService extends ApiController {
    private final string CONFIG_NAME = 'KRP_API';
    private final string SERVICE_AUTH_HEADER = 'Krp';

    public enum SERVICES {
        POST_HENT_AKTIV_KONTO
    }

    public HttpResponse getBankAccount(String ident) {
        initRequest(CONFIG_NAME, SERVICES.POST_HENT_AKTIV_KONTO.name());
        addServiceAuthHeader(SERVICE_AUTH_HEADER);
        setBody(JSON.serialize(new Map<String, String> {'kontohaver' => ident}));
        doCallout();
        return getResponse();
    }
}
