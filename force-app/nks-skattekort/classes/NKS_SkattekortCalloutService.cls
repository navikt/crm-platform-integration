public with sharing class NKS_SkattekortCalloutService {
    public static HttpResponse getSkattekort(String fnr, String inntektsaar) {
       // Testdata to use: fnr - 03063300267, inntektsaar - 2022
        SkattekortRequest requestBody = new SkattekortRequest();
        requestBody.fnr = fnr;
        requestBody.inntektsaar = inntektsaar;

        ApiController apiController = new ApiController();
        apiController.initRequest('Skattekort_API', 'POST_SKATTEKORT_API');
        // TODO: Send Swagger-fil i "saas-tilgang-til-nav-apier" kanalen for å få lagt det inn i API Gateway, deretter kan det testes i dev console / postman
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