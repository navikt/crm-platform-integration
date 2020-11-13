@IsTest
private class PersonHandlerTest {

    @IsTest
    static void testConfidentialPersonNullsAccountNamesOnUpdate() {
        // Arrange
        Person__c person = BaseTestFactory.getPerson();
        insert person;
        Account account = [SELECT Id, FirstName, MiddleName, LastName, INT_PersonIdent__c FROM Account WHERE CRM_Person__c = :person.Id];
        System.assertEquals(person.INT_FirstName__c, account.FirstName);
        System.assertEquals(person.INT_MiddleName__c, account.MiddleName);
        System.assertEquals(person.INT_LastName__c, Account.LastName);
        System.assertEquals(person.Name, Account.INT_PersonIdent__c);

        // Act
        Test.startTest();
        person.INT_Confidential__c = 'STRENGT_FORTROLIG';
        update person;
        Test.stopTest();

        // Assert
        Account confidentialAccount = [SELECT Id, FirstName, MiddleName, LastName, INT_PersonIdent__c FROM Account WHERE CRM_Person__c = :person.Id];
        System.debug(confidentialAccount.FirstName);
        System.assert(String.isBlank(confidentialAccount.FirstName));
        System.assert(String.isBlank(confidentialAccount.MiddleName));
        System.assertEquals('IKKE TILGJENGELIG', confidentialAccount.LastName);
        System.assertEquals(person.Name, confidentialAccount.INT_PersonIdent__c);
    }

    @IsTest
    static void testConfidentialPersonNullsAccountNamesOnInsert() {
        // Arrange
        Person__c confidentialPerson = BaseTestFactory.getPerson();
        confidentialPerson.INT_Confidential__c = 'FORTROLIG';

        // Act
        Test.startTest();
        insert confidentialPerson;
        Test.stopTest();

        // Assert
        Account confidentialAccount = [SELECT Id, FirstName, MiddleName, LastName, INT_PersonIdent__c FROM Account WHERE CRM_Person__c = :confidentialPerson.Id];
        System.assert(String.isBlank(confidentialAccount.FirstName));
        System.assert(String.isBlank(confidentialAccount.MiddleName));
        System.assertEquals('IKKE TILGJENGELIG', confidentialAccount.LastName);
        System.assertEquals(confidentialPerson.Name, confidentialAccount.INT_PersonIdent__c);
    }

    @IsTest
    static void testCreateRelatedAccountsBulk() {
        // Arrange
        List<Person__c> personsToInsert = new List<Person__c>();
        for (Integer i = 0; i < 200; i++) {
            personsToInsert.add(BaseTestFactory.getPerson());
        }
        System.assertEquals(0, [SELECT Count() FROM Account]);
        System.assertEquals(0, [SELECT Count() FROM Person__c]);

        // Act
        Test.startTest();
        insert personsToInsert;
        Test.stopTest();

        // Assert
        System.assertEquals(200, [SELECT Count() FROM Person__c]);
        System.assertEquals(200, [SELECT Count() FROM Account]);
        for(Person__c person : [SELECT Id, Name, INT_FirstName__c, INT_MiddleName__c, INT_LastName__c, CRM_Account__r.INT_PersonIdent__c, CRM_Account__r.FirstName, CRM_Account__r.MiddleName, CRM_Account__r.LastName FROM Person__c]) {
            System.assertEquals(person.CRM_Account__r.INT_PersonIdent__c, person.Name);
            System.assertEquals(person.CRM_Account__r.FirstName, person.INT_FirstName__c);
            System.assertEquals(person.CRM_Account__r.MiddleName, person.INT_MiddleName__c);
            System.assertEquals(person.CRM_Account__r.LastName, person.INT_LastName__c);
        }
    }

    @IsTest
    static void testUpdateRelatedAccountsBulk() {
        // Arrange
        List<Person__c> personsToInsert = new List<Person__c>();
        for (Integer i = 0; i < 200; i++) {
            personsToInsert.add(BaseTestFactory.getPerson());
        }
        insert personsToInsert;
        System.assertEquals(200, [SELECT Count() FROM Account]);
        System.assertEquals(200, [SELECT Count() FROM Person__c]);

        for(Person__c person : personsToInsert) {
            person.INT_FirstName__c += 'Updated';
            person.INT_MiddleName__c += 'Updated';
            person.INT_LastName__c += 'Updated';
            person.Name = String.valueOf(Long.valueOf(person.Name) + 1);
        }

        // Act
        Test.startTest();
        update personsToInsert;
        Test.stopTest();

        // Assert
        for(Person__c person : [SELECT Id, Name, INT_FirstName__c, INT_MiddleName__c, INT_LastName__c, CRM_Account__r.INT_PersonIdent__c, CRM_Account__r.FirstName, CRM_Account__r.MiddleName, CRM_Account__r.LastName FROM Person__c]) {
            System.assertEquals(person.CRM_Account__r.INT_PersonIdent__c, person.Name);
            System.assertEquals(person.CRM_Account__r.FirstName, person.INT_FirstName__c);
            System.assertEquals(person.CRM_Account__r.MiddleName, person.INT_MiddleName__c);
            System.assertEquals(person.CRM_Account__r.LastName, person.INT_LastName__c);
        }
    }


}