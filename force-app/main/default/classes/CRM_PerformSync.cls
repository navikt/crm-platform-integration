global with sharing class CRM_PerformSync implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext sc) {
        for (Sync_Class_Binding__mdt binding : [
            SELECT Id, ApexClass__c
            FROM Sync_Class_Binding__mdt
        ]) {
            if(Test.isRunningTest()){
                continue;
            }
            ((CRM_SyncInterface) Type.forName(binding.ApexClass__c).newInstance()).doSync();
        }
    }
}
