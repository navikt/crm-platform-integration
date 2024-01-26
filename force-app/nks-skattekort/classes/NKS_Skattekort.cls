public inherited sharing class NKS_Skattekort {
    public static List<NKS_SkattekortWrapper> getSkattekort(String fnr, String inntektsaar) {
        List<NKS_SkattekortWrapper> skattekort;

        try {
            HttpResponse resp = NKS_SkattekortCalloutService.getSkattekort(fnr, inntektsaar);
            if (resp.getStatusCode() == 200) {
                skattekort = String.isNotBlank(resp.getBody())
                    ? (List<NKS_SkattekortWrapper>) JSON.deserialize(resp.getBody(), List<NKS_SkattekortWrapper>.class)
                    : null;
            } else {
                handleError('Kunne ikke hente skattekort', resp);
            }
        } catch (SkattekortException e) {
            throw e;
        } catch (Exception e) {
            String uuid = logException(e);
            throw new SkattekortException(e.getMessage() + ' LoggId: ' + uuid);
        }
        return skattekort;
    }

    private static void handleError(String message, HttpResponse resp) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('NKS');
        logger.httpError(message, resp, null, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new SkattekortException(message + ' LoggId: ' + uuid);
    }

    private static String logException(Exception e) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('NKS');
        logger.exception(e);
        uuid = logger.peek().UUID__c;
        logger.publish();
        return uuid;
    }

    public class SkattekortException extends Exception {
    }
}
