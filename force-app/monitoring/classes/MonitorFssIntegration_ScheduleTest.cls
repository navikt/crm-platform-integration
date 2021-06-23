@IsTest
private class MonitorFssIntegration_ScheduleTest {
   
    @IsTest
    static void testSchedule(){
        SingleRequestMock httpMock = new SingleRequestMock(
            200,
            'Success',
            JSON.serialize(new List<String>()),
            null
        );

        Test.setMock(HttpCalloutMock.class, httpMock);

        Test.startTest();
        MonitorFssIntegration scheduleClass=new MonitorFssIntegration();
        String chron = '0 0 23 * * ?';
        System.schedule('Check FSS integration', chron, scheduleClass);
        Test.stopTest();
        
        System.assert([SELECT COUNT() FROM CronTrigger]>0, 'A job should be scheduled');
    }

    @IsTest
    static void testGetUnitFromNorg2_whenOk(){
       
        SingleRequestMock httpMock = new SingleRequestMock(
            200,
            'Success',
            JSON.serialize(new List<String>()),
            null
        );

        Test.setMock(HttpCalloutMock.class, httpMock);

        Test.startTest();
        MonitorFssIntegration_Schedule fssIntegration=new MonitorFssIntegration_Schedule();
        System.enqueueJob(fssIntegration);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c WHERE Source_Class__c='MonitorFssIntegration_Schedule' AND Log_Level__c='Info'], 'Expect info log to be created');
}

@IsTest
    static void testGetUnitFromNorg2_whenError(){
       
        SingleRequestMock httpMock = new SingleRequestMock(
            401,
            'Error',
            JSON.serialize(new List<String>()),
            null
        );

        Test.setMock(HttpCalloutMock.class, httpMock);

        Test.startTest();
        MonitorFssIntegration_Schedule fssIntegration=new MonitorFssIntegration_Schedule();
        System.enqueueJob(fssIntegration);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Application_Log__c WHERE Source_Class__c='MonitorFssIntegration_Schedule' AND Log_Level__c='Error'], 'Expect error log to be created');
}
}