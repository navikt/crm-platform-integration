public with sharing class MonitorFssIntegration_Schedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        getUnitFromNorg2();
    }

    @Future(callout=true)
    public static void getUnitFromNorg2() {
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(
            'NORG2_UNIT_API',
            'GET_UNIT_CONTACT_INFORMATION',
            new Map<String, String>{ 'enhetsnummer' => '0104' }
        );
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
