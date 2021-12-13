public with sharing class CRM_PerformSyncInterfaceTestClass implements CRM_SyncInterface {
    public static void doSync() {
        insert new Account(Name = 'TestAccount4');
    }
}
