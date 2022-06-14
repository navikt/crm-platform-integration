public with sharing class Unit4CalloutService extends CRM_ApplicationDomain{
    public static HttpResponse postToUnit4(List<SObject> records) {

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest('Unit4_API', 'POST_Unit4');
        apiCtrl.setBody(formatJSONBody(record));
        apiCtrl.addHeader('Content-Type', 'application/json');


        try {
            apiCtrl.doCallout();
        } catch (Exception e) {
            LoggerUtility logger = new LoggerUtility();
            logger.exception(e, sms, domain);
            logger.publish();
        }

        if (apiCtrl.getResponse()?.getStatusCode() != 200) {
            LoggerUtility logger = new LoggerUtility();
            logger.error(
                apiCtrl.getResponse()?.getStatusCode() +
                ': ' +
                apiCtrl.getResponse()?.getStatus(),
                sms,
                domain
            );
            logger.publish();
        }

        return apiCtrl.getResponse();
    }

    private static String formatJSONBody(String RCV, String TXT, SMS_Config__mdt smsConfig) {
        Map<String, String> mappy = new Map<String, String>();
        mappy.put('source', smsConfig.Source__c); //20216
        mappy.put('destination', RCV);
        mappy.put('userData', TXT);
        mappy.put('platformId', smsConfig.PlatformId__c);
        mappy.put('platformPartnerId', smsConfig.PlatformPartnerId__c);

        return JSON.serialize(mappy);
    }

    public class Unit4CalloutServiceException extends Exception {
    }
}
