@IsTest
public with sharing class NKS_SkattekortTest {
    @IsTest
    static void getSkattekortV2WithSerialize() {
        // Create skattekortListe instance and list. Assign pointer.
        List<NKS_SkattekortWrapperV2> skattekortWrapper = new List<NKS_SkattekortWrapperV2>();
        NKS_SkattekortWrapperV2 skattekortInstance = new NKS_SkattekortWrapperV2();

        // Create arbeidsgiver instance and list. Assign pointer.
        NKS_SkattekortWrapperV2.Arbeidsgiver arbeidsgiver = new NKS_SkattekortWrapperV2.Arbeidsgiver();
        List<NKS_SkattekortWrapperV2.Arbeidsgiver> arbeidsgiverListe = new List<NKS_SkattekortWrapperV2.Arbeidsgiver>();
        skattekortInstance.arbeidsgiver = arbeidsgiverListe;

        // Create arbeidsgiveridentifikator instance. Assign pointer.
        NKS_SkattekortWrapperV2.Arbeidsgiveridentifikator arbeidsgiverIdentifikator = new NKS_SkattekortWrapperV2.Arbeidsgiveridentifikator();
        arbeidsgiver.arbeidsgiveridentifikator = arbeidsgiverIdentifikator;

        // Create arbeidstaker instance and list. Assign pointer.
        NKS_SkattekortWrapperV2.Arbeidstaker arbeidstaker = new NKS_SkattekortWrapperV2.Arbeidstaker();
        List<NKS_SkattekortWrapperV2.Arbeidstaker> arbeidstakerListe = new List<NKS_SkattekortWrapperV2.Arbeidstaker>();
        arbeidsgiver.arbeidstaker = arbeidstakerListe;

        // Create skattekort instance. Assign pointer.
        NKS_SkattekortWrapperV2.Skattekort skattekort = new NKS_SkattekortWrapperV2.Skattekort();
        arbeidstaker.skattekort = skattekort;

        // Create forskuddstrekk instance and list. Assign pointer.
        NKS_SkattekortWrapperV2.Forskuddstrekk forskuddstrekk = new NKS_SkattekortWrapperV2.Forskuddstrekk();
        List<NKS_SkattekortWrapperV2.Forskuddstrekk> forskuddstrekkListe = new List<NKS_SkattekortWrapperV2.Forskuddstrekk>();
        skattekort.forskuddstrekk = forskuddstrekkListe;

        // Assign arbeidsgiverIdentifikator variables
        arbeidsgiveridentifikator.organisasjonsnummer = '910962728';
        arbeidsgiverIdentifikator.personidentifikator = '123456789';

        // Assign arbeidstaker variables
        arbeidstaker.inntektsaar = 2022;
        arbeidstaker.arbeidstakeridentifikator = '03063300267';
        arbeidstaker.resultatPaaForespoersel = 'skattekortopplysningerOK';
        arbeidstaker.tilleggsopplysning = new List<String>{ 'oppholdPaaSvalbard' };

        // Assign skattekort variables
        skattekort.inntektsaar = 0;
        skattekort.utstedtDato = '2022-01-25';
        skattekort.skattekortidentifikator = 188547;

        // Assign forskuddstrekk variables
        forskuddstrekk.type = 'Trekkprosent';
        forskuddstrekk.trekkode = 'ufoeretrygdFraNAV';
        forskuddstrekk.prosentsats = 15.0;
        forskuddstrekk.antallMaanederForTrekk = 12.0;
        forskuddstrekk.frikortbeloep = '50 000';
        forskuddstrekk.tabellnummer = '2701';
        forskuddstrekk.tabelltype = 'trekktabellForLoenn';

        // Add instances to lists
        forskuddstrekkListe.add(forskuddstrekk);
        arbeidstakerListe.add(arbeidstaker);
        arbeidsgiverListe.add(arbeidsgiver);
        skattekortWrapper.add(skattekortInstance);

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(skattekortWrapper, true), null)
        );

        List<NKS_SkattekortWrapperV2> result;
        Test.startTest();
        result = NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Returned value should not be null');
    }

    @IsTest
    static void getSkattekortV2Success() {
        List<NKS_SkattekortWrapperV2> result;
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new List<NKS_SkattekortWrapperV2>(), true), null)
        );

        Test.startTest();
        try {
            result = NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        } catch (Exception e) {
            System.assert(false, e);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a result');
    }

    @IsTest
    static void getSkattekortV2400() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(400, 'Unauthorized', 'Ugyldig request, oppfyller ikke swagger-kontrakt', null)
        );
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekortV2401() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(401, 'Unauthorized', 'Ingen tilgang', null));
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekortV2500() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(500, 'Unauthorized', 'Annen feil', null));
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getSkattekortV2HttpException() {
        Test.setMock(HttpCalloutMock.class, null);
        Test.startTest();
        try {
            NKS_Skattekort.getSkattekortV2('03063300267', '2022');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}
