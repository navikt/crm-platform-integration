public with sharing class PersonHandler extends MyTriggers {

    private final Id PERSON_ACCOUNT_RECORD_TYPE_ID = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;


    public override void onAfterInsert() {
        createRelatedAccounts(records);
    }

    public override void onAfterUpdate(Map<Id, SObject> triggerOldMap) {
        updateRelatedAccounts(records, triggerOldMap);
    }


    /**
     * Create a Person Account record associated with each new Person__c record. The Account
     * contains a subset of the personal information stored on the Person record, and is related
     * through Lookup-fields both ways (Account -> Person__c, Person__c -> Account)
     *
     * @param newRecords Newly inserted Person__c records
     */
    private void createRelatedAccounts(List<Person__c> newRecords) {
        List<Account> accountsToInsert = new List<Account>();
        for (Person__c person : newRecords) {
            Account personAccount = new Account();
            mapAccountFieldValues(personAccount, person);
            accountsToInsert.add(personAccount);
        }
        insert accountsToInsert;

        List<Person__c> personsToUpdate = new List<Person__c>();
        for (Account acc : accountsToInsert) {
            personsToUpdate.add(new Person__c(
                    Id = acc.CRM_Person__c,
                    CRM_Account__c = acc.Id
            ));
        }
        update personsToUpdate;

    }

    /**
     * Evaluate whether relevant field changes has been made, and if so update the related
     * Person Account with values from changed Person__c fields
     *
     * @param newRecords Newly updated records
     * @param oldRecordsMap Trigger.oldMap of updated records
     */
    private void updateRelatedAccounts(List<Person__c> newRecords, Map<Id, SObject> oldRecordsMap) {
        List<Person__c> recordsWithRelevantUpdates = evaluateRelevantFieldChangesForAssociatedAccount(newRecords, oldRecordsMap);
        List<Account> accountsToUpdate = new List<Account>();
        for (Person__c person : recordsWithRelevantUpdates) {
            Account personAccount = new Account(Id = person.CRM_Account__c);
            mapAccountFieldValues(personAccount, person);
            accountsToUpdate.add(personAccount);
        }
        update accountsToUpdate;
    }

    /**
     * Evaluate if relevant fields have been changed and filter the list of records accordingly
     *
     * @param newRecords Newly updated records
     * @param oldRecordsMap Trigger.oldMap of updated records
     *
     * @return Records with changes necessitating updating the related Account record
     */
    private List<Person__c> evaluateRelevantFieldChangesForAssociatedAccount(List<Person__c> newRecords, Map<Id, SObject> oldRecordsMap) {
        List<String> fieldNamesToCheck = new String[]{
                'INT_FirstName__c', 'INT_MiddleName__c', 'INT_LastName__c', 'Name', 'INT_Confidential__c'
        };
        List<Person__c> recordsWithRelevantUpdates = new List<Person__c>();
        for (Person__c person : newRecords) {
            if (MyTriggers.hasChangedFields(fieldNamesToCheck, person, oldRecordsMap.get(person.Id))) {
                recordsWithRelevantUpdates.add(person);
            }
        }
        return recordsWithRelevantUpdates;
    }

    /**
     * Transform and map fields from Person__c record to Account record
     *
     * @param account Account record to populate fields on
     * @param person Person__c record to map fields from
     */
    private void mapAccountFieldValues(Account account, Person__c person) {
        account.RecordTypeId = PERSON_ACCOUNT_RECORD_TYPE_ID;
        account.OwnerId = person.OwnerId;
        account.FirstName = person.INT_Confidential__c != 'UGRADERT' ? '' : String.isBlank(person.INT_FirstName__c) ? '' : person.INT_FirstName__c.left(40);
        account.MiddleName = person.INT_Confidential__c != 'UGRADERT' ? '' : String.isBlank(person.INT_MiddleName__c) ? '' : person.INT_MiddleName__c.left(40);
        account.LastName = person.INT_Confidential__c != 'UGRADERT' ? 'IKKE TILGJENGELIG' : String.isBlank(person.INT_LastName__c) ? '' : person.INT_LastName__c.left(80);
        account.INT_PersonIdent__c = person.Name;
        account.CRM_Person__c = person.Id;
    }

}