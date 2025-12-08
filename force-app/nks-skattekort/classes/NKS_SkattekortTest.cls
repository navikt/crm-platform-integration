@isTest
private with sharing class NKS_SkattekortTest {
    @IsTest // Ensure code coverage for wrapper class
    static void getSkattekortWithSerialize() {
        // Create test data matching the actual API response structure
        List<NKS_SkattekortWrapper> skattekortWrapper = new List<NKS_SkattekortWrapper>();
        
        // Create first tax card entry
        NKS_SkattekortWrapper wrapper1 = new NKS_SkattekortWrapper();
        wrapper1.inntektsaar = 2025;
        wrapper1.arbeidstakeridentifikator = '09910497658';
        wrapper1.resultatPaaForespoersel = 'skattekortopplysningerOK';
        wrapper1.tilleggsopplysning = new List<String>();

        // Create skattekort for first entry
        NKS_SkattekortWrapper.Skattekort skattekort1 = new NKS_SkattekortWrapper.Skattekort();
        skattekort1.utstedtDato = '2025-12-08';
        skattekort1.skattekortidentifikator = 75533;

        // Create forskuddstrekk instances matching actual API response
        NKS_SkattekortWrapper.Forskuddstrekk forskudd1 = new NKS_SkattekortWrapper.Forskuddstrekk();
        forskudd1.type = 'Trekkprosent';
        forskudd1.trekkode = 'LOENN_FRA_NAV';
        forskudd1.prosentsats = 47.00;

        NKS_SkattekortWrapper.Forskuddstrekk forskudd2 = new NKS_SkattekortWrapper.Forskuddstrekk();
        forskudd2.type = 'Trekkprosent';
        forskudd2.trekkode = 'UFOERETRYGD_FRA_NAV';
        forskudd2.prosentsats = 47.00;

        // Build the structure
        List<NKS_SkattekortWrapper.Forskuddstrekk> forskuddstrekkListe = new List<NKS_SkattekortWrapper.Forskuddstrekk>();
        forskuddstrekkListe.add(forskudd1);
        forskuddstrekkListe.add(forskudd2);
        
        skattekort1.forskuddstrekk = forskuddstrekkListe;
        wrapper1.skattekort = skattekort1;
        skattekortWrapper.add(wrapper1);

        // Create second tax card entry
        NKS_SkattekortWrapper wrapper2 = new NKS_SkattekortWrapper();
        wrapper2.inntektsaar = 2025;
        wrapper2.arbeidstakeridentifikator = '09910497658';
        wrapper2.resultatPaaForespoersel = 'skattekortopplysningerOK';
        wrapper2.tilleggsopplysning = new List<String>();

        NKS_SkattekortWrapper.Skattekort skattekort2 = new NKS_SkattekortWrapper.Skattekort();
        skattekort2.utstedtDato = '2025-12-06';
        skattekort2.skattekortidentifikator = 74101;
        skattekort2.forskuddstrekk = forskuddstrekkListe;
        wrapper2.skattekort = skattekort2;
        skattekortWrapper.add(wrapper2);

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(skattekortWrapper, true), null)
        );

        List<NKS_SkattekortWrapper> result;
        Test.startTest();
        result = NKS_Skattekort.getSkattekort('14859898638', '2025');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Returned value should not be null');
    }

    @IsTest
    static void getSkattekortSuccess() {
        ApiMock.setTestMock('POST_SKATTEKORT_API', 200, 'OK');

        List<NKS_SkattekortWrapper> result;
        Test.startTest();
        try {
            result = NKS_Skattekort.getSkattekort('14859898638', '2025');
        } catch (Exception e) {
            System.assert(false, e);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a result');
    }

    @IsTest
    static void getSkattekort400() {
        ApiMock.setTestMock('POST_SKATTEKORT_API', 400, 'Unauthorized');

        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('14859898638', '2025');
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
        ApiMock.setTestMock('POST_SKATTEKORT_API', 401, 'Unauthorized');

        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('14859898638', '2025');
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
        ApiMock.setTestMock('POST_SKATTEKORT_API', 500, 'Unauthorized');

        Test.startTest();
        try {
            NKS_Skattekort.getSkattekort('14859898638', '2025');
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
            NKS_Skattekort.getSkattekort('14859898638', '2025');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}
