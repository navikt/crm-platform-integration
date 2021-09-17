@IsTest
private with sharing class TPS_CalloutServiceTest {
    @IsTest
    static void getBankAccountTest() {
        HttpResponse result;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', 'TPS_BANKKONTO', null));

        Test.startTest();
        result = TPS_CalloutService.getBankAccount('actorId');
        Test.stopTest();

        System.assertEquals('TPS_BANKKONTO', result.getBody(), 'Expected to get the test body');
    }
}
