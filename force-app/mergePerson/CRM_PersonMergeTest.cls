@IsTest
private with sharing class CRM_PersonMergeTest {
    @TestSetup
    static void makeData() {
        Person__c p1 = new Person__c();
        p1.Name = '01234567890';
        p1.INT_fnr__c = p1.Name;
        p1.INT_ActorId__c = '109876543210';
        p1.INT_FirstName__c = 'Firstname';
        p1.INT_MiddleName__c = 'Middlename';
        p1.INT_LastName__c = 'Lastname';
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

        String mockData =
            '{"data":{"hentIdenter":{"identer":[' +
            '{ "ident": "109876543210", "historisk": true, "gruppe": "AKTORID" },' +
            '{ "ident": "109876543211", "historisk": false, "gruppe": "AKTORID" },' +
            '{ "ident": "109876543212", "historisk": true, "gruppe": "AKTORID" }' +
            ']}}}';

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', mockData, new Map<String, String>()));
    }

    @IsTest
    static void testMerge() {
        Map<String, Account> accountMap = new Map<String, Account>();
        for (Account acc : [SELECT Id, CRM_Person__c, CRM_Person__r.INT_ActorId__c FROM Account]) {
            accountMap.put(
                acc.CRM_Person__r.INT_ActorId__c,
                new Account(Id = acc.Id, CRM_Person__c = acc.CRM_Person__c)
            );
        }

        CRM_PersonMerge result;
        Test.startTest();
        result = new CRM_PersonMerge().getIdentsFromPDL('109876543210').startMerge();
        Test.stopTest();

        List<Account> accounts = [SELECT Id, CRM_Person__r.INT_ActorId__c FROM Account];
        List<Person__c> persons = [SELECT Id, CRM_Account__c FROM Person__c];
        system.assertEquals(true, result.isMergeSuccess(), 'Got these errors: ' + result.getMergeErrors().toString());
        system.assertEquals(1, accounts.size(), 'Accounts: ' + accounts.toString());
        system.assertEquals(1, persons.size(), 'Persons: ' + persons.toString());
    }
}
