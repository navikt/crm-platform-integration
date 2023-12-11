/**
 * @description
 * Service class to retrieve CV via API
 */
public with sharing class CV_Service {
    private static final Boolean ER_MANUELL = true;
    private static final String BASE_CONFIG = 'CV_API';

    /**
     * @description: Get CV for a person by person ident
     * @author Sara Mohammadi | 06-01-2022
     * @param fodselsnummer
     * @return CV-Response
     **/
    public static HttpResponse getCV(String fodselsnummer) {
        ApiController apiCtrl = new ApiController();
        String serviceName = 'GET_CV';

        Map<String, String> pathParamMap = new Map<String, String>{ 'fodselsnummer' => fodselsnummer };
        Map<String, String> queryParamMap = new Map<String, String>{ 'erManuell' => String.valueOf(ER_MANUELL) };

        apiCtrl.initRequest(BASE_CONFIG, serviceName, pathParamMap);
        apiCtrl.addServiceAuthHeader('CV').addHeader('Content-Type', 'application/json');
        apiCtrl.setUrlParams(queryParamMap);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }
}