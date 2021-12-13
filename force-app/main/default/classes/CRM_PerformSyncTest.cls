@IsTest
public with sharing class CRM_PerformSyncTest {
    @isTest
    static void performSyncTest() {
        Test.startTest();
        new CRM_PerformSync().execute(null);
        Test.stopTest();

        System.assert([SELECT COUNT() FROM Account WHERE Name = 'TestAccount4'] == 1);
    }
}
