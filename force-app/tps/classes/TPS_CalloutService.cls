public inherited sharing class TPS_CalloutService {
    private static final string CONFIG_NAME = 'TPS_PROXY';
    private static final string SERVICE_AUTH_HEADER = 'TpsProxy';

    public static HttpResponse getBankAccount(String actorId) {
        Map<String, String> paramMap = new Map<String, String>{ 'aktoerid' => actorId };

        ApiController apiController = new ApiController();
        apiController.initRequest(CONFIG_NAME, 'GET_TPS_BANKKONTO', paramMap);
        apiController.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiController.doCallout();
        return apiController.getResponse();
    }
}
