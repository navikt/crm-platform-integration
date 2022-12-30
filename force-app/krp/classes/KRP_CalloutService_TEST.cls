@isTest
public class KRP_CalloutService_TEST {
    private static KRP_CalloutService service = new KRP_CalloutService();

    @isTest
    static void testGetBankAccount() {
        ApiMock.setTestMock(KRP_CalloutService.SERVICES.POST_HENT_AKTIV_KONTO.name(), 200, 'OK');

        Test.startTest();
        HttpResponse resp = service.getBankAccount('12345678910');
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
        System.assertNotEquals(null, resp.getBody());
    }
}
