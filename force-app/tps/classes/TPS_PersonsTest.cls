@IsTest
private with sharing class TPS_PersonsTest {
    @IsTest
    static void getBankkontoSuccess() {
        TPS_Bankkonto result;
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new TPS_Bankkonto(), true), null)
        );

        Test.startTest();
        try {
            result = TPS_Persons.getBankkonto('123456789');
        } catch (Exception e) {
            System.assert(false, e);
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected a result');
    }

    @IsTest
    static void getBankkonto401() {
        TPS_Bankkonto result;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(401, 'Unauthorized', 'Giltigt token saknas', null));

        Test.startTest();
        try {
            TPS_Persons.getBankkonto('123456789');
        } catch (TPS_Persons.TPS_PersonsException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }

    @IsTest
    static void getBankkontoHttpException() {
        TPS_Bankkonto result;

        Test.setMock(HttpCalloutMock.class, null);

        Test.startTest();
        try {
            TPS_Persons.getBankkonto('123456789');
        } catch (TPS_Persons.TPS_PersonsException e) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Wrong exception: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c], 'Expected only one log');
    }
}
