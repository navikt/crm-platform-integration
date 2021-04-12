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
    private static void getOrganizations_when500Error(){
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 500, 'Server error');

        Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp=new AltinnCalloutService().getOrganizations('12345678901');
        Test.stopTest();

        System.assertEquals(false,resp.success, 'Expect error');
        System.assert(resp.errorMessage.contains('Kunne ikke hente organisasjoner fra Altinn.'), 'Expect error message');
        System.assertEquals(null, resp.organizations, 'Expect no organaizations');
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

    @IsTest
    private static void getRights_when500Error(){
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 500, 'Server error');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp=new AltinnCalloutService().getRights('12345678901','87231908');
        Test.stopTest();

        System.assertEquals(false,resp.success, 'Expect error');
        System.assert(resp.errorMessage.contains('Kunne ikke hente rettigheter fra Altinn.'), 'Expect error message');
        System.assertEquals(null, resp.rights, 'Expect no rights');
    }
}
