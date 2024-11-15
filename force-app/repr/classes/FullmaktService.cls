public with sharing class FullmaktService {
    private final static string API_CONFIG_NAME = 'Representasjon_Fullmakt'; //API Config name to set when using the ApiController
    private final static string SERVICE_AUTH_HEADER = 'PDLfullmakt';

    @TestVisible
    private enum services {
        GET_FULLMAKTSGIVER,
        GET_FULLMAKTSGIVER_HISTORIKK
    }

    public static HttpResponse getFullmaktsgiver(String identNr) {
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, services.GET_FULLMAKTSGIVER.name());
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.setLogUuid(new Uuid().getValue());
        apiCtrl.addHeader('Nav-Call-Id', apiCtrl.getLogUuid());
        apiCtrl.addHeader('Content-Type', 'application/json');
        Map<String, String> bodyData = new Map<String, String>{'ident' => identNr};
        apiCtrl.setBody(JSON.serialize(bodyData));
        apiCtrl.doCallout();
        return apiCtrl.getResponse();
    }

    public static HttpResponse getFullmaktsgiverHistorikk(String identNr) {
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, services.GET_FULLMAKTSGIVER_HISTORIKK.name());
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.setLogUuid(new Uuid().getValue());
        apiCtrl.addHeader('Nav-Call-Id', apiCtrl.getLogUuid());
        apiCtrl.addHeader('Content-Type', 'application/json');
        Map<String, String> bodyData = new Map<String, String>{'ident' => identNr};
        apiCtrl.setBody(JSON.serialize(bodyData));
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }
}