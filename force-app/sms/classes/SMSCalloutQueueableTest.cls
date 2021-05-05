@isTest
private class SMSCalloutQueueableTest{

    @isTest
    static void test1() {
        
		Map<String,String> messages = new Map<String,String>();
        messages.put('00000000', 'Test');
        SMSCalloutQueueable instance = new SMSCalloutQueueable(messages);
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