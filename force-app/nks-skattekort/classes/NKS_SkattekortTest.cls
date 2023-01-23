@IsTest
public with sharing class NKS_SkattekortTest {
    @IsTest
    static void getSkattekortAndUpdatePerson() {
        // Create skattekortListe instance and list. Assign pointer.
        NKS_SkattekortWrapper skattekortWrapper = new NKS_SkattekortWrapper();
        NKS_SkattekortWrapper.SkattekortListe skattekortListeInstance = new NKS_SkattekortWrapper.SkattekortListe();
        List<NKS_SkattekortWrapper.SkattekortListe> skattekortliste = new List<NKS_SkattekortWrapper.SkattekortListe>();
        skattekortWrapper.skattekortListe = skattekortliste;
        
        // Create arbeidsgiver instance and list. Assign pointer.
        NKS_SkattekortWrapper.Arbeidsgiver arbeidsgiver = new NKS_SkattekortWrapper.Arbeidsgiver();
        List<NKS_SkattekortWrapper.Arbeidsgiver> arbeidsgiverListe = new List<NKS_SkattekortWrapper.Arbeidsgiver>();
        skattekortListeInstance.arbeidsgiver = arbeidsgiverListe;

        // Create arbeidsgiveridentifikator instance. Assign pointer.
        NKS_SkattekortWrapper.Arbeidsgiveridentifikator arbeidsgiverIdentifikator = new NKS_SkattekortWrapper.Arbeidsgiveridentifikator();
        arbeidsgiver.arbeidsgiveridentifikator = arbeidsgiverIdentifikator;

        // Create arbeidstaker instance and list. Assign pointer.
        NKS_SkattekortWrapper.Arbeidstaker arbeidstaker = new NKS_SkattekortWrapper.Arbeidstaker();
        List<NKS_SkattekortWrapper.Arbeidstaker> arbeidstakerListe = new List<NKS_SkattekortWrapper.Arbeidstaker>();
        arbeidsgiver.arbeidstaker = arbeidstakerListe;

        // Create skattekort instance. Assign pointer.
        NKS_SkattekortWrapper.Skattekort skattekort = new NKS_SkattekortWrapper.Skattekort();
        arbeidstaker.skattekort = skattekort;

        // Create forskuddstrekk instance and list. Assign pointer.
        NKS_SkattekortWrapper.Forskuddstrekk forskuddstrekk = new NKS_SkattekortWrapper.Forskuddstrekk();
        List<NKS_SkattekortWrapper.Forskuddstrekk> forskuddstrekkListe = new List<NKS_SkattekortWrapper.Forskuddstrekk>();
        skattekort.forskuddstrekk = forskuddstrekkListe;

        // Assign arbeidsgiverIdentifikator variables
        arbeidsgiveridentifikator.organisasjonsnummer = '910962728';
        arbeidsgiverIdentifikator.personidentifikator = '123456789';

        // Assign arbeidstaker variables
        arbeidstaker.inntektsaar = 2022;
        arbeidstaker.arbeidstakeridentifikator = '03063300267';
        arbeidstaker.resultatPaaForespoersel = 'skattekortopplysningerOK';
        arbeidstaker.tilleggsopplysning = new List<String>{'oppholdPaaSvalbard'};

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
        skattekortliste.add(skattekortListeInstance);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', JSON.serialize(skattekortWrapper, true), null));
        
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