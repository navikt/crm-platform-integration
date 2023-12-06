@IsTest
private with sharing class CV_ServiceTest{
    @isTest
    static void testGetCV() {
        String fodselsnummer = '12345678901';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        HttpResponse res = CV_Service.getCV(fodselsnummer);
        System.assertEquals(200, res.getStatusCode());   
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"mockResponse": "success"}');
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }
}