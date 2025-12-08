@isTest
private with sharing class NKS_SkattekortTest {
    @IsTest // Ensure code coverage for wrapper class
    static void getSkattekortWithSerialize() {
        // Create skattekortWrapper instance
        List<NKS_SkattekortWrapper> skattekortWrapper = new List<NKS_SkattekortWrapper>();
        NKS_SkattekortWrapper wrapper = new NKS_SkattekortWrapper();
        wrapper.navn = 'TEST PERSON';

        // Create arbeidsgiver
        NKS_SkattekortWrapper.Arbeidsgiver arbeidsgiver = new NKS_SkattekortWrapper.Arbeidsgiver();
        
        // Create arbeidsgiveridentifikator
        NKS_SkattekortWrapper.Arbeidsgiveridentifikator arbeidsgiveridentifikator = new NKS_SkattekortWrapper.Arbeidsgiveridentifikator();
        arbeidsgiveridentifikator.organisasjonsnummer = '910962728';
        arbeidsgiver.arbeidsgiveridentifikator = arbeidsgiveridentifikator;

        // Create arbeidstaker
        NKS_SkattekortWrapper.Arbeidstaker arbeidstaker = new NKS_SkattekortWrapper.Arbeidstaker();
        arbeidstaker.inntektsaar = 2025;
        arbeidstaker.arbeidstakeridentifikator = '14859898638';
        arbeidstaker.resultatPaaForespoersel = 'skattekortopplysningerOK';
        arbeidstaker.tilleggsopplysning = new List<String>{'oppholdPaaSvalbard'};

        // Create skattekort
        NKS_SkattekortWrapper.Skattekort skattekort = new NKS_SkattekortWrapper.Skattekort();
        skattekort.utstedtDato = '2025-01-25';
        skattekort.skattekortidentifikator = 188547;

        // Create forskuddstrekk instances
        NKS_SkattekortWrapper.Forskuddstrekk trekkprosent = new NKS_SkattekortWrapper.Forskuddstrekk();
        trekkprosent.type = 'Trekkprosent';
        trekkprosent.trekkode = 'ufoeretrygdFraNAV';
        trekkprosent.prosentsats = 15.0;
        trekkprosent.antallMaanederForTrekk = 12.0;

        NKS_SkattekortWrapper.Forskuddstrekk frikort = new NKS_SkattekortWrapper.Forskuddstrekk();
        frikort.type = 'Frikort';
        frikort.trekkode = 'frikort';
        frikort.frikortbeloep = 50000.0;

        NKS_SkattekortWrapper.Forskuddstrekk trekktabell = new NKS_SkattekortWrapper.Forskuddstrekk();
        trekktabell.type = 'Trekktabell';
        trekktabell.trekkode = 'trekktabell';
        trekktabell.tabellnummer = '2701';
        trekktabell.prosentsats = 10.0;
        trekktabell.antallMaanederForTrekk = 12.0;

        // Build the structure
        List<NKS_SkattekortWrapper.Forskuddstrekk> forskuddstrekkListe = new List<NKS_SkattekortWrapper.Forskuddstrekk>();
        forskuddstrekkListe.add(trekkprosent);
        forskuddstrekkListe.add(frikort);
        forskuddstrekkListe.add(trekktabell);
        
        skattekort.forskuddstrekk = forskuddstrekkListe;
        arbeidstaker.skattekort = skattekort;
        arbeidsgiver.arbeidstaker = new List<NKS_SkattekortWrapper.Arbeidstaker>{arbeidstaker};
        wrapper.arbeidsgiver = new List<NKS_SkattekortWrapper.Arbeidsgiver>{arbeidsgiver};
        skattekortWrapper.add(wrapper);

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
