@IsTest
public with sharing class NKS_SkattekortTest {
    @IsTest
    static void getSkattekortAndUpdatePerson() {
        // TODO: Do JSON.serialize instead to get coverage on SkattekortWrapper class
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', '{"skattekortListe": [{"arbeidsgiver": [{"arbeidstaker": [{"inntektsaar": 0, "arbeidstakeridentifikator": "string", "resultatPaaForespoersel": "ikkeSkattekort", "skattekort": {"inntektsaar": 0, "utstedtDato": "2023-01-20", "skattekortidentifikator": 0, "forskuddstrekk": {}}, "tilleggsopplysning": "string"}], "arbeidsgiveridentifikator": {"organisasjonsnummer": "string", "personidentifikator": "string"}}]}]}', null)
        );
        
        NKS_SkattekortWrapper result;
        Test.startTest();
        result = NKS_Skattekort.getSkattekort('03063300267', '2022');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Returned value should not be null');
    }

    
    @IsTest
    static void getSkattekortSuccess() {
        NKS_SkattekortWrapper result;
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new NKS_SkattekortWrapper(), true), null)
        );

        Test.startTest();
        try {
            result = NKS_Skattekort.getSkattekort('03063300267', '2022');
        } catch (Exception e) {
            System.assert(false, e);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a result');
    }

    @IsTest
    static void getSkattekort400() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Unauthorized', 'Ugyldig request, oppfyller ikke swagger-kontrakt', null));
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekort401() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(401, 'Unauthorized', 'Ingen tilgang', null));
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekort500() {        
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(500, 'Unauthorized', 'Annen feil', null));
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekortHttpException() {
        Test.setMock(HttpCalloutMock.class, null);
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}