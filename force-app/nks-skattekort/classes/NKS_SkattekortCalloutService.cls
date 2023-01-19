public with sharing class NKS_SkattekortCalloutService {
    public static HttpResponse getSkattekort(String fnr, String inntektsaar) {
       
        SkattekortRequest requestBody = new SkattekortRequest();
        requestBody.fnr = fnr;
        requestBody.inntektsaar = inntektsaar;

        ApiController apiController = new ApiController();
        apiController.initRequest('Skattekort_API', 'POST_SKATTEKORT_API');
        // TODO: Login to IDA -> Test Access Token link -> See if I get token
        apiController.addServiceAuthHeader('Skattekort').addHeader('Content-Type', 'application/json');
        apiController.setBody(JSON.serialize(requestBody));
        apiController.doCallout();
        return apiController.getResponse();
    }

    private class SkattekortRequest {
        String fnr;
        String inntektsaar;
    }
}