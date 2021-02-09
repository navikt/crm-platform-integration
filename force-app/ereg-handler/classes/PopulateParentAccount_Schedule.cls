public without sharing class PopulateParentAccount_Schedule implements Schedulable, Database.Batchable<SObject> {
    private final String ACCOUNT_HISTORY_QUERY = 'SELECT AccountId FROM AccountHistory WHERE CreatedDate = TODAY AND Field IN (\'INT_ParentOrganizationNumber__c\', \'created\')';

    public void execute(SchedulableContext sc) {
        PopulateParentAccount_Schedule btch = new PopulateParentAccount_Schedule();
        Database.executeBatch(btch, 2000);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.ACCOUNT_HISTORY_QUERY);
    }

    public void execute(
        Database.BatchableContext BC,
        List<AccountHistory> scope
    ) {
        Set<Id> accountIds = new Set<Id>();
        for (AccountHistory accountHistory : scope) {
            accountIds.add(accountHistory.AccountId);
        }

        List<Account> accounts = [
            SELECT Id, INT_ParentOrganizationNumber__c, ParentId
            FROM Account
            WHERE Id IN :accountIds
        ];
        Set<String> parentOrgNumbers = new Set<String>();
        for (Account acc : accounts) {
            parentOrgNumbers.add(acc.INT_ParentOrganizationNumber__c);
        }

        Map<String, Id> parentAccountIdsByOrganizationNumber = new Map<String, Id>();
        for (Account acc : [
            SELECT Id, INT_OrganizationNumber__c
            FROM Account
            WHERE INT_OrganizationNumber__c IN :parentOrgNumbers
        ]) {
            parentAccountIdsByOrganizationNumber.put(
                acc.INT_OrganizationNumber__c,
                acc.Id
            );
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : accounts) {
            if (
                parentAccountIdsByOrganizationNumber.containsKey(
                    acc.INT_ParentOrganizationNumber__c
                )
            ) {
                if (
                    acc.ParentId !=
                    parentAccountIdsByOrganizationNumber.get(
                        acc.INT_ParentOrganizationNumber__c
                    )
                ) {
                    acc.ParentId = parentAccountIdsByOrganizationNumber.get(
                        acc.INT_ParentOrganizationNumber__c
                    );
                    accountsToUpdate.add(acc);
                }
            } else if (acc.ParentId != null) {
                acc.ParentId = null;
                accountsToUpdate.add(acc);
            }
        }
        update accountsToUpdate;
    }
    public void finish(Database.BatchableContext BC) {
    }
}
