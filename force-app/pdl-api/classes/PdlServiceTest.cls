@isTest
private class PdlServiceTest {
    @isTest
    private static void PdlApiTest() {

        ApiMock.setTestMock('GET_PDL_API', 200, 'OK');
        PdlService.testQuery();

    }
    
    @isTest
    private static void getAnsvarssubjektListTest(){
        ApiMock.setTestMock('GET_PDL_API', 200, 'OK');
        System.assertEquals('0987654321', PdlService.getAnsvarssubjekList('1234567890')[0]);
    }

    @isTest
    private static void getNavnTest(){
        ApiMock.setTestMock('GET_PDL_API', 200, 'OK');
        System.assertEquals('Ola', PdlService.getName('1234567890'));
    }

/*     private static void testtest(){
        ApiController ac = new ApiController();

        ac.addApiGwHeader();

        https://saas-to-nav-api.preprod.nav.no

    } */
}
