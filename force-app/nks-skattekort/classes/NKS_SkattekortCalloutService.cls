public with sharing class NKS_SkattekortCalloutService {
    public static HttpResponse getSkattekort(String fnr, String inntektsaar) {
       
        SkattekortRequest requestBody = new SkattekortRequest();
        requestBody.fnr = fnr;
        requestBody.inntektsaar = inntektsaar;

        ApiController apiController = new ApiController();
        apiController.initRequest('name of api base config','name of api service config'); // TODO: Fix api base config and service config
        apiController.addServiceAuthHeader('name of skattekort auth header').addHeader('Content-Type', 'application/json'); // TODO: Fix service auth header
        apiController.setBody(JSON.serialize(requestBody));
        apiController.doCallout();
        return apiController.getResponse();
    }

    private class SkattekortRequest {
        String fnr;
        String inntektsaar;
    }
}