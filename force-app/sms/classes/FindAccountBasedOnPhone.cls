public inherited sharing class FindAccountBasedOnPhone {
    public static List<Person__c> findPersonAccount(String phone) {
        phone = '%' + phone;
        List<Person__c> personList = [
            SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c
            FROM Person__c
            WHERE INT_KrrMobilePhone__c LIKE :phone
        ];
        return personList;
    }
}
