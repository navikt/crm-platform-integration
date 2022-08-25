@IsTest
private with sharing class CRM_PersonMergeBatchTest {
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
            insert new List<Account>{ accountWithoutPerson1 };

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

    @IsTest
    static void testMerge() {
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Account WHERE INT_PersonIdent__c = '01234567891'],
            'Expected to find the test accounts'
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            CRM_PersonMergeBatch testBatch = new CRM_PersonMergeBatch();
            testBatch.setBatchSize(1).setQuery(testBatch.query).startBatch();
            Test.stopTest();
        }
        List<Application_Log__c> errors = new List<Application_Log__c>(
            [SELECT Id, Log_Message__c FROM Application_Log__c]
        );
        System.assertEquals(0, errors.size(), errors);

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Account WHERE INT_PersonIdent__c = '01234567891'],
            'Expected to have merged the accounts'
        );
    }
}
