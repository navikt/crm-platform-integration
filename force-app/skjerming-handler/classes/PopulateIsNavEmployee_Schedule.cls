public with sharing class PopulateIsNavEmployee_Schedule implements Schedulable, Database.Batchable<SObject> {
    private final String PERSON_NAV_EMPLOYEE_QUERY = 'SELECT INT_IsNavEmployee__c, INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c FROM Person__c WHERE INT_NavEmployeeFromDate__c!=null';
    public void execute(SchedulableContext sc) {
        PopulateIsNavEmployee_Schedule btch = new PopulateIsNavEmployee_Schedule();
        Database.executeBatch(btch, 2000);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(PERSON_NAV_EMPLOYEE_QUERY);
    }

    public void execute(Database.BatchableContext BC, List<Person__c> scope) {
        List<Person__c> personsToUpdate = new List<Person__c>();

        for (Person__c person : scope) {
            //update person where from date is today or before and IsNavEmployee is false
            if (
                person.INT_NavEmployeeFromDate__c <= Date.today() &&
                !person.INT_IsNavEmployee__c
            ) {
                person.INT_IsNavEMployee__c = true;
                personsToUpdate.add(person);
            }

            //update person where to date is expired  and IsNavEmployee is true
            if (
                person.INT_NavEmployeeToDate__c < Date.today() &&
                person.INT_IsNavEmployee__c
            ) {
                person.INT_IsNavEMployee__c = false;
                personsToUpdate.add(person);
            }
        }

        if (personsToUpdate.size() > 0) {
            update personsToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}
