public with sharing class MonitorFssIntegration_Schedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        getUnitFromNorg2();
    }

    @Future(callout=true)
    public static void getUnitFromNorg2() {
        runNorg2UnitCheck('NORG2_UNIT_API', 'GET_UNIT_CONTACT_INFORMATION');
    }

    /**
     * Executes the configured monitor request and logs its response status.
     * Test visibility allows using the dependency's packaged API fixtures without changing production configuration.
     * @param apiConfigName API base configuration metadata developer name
     * @param serviceName API service configuration metadata developer name
     * @since 2026-10-26
     */
    @TestVisible
    private static void runNorg2UnitCheck(String apiConfigName, String serviceName) {
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(apiConfigName, serviceName, new Map<String, String>{ 'enhetsnummer' => '0104' });
        apiCtrl.setSystemContext();
        apiCtrl.addServiceAuthHeader('gcpsaasproxy');
        apiCtrl.doCallout();

        String bodyString = apiCtrl.getResponse().getBody();
        if (String.isNotBlank(bodyString)) {
            bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        }

        if (apiCtrl.getResponse().getStatusCode() == 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.info('Integrasjon ok', null);
            logger.publishSynch();
        } else {
            //something went wrong. Log error
            LoggerUtility logger = new LoggerUtility();
            logger.error('Integrasjon feilet', null);
            logger.publishSynch();
        }
    }
}
