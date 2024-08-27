public inherited sharing class FindAccountBasedOnPhone {
    public static Map<String, Person__c> findPersonAccount(List<String> phoneList) {
        for (Integer i = 0; i < phoneList.size(); i++) {
        	phoneList[i] = '%' + phoneList[i];
    	}
        Map<String, Person__c> personByPhoneNumber = new Map<String, Person__c>();
        for (Person__c person : [SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c FROM Person__c WHERE INT_KrrMobilePhone__c LIKE :phoneList]) {
            personByPhoneNumber.put(person.INT_KrrMobilePhone__c, person);
        }
        return personByPhoneNumber;
    }
    public static Person__c findPersonAccount(String phoneNum) {
        String phoneNumWithWildcard = '%' + phoneNum;
        Person__c person = [SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c 
                                   FROM Person__c 
                                   WHERE INT_KrrMobilePhone__c LIKE :phoneNumWithWildcard LIMIT 1];
        
        return person;
    }
    
}
