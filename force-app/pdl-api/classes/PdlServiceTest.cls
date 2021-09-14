@isTest
private class PdlServiceTest {
    @isTest
    private static void PdlApiTest() {
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        System.assertEquals(200, PdlService.queryData('').getStatusCode());
    }
}
