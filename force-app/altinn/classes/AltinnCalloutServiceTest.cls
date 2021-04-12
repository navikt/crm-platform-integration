@IsTest
private with sharing class AltinnCalloutServiceTest {
   
    @IsTest
    private static void getOrganizations(){
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp=new AltinnCalloutService().getOrganizations('12345678901');
        Test.stopTest();

        System.assertEquals(true,resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
        System.assertEquals(18, resp.organizations.size(), 'Expect 18 organaizations');
    }

    @IsTest
    private static void getRights(){
        ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp=new AltinnCalloutService().getRights('12345678901','87231908');
        Test.stopTest();

        System.assertEquals(true,resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
        System.assertEquals(50, resp.rights.size(), 'Expect 50 rights');
    }
}
