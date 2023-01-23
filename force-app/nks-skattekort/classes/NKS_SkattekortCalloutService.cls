public with sharing class NKS_SkattekortCalloutService {
    // Swagger: https://sokos-skattekort-person.dev.intern.nav.no/api/v1/docs
    // Testdata: fnr - 03063300267, inntektsaar - 2022
    public static HttpResponse getSkattekort(String fnr, String inntektsaar) {
        SkattekortRequest requestBody = new SkattekortRequest();
        requestBody.fnr = fnr;
        requestBody.inntektsaar = inntektsaar;

        ApiController apiController = new ApiController();
        apiController.initRequest('Skattekort_API', 'POST_SKATTEKORT_API');
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