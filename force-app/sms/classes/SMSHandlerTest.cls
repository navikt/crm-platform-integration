@isTest
private class SMSHandlerTest {
    @testSetup
    static void setup() {
    }

    @isTest
    static void testMethod1() {
        List<SMS__c> smsList = new List<SMS__c>();
        for (Integer i = 0; i < 21; i++) {
            smsList.add(new SMS__c(Message__c = 'Test', Recipient__c = '00000000'));
        }
        Test.startTest();
        insert smsList;
        Test.stopTest();

        System.assertEquals(3, getQueueableApexJobCount());
    }

    private static Integer getQueueableApexJobCount() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND Status = 'Completed' AND ApexClass.Name = 'SMSCalloutQueueable'
        ];
    }
}
