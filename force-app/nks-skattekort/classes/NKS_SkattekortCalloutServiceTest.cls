@isTest
private with sharing class NKS_SkattekortCalloutServiceTest {
    @IsTest
    static void getSkattekortTest() {
        ApiMock.setTestMock('POST_SKATTEKORT_API', 200, 'OK');

        Test.startTest();
        HttpResponse result = NKS_SkattekortCalloutService.getSkattekort('14859898638', '2025');
        Test.stopTest();

        System.assertNotEquals(null, result.getBody(), 'Expected to get the test body.');
        System.assertEquals(200, result.getStatusCode(), 'Code is not 200.');
    }
}