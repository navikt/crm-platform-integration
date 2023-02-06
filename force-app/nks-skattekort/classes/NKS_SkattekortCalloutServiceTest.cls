@isTest
private with sharing class NKS_SkattekortCalloutServiceTest {
    @IsTest
    static void getSkattekortTest() {
        HttpResponse result;
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', 'POST_SKATTEKORT_API', null));

        Test.startTest();
        result = NKS_SkattekortCalloutService.getSkattekort('12345612345', '2022');
        Test.stopTest();

        System.assertEquals('POST_SKATTEKORT_API', result.getBody(), 'Expected to get the test body.');
        System.assertEquals(200, result.getStatusCode(), 'Code is not 200.');
    }
}