@IsTest
public with sharing class CRM_PerformSyncTest {
    @isTest
    static void test() {
        Test.startTest();

        Datetime executeTime = System.now().addYears(1);
        String cronEXP = executetime.format('s m h d M ? yyyy');

        // Schedule the test job
        String jobId = System.schedule('CRM_PerformSync',
        cronEXP, 
            new CRM_PerformSync());
    
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
            NextFireTime
            FROM CronTrigger WHERE id = :jobId];
    
        // Verify the expressions are the same
        System.assertEquals(cronEXP, 
            ct.CronExpression);
    
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
    
        // Verify the next time the job will run
        System.assertEquals(executeTime.format('YYYY-MM-dd hh:mm:ss'), 
            String.valueOf(ct.NextFireTime));
    
        Test.stopTest();
     
        }
}
