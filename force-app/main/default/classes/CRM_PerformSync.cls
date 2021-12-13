global with sharing class CRM_PerformSync implements Schedulable {
    global void execute(SchedulableContext sc) {
        for (Sync_Class_Binding__mdt binding : getHandlers()) {
            ((CRM_SyncInterface) Type.forName(binding.ApexClass__c).newInstance()).doSync();
        }
    }

    global List<Sync_Class_Binding__mdt> getHandlers() {
        return !Test.isRunningTest()
            ? [SELECT Id, ApexClass__c FROM Sync_Class_Binding__mdt]
            : new List<Sync_Class_Binding__mdt>{
                  new Sync_Class_Binding__mdt(ApexClass__c = 'CRM_PerformSyncInterfaceTestClass')
              };
    }
}
