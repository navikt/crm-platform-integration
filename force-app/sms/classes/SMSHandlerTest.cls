@isTest
private class SMSHandlerTest {
    @testSetup
    static void setup() {
    }

    @isTest
    static void testCheckAddedQueueableSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        for (Integer i = 0; i < 21; i++) {
            if(math.mod(i, 2) == 0) {
                smsList.add(new SMS__c(Message__c = 'Tekstmelding fra Olga', Type__c = 'Incoming SMS', Status__c = 'Received', Recipient__c = '+4741716090'));
            } else {
                smsList.add(new SMS__c(Message__c = 'Test', Status__c = 'Pending', Recipient__c = '00000000'));
            }
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
