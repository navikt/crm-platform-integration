@IsTest
public class KrrCalloutServiceTest {

    @isTest
    public static void testEndpoint(){
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{\"personer\":{\"additionalProp1\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}},\"additionalProp2\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}},\"additionalProp3\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}}},\"feil\":{\"additionalProp1\":\"string\",\"additionalProp2\":\"string\",\"additionalProp3\":\"string\"}}', null));

        Test.startTest();
        List<KrrCalloutService.Person> ls = KrrCalloutService.doPersonOppslag2(new List<String>{'1234456'}, null, false);
        Test.stopTest();
        System.assert(ls.size() == 3, 'JSON Parser returned unexpected amount of person records.');
        System.assert(ls[0].epostadresse == 'string', 'First result incorrectly returned.');
    }

    //OLD CODE FOR TRANSITION TO NEW INTEGRATION
    @IsTest
    public static void testSingleSuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '01048800153' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(1, personer.size());
        System.assertEquals(personer[0].personidentifikator, '01048800153');
        System.assertEquals(personer[0].kontaktinformasjon.epostadresse, '01048800153-test@minid.norge.no');
        System.assertEquals(personer[0].kontaktinformasjon.mobiltelefonnummer, '+4799999999');
    }

    @IsTest
    public static void testMultipleSuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"01048800153","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01048800153-test@minid.norge.no","epostadresse_sist_verifisert":"2020-01-14T17:57:58+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2020-01-14T17:57:58+01"}},{"personidentifikator":"01066100746","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_VARSLES","kontaktinformasjon":{"epostadresse":"01066100746-test@minid.norge.no","epostadresse_sist_verifisert":"2018-11-05T15:27:22+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_sist_verifisert":"2018-11-05T15:27:22+01"}},{"personidentifikator":"27129323960","reservasjon":"NEI","status":"AKTIV","varslingsstatus":"KAN_IKKE_VARSLES","kontaktinformasjon":{"epostadresse":"27129323960-test@minid.norge.no","epostadresse_oppdatert":"2015-03-11T19:59:13+01","mobiltelefonnummer":"+4799999999","mobiltelefonnummer_oppdatert":"2015-03-11T19:59:13+01"}}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '01048800153', '01066100746', '27129323960' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(3, personer.size());
        System.assertEquals(personer[0].personidentifikator, '01048800153');
        System.assertEquals(personer[0].kontaktinformasjon.epostadresse, '01048800153-test@minid.norge.no');
        System.assertEquals(personer[1].personidentifikator, '01066100746');
        System.assertEquals(personer[1].kontaktinformasjon.epostadresse, '01066100746-test@minid.norge.no');
        System.assertEquals(personer[2].personidentifikator, '27129323960');
        System.assertEquals(personer[2].kontaktinformasjon.epostadresse, '27129323960-test@minid.norge.no');
    }

    @IsTest
    public static void testSingleUnsuccesfulPersonOppslag() {
        // Get the KRR maskinporten client in order to map the endpoint to a mock response
        MaskinportenClient__mdt krrClient = [
            SELECT Endpoint__c
            FROM Maskinportenclient__mdt
            WHERE DeveloperName = :Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr'
            LIMIT 1
        ];

        // Construct mock responses for all callouts that will be performed
        SingleRequestMock maskinPortenResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"access_token": "super-secret-access-token", "token_type": "Bearer", "expires_in": 119, "scope": "global/kontaktinformasjon.read global/spraak.read global/sikkerdigitalpost.read global/varslingsstatus.read"}',
            null
        );
        SingleRequestMock krrResponse = new SingleRequestMock(
            200,
            'Complete',
            '{"personer":[{"personidentifikator":"24999412372","status":"IKKE_REGISTRERT","varslingsstatus":"KAN_IKKE_VARSLES"}]}',
            null
        );

        // Map responses to callout endpoints and set mock
        Map<String, HttpCalloutMock> mockResponseByEndpoint = new Map<String, HttpCalloutMock>();
        mockResponseByEndpoint.put(krrClient.Endpoint__c, maskinPortenResponse);
        mockResponseByEndpoint.put('https://difiKrrExampleEndpoint.no', krrResponse);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(mockResponseByEndpoint);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Test.startTest();
        List<KRRCalloutService.Personer> personer = KrrCalloutService.doPersonOppslag(
            new List<String>{ '24999412372' }
        );
        Test.stopTest();

        // Assert that result has been correctly parsed
        System.assertEquals(1, personer.size());
        System.assertEquals(personer[0].personidentifikator, '24999412372');
        System.assertEquals(personer[0].kontaktinformasjon, null);
    }
}