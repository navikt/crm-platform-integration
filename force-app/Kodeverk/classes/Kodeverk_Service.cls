public with sharing class Kodeverk_Service extends ApiController {
    private LoggerUtility logger;
    private static final String BASE_CONFIG = 'KODEVERK_API';

    public enum SERVICES {
        GET_HIERARKI,
        GET_KODEVERK_BETYDNINGER
    }

    public Kodeverk_Service() {
        addServiceAuthHeader('KodeverkAPI');
    }

    public HttpResponse getHierarki(String hierarkiNavn) {
        Map<String, String> queryParamMap = new Map<String, String>{ 'spraak' => 'nb' };
        Map<String, String> params = new Map<String, String>();
        params.put('hierarkinavn', hierarkiNavn);

        initRequest(BASE_CONFIG, SERVICES.GET_HIERARKI.name(), params);

        String transactionId = new Uuid().getValue();
        setLogUuid(transactionId);
        setHeaders(
            new Map<String, String>{
                'Nav-Call-Id' => transactionId,
                'NAV-Consumer-Id' => 'Salesforce',
                'Content-Type' => 'application/json',
                'accept' => 'application/json'
            }
        );
        setUrlParams(queryParamMap);
        doCallout();

        return getResponse();
    }

    public HttpResponse getKodeverkBetydninger(String kodeverkNavn) {
        Map<String, String> queryParamMap = new Map<String, String>{ 'spraak' => 'nb' };
        Map<String, String> params = new Map<String, String>();
        params.put('kodeverksnavn', kodeverkNavn);

        initRequest(BASE_CONFIG, SERVICES.GET_KODEVERK_BETYDNINGER.name(), params);

        String transactionId = new Uuid().getValue();
        setLogUuid(transactionId);
        setHeaders(
            new Map<String, String>{
                'Nav-Call-Id' => transactionId,
                'NAV-Consumer-Id' => 'Salesforce',
                'Content-Type' => 'application/json',
                'accept' => 'application/json'
            }
        );
        setUrlParams(queryParamMap);
        doCallout();

        return getResponse();
    }
}
