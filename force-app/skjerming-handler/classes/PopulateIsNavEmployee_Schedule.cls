public with sharing class PopulateIsNavEmployee_Schedule implements Schedulable, Database.Batchable<SObject> {
    private final String PERSON_NAV_EMPLOYEE_QUERY = 'SELECT INT_IsNavEmployee__c, INT_NavEmployeeFromDatetime__c, INT_NavEmployeeToDatetime__c FROM Person__c WHERE INT_NavEmployeeFromDatetime__c!=null';
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
            if (person.INT_NavEmployeeFromDatetime__c <= Datetime.now() && !person.INT_IsNavEmployee__c &&(person.INT_NavEmployeeToDatetime__c ==null || person.INT_NavEmployeeToDatetime__c >= Datetime.now())) {
                person.INT_IsNavEmployee__c = true;
                personsToUpdate.add(person);
            } else if (person.INT_NavEmployeeToDatetime__c < Datetime.now() && person.INT_IsNavEmployee__c) {
                //update person where to date is expired  and IsNavEmployee is true
                person.INT_IsNavEmployee__c = false;
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
