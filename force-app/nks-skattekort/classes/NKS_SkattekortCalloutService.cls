public with sharing class NKS_SkattekortCalloutService {
    // Swagger: https://sokos-skattekort.intern.dev.nav.no/api/v1/hent-skattekort/docs
    // Test fnr til testing: 09910497658 for prosentkort, 14859898638 for tabellkort, 29855398344 og 29860299923 for syntetisk-kort
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