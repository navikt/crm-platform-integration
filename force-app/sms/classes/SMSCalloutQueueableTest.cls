@isTest
private class SMSCalloutQueueableTest {

    @isTest
    static void test1() {
        List<SMS__c> smsList = new List<SMS__c>{ new SMS__c(Message__c = 'Test', Recipient__c = '0') };
        SMSCalloutQueueable instance = new SMSCalloutQueueable(smsList);

        Test.startTest();
        System.enqueueJob(instance);
        Test.stopTest();

        System.assertEquals(1, getQueueableApexJobCount());
    }

    private static Integer getQueueableApexJobCount() { 
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND Status = 'Completed' AND ApexClass.Name = 'SMSCalloutQueueable'
        ];
    }
}
