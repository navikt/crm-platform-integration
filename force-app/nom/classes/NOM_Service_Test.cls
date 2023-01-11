@isTest
public class NOM_Service_Test {
    
    @isTest
    private static void queryDataTest(){
        NOM_Service service = new NOM_Service();
        ApiMock.setTestMock('POST_NOM', 200, 'OK');

        Test.startTest();
        HttpResponse resp = service.queryData('query');
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode());
        System.assertNotEquals(null, resp.getBody());
    }
}
