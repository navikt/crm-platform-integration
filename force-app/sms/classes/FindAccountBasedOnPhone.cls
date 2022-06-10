public inherited sharing class FindAccountBasedOnPhone {
    public static Map<String, Person__c> findPersonAccount(List<String> phoneList) {
        for (String phoneNum : phoneList) {
            phoneNum = '%' + phoneNum;
        }
        Map<String, Person__c> personByPhoneNumber = new Map<String, Person__c>();
        for (Person__c person : [SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c FROM Person__c WHERE INT_KrrMobilePhone__c LIKE :phoneList]) {
            personByPhoneNumber.put(person.INT_KrrMobilePhone__c, person);
        }
        return personByPhoneNumber;
    }
}
