@IsTest
public with sharing class NKS_SkattekortTest {
    @IsTest
    static void getSkattekortAndUpdatePerson() {
        Person__c person = new Person__c(
            Name = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );
        insert person;

        NKS_SkattekortWrapper skattekort = new NKS_SkattekortWrapper();
        skattekort.skattekortListe = new NKS_SkattekortWrapper.SkattekortListe();
        skattekort.skattekortListe.arbeidsgiver = new NKS_SkattekortWrapper.SkattekortListe.Arbeidsgiver();
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker = new NKS_SkattekortWrapper.SkattekortListe.Arbeidsgiver.Arbeidstaker();
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker.skattekort = new NKS_SkattekortWrapper.SkattekortListe.Arbeidsgiver.Arbeidstaker.Skattekort();
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker.skattekort.forskuddstrekk = '';
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker.skattekort.inntektsaar = '0';
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker.skattekort.skattekortidentifikator = '0'; 
        skattekort.skattekortListe.arbeidsgiver.arbeidstaker.skattekort.utstedtDato = '2023-01-18';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(skattekort, true), null)
        );
        
        Test.startTest();
        NKS_Skattekort.getSkattekort(person.Name, '2023');
        Test.stopTest();
    }

    

    @IsTest
    static void getSkattekortSuccess() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new NKS_SkattekortWrapper(), true), null)
        );

        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void getSkattekort400() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Unauthorized', 'Ugyldig request, oppfyller ikke swagger-kontrakt', null));
        
        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void getSkattekort401() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(401, 'Unauthorized', 'Ingen tilgang', null));
        
        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void getSkattekort500() {
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(500, 'Unauthorized', 'Annen feil', null));
        
        Test.startTest();
        Test.stopTest();
    }

    @IsTest
    static void getSkattekortHttpException() {
        Test.setMock(HttpCalloutMock.class, null);
        
        Test.startTest();
        Test.stopTest();
    }
}