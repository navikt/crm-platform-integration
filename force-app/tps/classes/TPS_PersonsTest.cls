@IsTest
private with sharing class TPS_PersonsTest {
    @IsTest
    static void getBankkontoAndUpdatePerson() {
        Person__c person = new Person__c(
            Name = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );
        insert person;

        TPS_Bankkonto bankkonto = new TPS_Bankkonto();
        bankkonto.endringstidspunkt = Date.today();
        bankkonto.bankkontoNorge = new TPS_Bankkonto.BankkontonummerNorge();
        bankkonto.bankkontoNorge.bankkontonummer = '1234.56.78901';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(bankkonto, true), null)
        );

        Test.startTest();
        TPS_Persons.getBankkonto(person.Name, true);
        Test.stopTest();

        person = [
            SELECT Id, INT_BankAccountNumber__c, INT_BankAccountNumberLastModified__c
            FROM Person__c
            WHERE Id = :person.Id
        ];

        System.assertEquals(
            bankkonto.endringstidspunkt,
            person.INT_BankAccountNumberLastModified__c,
            'Expected same as endringstidspunkt'
        );
        System.assertEquals(
            bankkonto.bankkontoNorge.bankkontonummer,
            person.INT_BankAccountNumber__c,
            'Expected same as bankkontoNorge.bankkontonummer'
        );
    }

    @IsTest
    static void getBankkontoAndUpdatePersonNullValue() {
        Person__c person = new Person__c(
            Name = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME',
            INT_BankAccountNumber__c = '123456789',
            INT_BankAccountNumberLastModified__c = Date.today()
        );
        insert person;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', '', null));

        Test.startTest();
        TPS_Persons.getBankkonto(person.Name, true);
        Test.stopTest();

        person = [
            SELECT Id, INT_BankAccountNumber__c, INT_BankAccountNumberLastModified__c
            FROM Person__c
            WHERE Id = :person.Id
        ];

        System.assertEquals(null, person.INT_BankAccountNumberLastModified__c, 'Expected null');
        System.assertEquals(null, person.INT_BankAccountNumber__c, 'Expected null');
    }

    @IsTest
    static void addBankAccountNumberToPersonBlankValue() {
        Person__c person = new Person__c();
        TPS_Bankkonto bankkonto = new TPS_Bankkonto();

        Test.startTest();
        TPS_Persons.addBankAccountNumberToPerson(person, bankkonto);
        Test.stopTest();

        System.assertEquals(null, person.INT_BankAccountNumber__c, 'Expected null');
        System.assertEquals(null, person.INT_BankAccountNumberLastModified__c, 'Expected null');
    }

    @IsTest
    static void addBankAccountNumberToPersonUpdateBankAccount() {
        Person__c person = new Person__c();
        person.INT_BankAccountNumber__c = '1234567890';
        person.INT_BankAccountNumberLastModified__c = Date.today().addDays(-10);

        TPS_Bankkonto bankkonto = new TPS_Bankkonto();
        bankkonto.endringstidspunkt = Date.today();
        bankkonto.bankkontoNorge = new TPS_Bankkonto.BankkontonummerNorge();
        bankkonto.bankkontoNorge.bankkontonummer = '0987654321';

        Test.startTest();
        TPS_Persons.addBankAccountNumberToPerson(person, bankkonto);
        Test.stopTest();

        System.assertEquals('0987654321', person.INT_BankAccountNumber__c, 'Expected new bank account number');
        System.assertEquals(Date.today(), person.INT_BankAccountNumberLastModified__c, 'Expected updated date');
    }

    @IsTest
    static void addBankAccountNumberForeignBank() {
        Person__c person = new Person__c();
        person.INT_BankAccountNumber__c = '1234567890';
        person.INT_BankAccountNumberLastModified__c = Date.today().addDays(-10);

        TPS_Bankkonto bankkonto = new TPS_Bankkonto();
        bankkonto.endringstidspunkt = Date.today();
        bankkonto.bankkontoUtland = new TPS_Bankkonto.BankkontonummerUtland();
        bankkonto.bankkontoUtland.bankkontonummer = '0987654321';

        Test.startTest();
        TPS_Persons.addBankAccountNumberToPerson(person, bankkonto);
        Test.stopTest();

        System.assertEquals('0987654321', person.INT_BankAccountNumber__c, 'Expected new bank account number');
        System.assertEquals(Date.today(), person.INT_BankAccountNumberLastModified__c, 'Expected updated date');
    }

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
