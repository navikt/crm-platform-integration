@isTest
private class PDL_API_HentPersonResponseTest {
    @isTest
    private static void makeFromJsonTest(){
        String testJsonString = '{"data": {"hentPerson": {"navn": ['+        
    '{"fornavn": "Ola","mellomnavn": null,"etternavn": "Normann"'+
    '}],"foreldreansvar": [{"ansvar": "far","ansvarlig": "1234567890",'+
    '"ansvarssubjekt": "0987654321"}]}},"errors": [{"message": "Fant ikke person",'+
    '"locations": [],"path": [],"extensions": {"code": "not_found",'+
    '"details": null,"classification": "ExecutionAborted"}}]}';
        HttpResponse httpr = new HttpResponse();
        httpr.setBody(testJsonString);
    PDL_API_HentPersonResponse r = PDL_API_HentPersonResponse.fromHttpResponse(httpr);
        System.assertNotEquals(null, r);
        System.assertEquals('Ola', r.getFornavn());
    }
}
