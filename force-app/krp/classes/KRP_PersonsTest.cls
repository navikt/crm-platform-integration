@IsTest
/**
 * Simplified version of TPS_PersonsTest, as KRP_Persons does not have
 * functionality for updating.
 */
private with sharing class KRP_PersonsTest {
    @IsTest
    static void getBankkontoTest() {
        Person__c person = new Person__c(
            Name = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );
        insert person;
        KRP_Konto bankkonto = new KRP_Konto();
        bankkonto.kontonummer = '1046.03.53203';
        ApiMock.setTestMock(KRP_CalloutService.SERVICES.POST_HENT_AKTIV_KONTO.name(), 200, 'OK');
        Test.startTest();
        KRP_Konto retkonto = KRP_Persons.getBankkonto(person.Name);
        Test.stopTest();
        System.assertEquals(retkonto.kontonummer, bankkonto.kontonummer, 'Expected same as bankkonto.kontonummer');
    }

    @IsTest
    static void getBankkontoSuccess() {
        KRP_Konto result;
        ApiMock.setTestMock(KRP_CalloutService.SERVICES.POST_HENT_AKTIV_KONTO.name(), 200, 'OK');
        Test.startTest();
        try {
            result = KRP_Persons.getBankkonto('123456789');
        } catch (Exception e) {
            System.assert(false, e);
        }
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected a result');
    }

    @IsTest
    static void getBankkonto401() {
        KRP_Konto result;
        ApiMock.setTestMock(KRP_CalloutService.SERVICES.POST_HENT_AKTIV_KONTO.name(), 401, 'go away');
        Test.startTest();
        try {
            result = KRP_Persons.getBankkonto('123456789');
        } catch (KRP_Persons.KRP_PersonsException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected one log from KRP_PersonsException');
    }

    @IsTest
    static void getBankkontoHttpException() {
        KRP_Konto result;
        Test.setMock(HttpCalloutMock.class, null);
        Test.startTest();
        try {
            KRP_Persons.getBankkonto('123456789');
        } catch (KRP_Persons.KRP_PersonsException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}
