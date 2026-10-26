/**
 * Verifies scheduling and response logging for the FSS integration monitor.
 * @author Frode Hoen
 * @since 2021-06-23
 * @group Monitoring
 */
@IsTest
private class MonitorFssIntegration_ScheduleTest {
    /**
     * Verifies that the monitor job is registered without executing its environment-specific callout.
     * @since 2026-10-26
     */
    @IsTest
    static void schedulesMonitorJob() {
        String cronExpression = '0 0 23 * * ?';
        String jobId = System.schedule('Check FSS integration', cronExpression, new MonitorFssIntegration_Schedule());

        CronTrigger scheduledJob = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.Assert.areEqual(cronExpression, scheduledJob.CronExpression, 'Expect the monitor job to be scheduled');
    }

    /**
     * Verifies a successful response is logged using the dependency's API test configuration.
     * @since 2026-10-26
     */
    @IsTest
    static void logsInfoWhenNorgRequestSucceeds() {
        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', '[]', null));

        System.runAs(createMinimumAccessUser()) {
            System.Test.startTest();
            MonitorFssIntegration_Schedule.runNorg2UnitCheck('TEST_CONFIG', 'TEST_SERVICE_CONFIG');
            System.Test.stopTest();
        }

        System.Assert.areEqual(
            1,
            [
                SELECT COUNT()
                FROM Application_Log__c
                WHERE Source_Class__c = 'MonitorFssIntegration_Schedule' AND Log_Level__c = 'Info'
            ],
            'Expect info log to be created'
        );
    }

    /**
     * Verifies an unsuccessful response is logged using the dependency's API test configuration.
     * @since 2026-10-26
     */
    @IsTest
    static void logsErrorWhenNorgRequestFails() {
        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(401, 'Error', '[]', null));

        System.runAs(createMinimumAccessUser()) {
            System.Test.startTest();
            MonitorFssIntegration_Schedule.runNorg2UnitCheck('TEST_CONFIG', 'TEST_SERVICE_CONFIG');
            System.Test.stopTest();
        }

        System.Assert.areEqual(
            1,
            [
                SELECT COUNT()
                FROM Application_Log__c
                WHERE Source_Class__c = 'MonitorFssIntegration_Schedule' AND Log_Level__c = 'Error'
            ],
            'Expect error log to be created'
        );
    }

    /**
     * Creates a user with the minimum Salesforce profile for callout behavior tests.
     * @since 2026-10-26
     * @return User with the Minimum Access - Salesforce profile
     */
    private static User createMinimumAccessUser() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];
        String uniqueSuffix = String.valueOf(DateTime.now().getTime()) + String.valueOf(Crypto.getRandomInteger());
        String username = 'monitor-fss-' + uniqueSuffix + '@example.invalid';

        User minimumAccessUser = new User(
            Alias = 'monfss',
            Email = username,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Monitor FSS Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minimumAccessProfile.Id,
            TimeZoneSidKey = 'Europe/Oslo',
            Username = username
        );
        insert minimumAccessUser;
        return minimumAccessUser;
    }
}
