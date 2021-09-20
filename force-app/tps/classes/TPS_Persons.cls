public inherited sharing class TPS_Persons {
    public static TPS_Bankkonto getBankkonto(String actorId) {
        TPS_Bankkonto bankonto;

        try {
            HttpResponse resp = TPS_CalloutService.getBankAccount(actorId);

            if (resp.getStatusCode() == 200) {
                bankonto = (TPS_Bankkonto) JSON.deserialize(resp.getBody(), TPS_Bankkonto.class);
            } else {
                handleError('Kunne ikke hente bankkontonummer', resp);
            }
        } catch (TPS_PersonsException e) {
            throw e;
        } catch (Exception e) {
            String uuid;
            LoggerUtility logger = new LoggerUtility('TPS');
            logger.exception(e);
            uuid = logger.peek().UUID__c;
            logger.publish();
            throw new TPS_PersonsException(e.getMessage() + ' LoggId: ' + uuid);
        }

        return bankonto;
    }

    private static void handleError(String message, HttpResponse resp) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('TPS');
        logger.httpError(message, resp, null, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new TPS_PersonsException(message + ' LoggId: ' + uuid);
    }

    public class TPS_PersonsException extends Exception {
    }
}
