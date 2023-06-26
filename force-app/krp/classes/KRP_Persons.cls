/**
 * This class provides a single method which returns a bank account.
 */
public inherited sharing class KRP_Persons {

    private static KRP_CalloutService service = new KRP_CalloutService();

    public static KRP_Konto getBankkonto(String ident) {
        // TPS would take an "update" argument for this method.
        // This is now handled by nksDataSyncher .
        KRP_Konto bankkonto;
        try {
            HttpResponse resp = service.getBankAccount(ident);
            if (resp.getStatusCode() == 200) {
                bankkonto = String.isNotBlank(resp.getBody())
                    ? (KRP_Konto) JSON.deserialize(resp.getBody(), KRP_Konto.class)
                    : null;
            } else if(resp.getStatusCode() == 204){
                handleNoBankAccount('Kontohaveren har ingen aktiv konto', resp);
            } else {
                handleError('Kunne ikke hente bankkontonummer', resp);
            }
        } catch (KRP_PersonsException e) {
            throw e;
        } catch (Exception e) {
            String uuid = logException(e);
            throw new KRP_PersonsException(e.getMessage() + ' LoggId: ' + uuid);
        }
        return bankkonto;
    }

    private static void handleNoBankAccount(String message, HttpResponse resp){
        String uuid;
        LoggerUtility logger = new LoggerUtility('KRP');
        String payload =
            'HTTP Status: ' +
            String.valueOf(resp.getStatusCode()) +
            ' - ' +
            response.getStatus() +
            '\n';
        payload += 'Body: \n' + resp.getBody();
        logger.logMessage(LoggerUtility.LogLevel.Info, null, null, message, payload, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new KRP_PersonsException(message + ' LoggId: ' + uuid);
    }
    private static void handleError(String message, HttpResponse resp) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('KRP');
        logger.httpError(message, resp, null, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new KRP_PersonsException(message + ' LoggId: ' + uuid);
    }

    private static String logException(Exception e) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('KRP');
        logger.exception(e);
        uuid = logger.peek().UUID__c;
        logger.publish();
        return uuid;
    }

    public class KRP_PersonsException extends Exception {
    }
}
