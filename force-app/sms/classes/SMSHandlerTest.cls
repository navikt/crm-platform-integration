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

    @isTest
    static void test21OutgoingSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        for (Integer i = 0; i < 21; i++) {
            smsList.add(new SMS__c(Message__c = 'Test', Status__c = 'Pending', Recipient__c = '00000000'));
        }
        Test.startTest();
        insert smsList;
        Test.stopTest();

        System.assertEquals(3, getQueueableApexJobCount());
        System.assertEquals(21, getSMSCount());
        System.assertEquals(21, getOutgoingCount());
    }
    @isTest
    static void test21IncommingSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        for (Integer i = 0; i < 21; i++) {
            smsList.add(
                new SMS__c(
                    Message__c = 'Test',
                    Domain__c = 'HOT',
                    Status__c = 'Received',
                    Type__c = 'Incoming SMS',
                    Recipient__c = '+4741716090'
                )
            );
        }
        Test.startTest();
        insert smsList;
        Test.stopTest();

        System.assertEquals(0, getQueueableApexJobCount());
        System.assertEquals(21, getSMSCount());
        System.assertEquals(21, getIncomingCount());
    }
    @isTest
    static void testMixOfSMS() {
        List<SMS__c> smsList = new List<SMS__c>();
        for (Integer i = 0; i < 22; i++) {
            if (math.mod(i, 2) == 0) {
                smsList.add(
                    new SMS__c(
                        Message__c = 'Test',
                        Domain__c = 'HOT',
                        Status__c = 'Received',
                        Type__c = 'Incoming SMS',
                        Recipient__c = '+4741716090'
                    )
                );
            } else {
                smsList.add(new SMS__c(Message__c = 'Test', Status__c = 'Pending', Recipient__c = '00000000'));
            }
        }
        Test.startTest();
        insert smsList;
        Test.stopTest();

        System.assertEquals(2, getQueueableApexJobCount());
        System.assertEquals(22, getSMSCount());
        System.assertEquals(11, getIncomingCount());
        System.assertEquals(11, getOutgoingCount());
    }

    private static Integer getQueueableApexJobCount() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND Status = 'Completed' AND ApexClass.Name = 'SMSCalloutQueueable'
        ];
    }

    private static Integer getSMSCount() {
        return [SELECT COUNT() FROM SMS__c];
    }

    private static Integer getIncomingCount() {
        return [SELECT COUNT() FROM SMS__c WHERE Status__c = 'Received' AND Type__c = 'Incoming SMS'];
    }

    private static Integer getOutgoingCount() {
        return [SELECT COUNT() FROM SMS__c WHERE Type__c != 'Incoming SMS' AND Status__c = 'Could not send'];
    }
}
