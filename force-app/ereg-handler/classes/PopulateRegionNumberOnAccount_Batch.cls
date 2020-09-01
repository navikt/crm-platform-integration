global without sharing class PopulateRegionNumberOnAccount_Batch implements Database.Batchable<sObject> {
    
    // To run: 
    // PopulateRegionNumberOnAccount_Batch batchObject = new PopulateRegionNumberOnAccount_Batch(); 
    // Database.executeBatch(batchObject, 2000);

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, INT_MunicipalityNumber__c, INT_RegionNumber__c FROM Account WHERE INT_MunicipalityNumber__c != null');
    }

    global void execute(Database.BatchableContext bc, List<Account> scope){
        List<Account> accounts = new List<Account>();
        for (Account account : scope) {
            if(account.INT_MunicipalityNumber__c.length() == 4) {
                account.INT_RegionNumber__c = account.INT_MunicipalityNumber__c.left(2);
                accounts.add(account);
            }
        }
        update accounts;
    }

    global void finish(Database.BatchableContext bc){}
}
