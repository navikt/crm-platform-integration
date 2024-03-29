@IsTest
private with sharing class CRM_PersonMergeTest {
    @TestSetup
    static void makeData() {
        System.runAs(new User(
            LastName = 'RunningUser',
            Email = 'runninguser@nav.no',
            Username = 'sfTestRunningUser' + DateTime.now().getTime().intValue() + '@nav.no.test',
            Alias = 'RUser',
            LanguageLocaleKey = 'no',
            LocaleSidKey = 'no_NO',
            TimeZoneSidKey = 'Europe/Paris',
            EmailEncodingKey = 'UTF-8',
            UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Default' LIMIT 1]
            .Id,
            ProfileId = [SELECT Id FROM Profile WHERE Name LIKE '%admin%' LIMIT 1]
            .Id
        )) {
            Person__c p1 = new Person__c();
            p1.Name = '01234567890';
            p1.INT_fnr__c = p1.Name;
            p1.INT_ActorId__c = '109876543210';
            p1.INT_FirstName__c = 'Tombstone';
            p1.INT_MiddleName__c = 'Tombstone';
            p1.INT_LastName__c = 'Tombstone';
            p1.INT_Confidential__c = 'UGRADERT';
            p1.INT_MunicipalityNumber__c = '1911';
            p1.INT_RegionNumber__c = '19';
            p1.INT_IsDeceased__c = false;
            p1.INT_IsHasTombstone__c = true;

            Person__c p2 = new Person__c();
            p2.Name = '01234567891';
            p2.INT_fnr__c = p2.Name;
            p2.INT_ActorId__c = '109876543211';
            p2.INT_FirstName__c = 'Firstname';
            p2.INT_MiddleName__c = 'Middlename';
            p2.INT_LastName__c = 'Lastname';
            p2.INT_Confidential__c = 'UGRADERT';
            p2.INT_MunicipalityNumber__c = '1911';
            p2.INT_RegionNumber__c = '19';
            p2.INT_IsDeceased__c = false;
            p2.INT_IsHasTombstone__c = false;

            insert new List<Person__c>{ p1, p2 };

            Account accountWithoutPerson1 = new Account();
            accountWithoutPerson1.FirstName = 'Missing';
            accountWithoutPerson1.LastName = 'Person';
            accountWithoutPerson1.RecordTypeId = Account.getSObjectType()
                .getDescribe()
                .recordtypeinfosbydevelopername.get('PersonAccount')
                .getRecordTypeId();
            accountWithoutPerson1.INT_PersonIdent__c = '01234567891';
            Account accountWithoutPerson2 = new Account();
            accountWithoutPerson2.FirstName = 'Missing';
            accountWithoutPerson2.LastName = 'Person';
            accountWithoutPerson2.RecordTypeId = Account.getSObjectType()
                .getDescribe()
                .recordtypeinfosbydevelopername.get('PersonAccount')
                .getRecordTypeId();
            accountWithoutPerson2.INT_PersonIdent__c = '01234567891';
            insert new List<Account>{ accountWithoutPerson1, accountWithoutPerson2 };

            List<User> users = new List<User>();
            Id communityProfileId = [
                SELECT Id
                FROM Profile
                WHERE Name IN ('Trial Customer Portal User', 'NAV Bruker')
                LIMIT 1
            ]
            .Id;
            for (Account acc : [
                SELECT Id, PersonContactId, firstName, lastName
                FROM Account
                WHERE CRM_Person__c IN :new List<Id>{ p1.Id, p2.Id } OR Id = :accountWithoutPerson1.Id
            ]) {
                String random = DateTime.now().getTime().intValue() + '_' + acc.Id;
                User u = new User(
                    FirstName = acc.firstName,
                    LastName = acc.lastName,
                    Email = 'sfTestMergePerson@nav.no',
                    Username = 'sfTestMerge' + random + '@nav.no',
                    Alias = acc.lastName,
                    LanguageLocaleKey = 'no',
                    LocaleSidKey = 'no_NO',
                    TimeZoneSidKey = 'Europe/Paris',
                    EmailEncodingKey = 'UTF-8',
                    ProfileId = communityProfileId,
                    ContactId = acc.PersonContactId
                );
                if (acc.Id == p2.Id) {
                    u.IsActive = false;
                }
                users.add(u);
            }

            insert users;
        }
    }

    static void activateIdentMock() {
        String mockData =
            '{"data":{"hentIdenter":{"identer":[' +
            '{ "ident": "109876543210", "historisk": true, "gruppe": "AKTORID" },' +
            '{ "ident": "109876543211", "historisk": false, "gruppe": "AKTORID" },' +
            '{ "ident": "109876543212", "historisk": true, "gruppe": "AKTORID" }' +
            ']}}}';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', mockData, new Map<String, String>()));
    }

    @IsTest
    static void testMergeWithAura() {
        CRM_PersonMergeTest.activateIdentMock();
        Test.startTest();
        System.assertEquals(true, CRM_PersonMerge.mergeIdentAura('01234567891'), 'Expected the merge to go OK');
        Test.stopTest();

        List<Account> accounts = [
            SELECT Id, Name, PersonContactId, CRM_Person__c, CRM_Person__r.INT_ActorId__c
            FROM Account
        ];
        List<Person__c> persons = [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c];
        List<User> users = [
            SELECT Id, AccountId, ContactId, IsActive, Name
            FROM User
            WHERE Email = 'sfTestMergePerson@nav.no' AND IsActive = TRUE
        ];

        system.assertEquals(1, accounts.size(), 'Accounts: ' + accounts.toString());
        system.assertEquals(1, persons.size(), 'Persons: ' + persons.toString());
        system.assertEquals(1, users.size(), 'Users: ' + users.toString());

        system.assertEquals('109876543211', persons[0].INT_ActorId__c, 'Wrong person left!');
        system.assertEquals(persons[0].Id, accounts[0].CRM_Person__c, 'Wrong account left!');

        system.assertEquals(users[0].AccountId, accounts[0].Id, 'Mapped to wrong account');
        system.assertEquals(users[0].ContactId, accounts[0].PersonContactId, 'Mapped to wrong account');

        System.assertEquals('Firstname Middlename Lastname', accounts[0].Name, 'Account is not updated!');
        System.assertEquals('Firstname Lastname', users[0].Name, 'User is not updated!');
    }

    @IsTest
    static void testMergeWithApi() {
        CRM_PersonMerge result;
        CRM_PersonMergeTest.activateIdentMock();
        Test.startTest();
        result = new CRM_PersonMerge()
            .addPersonIdentToMerge('01234567891')
            .getIdentsFromPDL('109876543210')
            .startMerge();
        Test.stopTest();

        List<Account> accounts = [
            SELECT Id, Name, PersonContactId, CRM_Person__c, CRM_Person__r.INT_ActorId__c
            FROM Account
        ];
        List<Person__c> persons = [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c];
        List<User> users = [
            SELECT Id, AccountId, ContactId, IsActive, Name
            FROM User
            WHERE Email = 'sfTestMergePerson@nav.no' AND IsActive = TRUE
        ];
        system.assertEquals(true, result.isMergeSuccess(), 'Got these errors: ' + result.getMergeErrors().toString());

        system.assertEquals(1, accounts.size(), 'Accounts: ' + accounts.toString());
        system.assertEquals(1, persons.size(), 'Persons: ' + persons.toString());
        system.assertEquals(1, users.size(), 'Users: ' + users.toString());

        system.assertEquals('109876543211', persons[0].INT_ActorId__c, 'Wrong person left!');
        system.assertEquals(persons[0].Id, accounts[0].CRM_Person__c, 'Wrong account left!');

        system.assertEquals(users[0].AccountId, accounts[0].Id, 'Mapped to wrong account');
        system.assertEquals(users[0].ContactId, accounts[0].PersonContactId, 'Mapped to wrong account');

        System.assertEquals('Firstname Middlename Lastname', accounts[0].Name, 'Account is not updated!');
        System.assertEquals('Firstname Lastname', users[0].Name, 'User is not updated!');
    }

    @IsTest
    static void testMergeWithoutApi() {
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, CRM_Person__c, CRM_Person__r.INT_ActorId__c FROM Account]) {
            accountMap.put(
                acc.CRM_Person__r.INT_ActorId__c,
                new Account(Id = acc.Id, CRM_Person__c = acc.CRM_Person__c)
            );
        }

        CRM_PersonMerge result;
        CRM_PersonMergeTest.activateIdentMock();
        Test.startTest();
        result = new CRM_PersonMerge()
            .setMasterAccount(accountMap.get('109876543211').Id)
            .addAccountToMerge(accountMap.get('109876543210').Id)
            .addPersonIdentToMerge('01234567891')
            .startMerge();
        Test.stopTest();

        List<Account> accounts = [
            SELECT Id, Name, PersonContactId, CRM_Person__c, CRM_Person__r.INT_ActorId__c
            FROM Account
        ];
        List<Person__c> persons = [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c];
        List<User> users = [
            SELECT Id, Name, AccountId, ContactId, IsActive
            FROM User
            WHERE Email = 'sfTestMergePerson@nav.no' AND IsActive = TRUE
        ];
        system.assertEquals(true, result.isMergeSuccess(), 'Got these errors: ' + result.getMergeErrors().toString());

        system.assertEquals(1, accounts.size(), 'Accounts: ' + accounts.toString());
        system.assertEquals(1, persons.size(), 'Persons: ' + persons.toString());
        system.assertEquals(1, users.size(), 'Users: ' + users.toString());

        system.assertEquals('109876543211', persons[0].INT_ActorId__c, 'Wrong person left!');
        system.assertEquals(persons[0].Id, accounts[0].CRM_Person__c, 'Wrong account left!');
        system.assertEquals(accounts[0].Id, persons[0].CRM_Account__c, 'Wrong mapping!');

        system.assertEquals(users[0].AccountId, accounts[0].Id, 'Mapped to wrong account');
        system.assertEquals(users[0].ContactId, accounts[0].PersonContactId, 'Mapped to wrong account');

        System.assertEquals('Firstname Middlename Lastname', accounts[0].Name, 'Account is not updated!');
        System.assertEquals('Firstname Lastname', users[0].Name, 'User is not updated!');
    }

    @isTest
    static void testErrors() {
        CRM_PersonMerge result;
        CRM_PersonMergeTest.activateIdentMock();
        Database.SaveResult sr = Database.insert(new Account(), false);
        Test.startTest();
        result = new CRM_PersonMerge().addPersonIdentToMerge('01234567891').getIdentsFromPDL('109876543210');
        result.handleDatabaseErrors(sr.getErrors());
        result.startMerge();
        Test.stopTest();

        List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c];

        List<Account> accounts = [SELECT Id, PersonContactId, CRM_Person__c, CRM_Person__r.INT_ActorId__c FROM Account];
        List<Person__c> persons = [SELECT Id, CRM_Account__c, INT_ActorId__c FROM Person__c];
        List<User> users = [
            SELECT Id, AccountId, ContactId, IsActive
            FROM User
            WHERE Email = 'sfTestMergePerson@nav.no' AND IsActive = TRUE
        ];

        System.assertEquals(false, result.isMergeSuccess(), 'Expected that we had errors');
        System.assertEquals(1, logs.size(), 'Expected one log entry');

        system.assertEquals(4, accounts.size(), 'Accounts: ' + accounts.toString());
        system.assertEquals(2, persons.size(), 'Persons: ' + persons.toString());
        system.assertEquals(3, users.size(), 'Users: ' + users.toString());
    }
}
