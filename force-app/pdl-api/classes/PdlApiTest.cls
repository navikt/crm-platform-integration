@isTest
private class PdlApiTest {
    @isTest
    private static void PdlApiTest() {

        ApiMock.setTestMock('GET_PDL_API', 200, 'OK');
        PdlApi.testQuery();

    }
    
    @isTest
    private static void getAnsvarssubjektListTest(){
        ApiMock.setTestMock('GET_PDL_API', 200, 'OK');
        System.assertEquals('0987654321', PdlApi.getAnsvarssubjekList('1234567890')[0]);
    }
}
