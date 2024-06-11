@IsTest
private with sharing class AltinnCalloutServiceTest {
    @TestSetup
    static void makeData() {
        BaseTestFactory.insertEncryptionKey();
    }

    @IsTest
    private static void getOrganizations() {
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp = new AltinnCalloutService()
            .getOrganizations('12345678901');
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
        System.assertEquals(18, resp.organizations.size(), 'Expect 18 organaizations');
    }

    @IsTest
    private static void getOrganizations_when500Error() {
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 500, 'Server error');

        Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp = new AltinnCalloutService()
            .getOrganizations('12345678901');
        Test.stopTest();

        System.assertEquals(false, resp.success, 'Expect error');
        System.assert(
            resp.errorMessage.contains('Kunne ikke hente organisasjoner fra Altinn.'),
            'Expect error message'
        );
        System.assertEquals(null, resp.organizations, 'Expect no organaizations');
    }

    @IsTest
    private static void getRights() {
        ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = new AltinnCalloutService()
            .getRights('12345678901', '87231908');
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
        System.assertEquals(51, resp.rights.size(), 'Expect 51 rights');
    }

     @IsTest
    private static void getRights_filterOnServiceCode() {
        ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = new AltinnCalloutService()
            .getRights('12345678901', '87231908', '5719');
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
        System.assertEquals(51, resp.rights.size(), 'Expect 51 rights');
    }

    @IsTest
    private static void getRights_when500Error() {
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 500, 'Server error');

        Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = new AltinnCalloutService()
            .getRights('12345678901', '87231908');
        Test.stopTest();

        System.assertEquals(false, resp.success, 'Expect error');
        System.assert(resp.errorMessage.contains('Kunne ikke hente rettigheter fra Altinn.'), 'Expect error message');
        System.assertEquals(null, resp.rights, 'Expect no rights');
    }

    /*@IsTest
    static void testGetMaskinportenTokenMethodPlatformCachePositive(){

        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.tokens');
        AltinnCalloutService altinnCalloutService = new AltinnCalloutService();

        System.Test.startTest();
        /*orgPartition.put(
            'altinntokendata',
            'abcdefghijklmnopqrstuv=',
            300
        );*/
                    
        /*String accessToken = altinnCalloutService.getMaskinportenToken();
        System.debug('accessToken: ' + accessToken);
        String accessToken2 = altinnCalloutService.getMaskinportenToken();
        System.debug('accessToken2: ' + accessToken2);

        MaskinportenService.AuthResponse testResponse = new MaskinportenService.AuthResponse();
        testResponse.access_token = 'access_token_test';
        testResponse.expires_in = 119;
        testResponse.created_at = Datetime.now().addSeconds(-210);//.format('yyyy-MM-dd HH:mm:ss');
        testResponse.scope = 'test_scope';

        orgPartition.put(
            'altinntokendata',
            CryptoService.encryptString(JSON.serialize(testResponse)),
            300
        );

        String accessToken3 = altinnCalloutService.getMaskinportenToken();
        System.debug('accessToken3: ' + accessToken3);
        String accessToken4 = altinnCalloutService.getMaskinportenToken();
        System.debug('accessToken4: ' + accessToken4);

        testResponse.access_token = 'access_token_test';
        testResponse.expires_in = 119;
        testResponse.created_at = Datetime.now().addSeconds(-210);//.format('yyyy-MM-dd HH:mm:ss');
        testResponse.scope = 'test_scope';

        orgPartition.put(
            'altinntokendata',
            CryptoService.encryptString(JSON.serialize(testResponse)),
            300
        );


        String accessToken5 = altinnCalloutService.getMaskinportenToken();
        System.debug('accessToken5: ' + accessToken5);
        System.Test.stopTest();
        
        String tokenData = (String) orgPartition.get('altinntokendata');

        String decryptedTokenData = CryptoService.decryptString(tokenData);
        Map<String, Object> tokenDataMap = (Map<String, Object>) JSON.deserializeUntyped(decryptedTokenData);
        accessToken = (String) tokenDataMap.get('access_token');
        Integer expiresIn = (Integer) tokenDataMap.get('expires_in');
        String createdAt = (String) tokenDataMap.get('created_at');
        String scope = (String) tokenDataMap.get('scope');

        System.debug('accessToken: ' + accessToken);
        System.debug('expiresIn: ' + expiresIn);
        System.debug('createdAt: ' + createdAt);
        System.debug('scope: ' + scope);
        System.Assert.areEqual('access_token_test', accessToken, 'Access token should be the same');
        
    }*/
}
