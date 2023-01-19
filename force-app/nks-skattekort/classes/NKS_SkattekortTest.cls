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

        NKS_SkattekortWrapper skattekortWrapper = new NKS_SkattekortWrapper();
        skattekortWrapper.skattekortListe = new List<NKS_SkattekortWrapper.SkattekortListe>();
        // TODO: Do JSON.serialize?

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(skattekortWrapper, true), null)
        );
        
        Test.startTest();
        NKS_Skattekort.getSkattekort(person.Name, '2023');
        Test.stopTest();
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
            result = NKS_Skattekort.getSkattekort('12345612345', '2023');
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
            NKS_Skattekort.getSkattekort('12345612345', '2023');
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
            NKS_Skattekort.getSkattekort('12345612345', '2023');
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
            NKS_Skattekort.getSkattekort('12345612345', '2023');
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
            NKS_Skattekort.getSkattekort('12345612345', '2023');
        } catch (NKS_Skattekort.SkattekortException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}