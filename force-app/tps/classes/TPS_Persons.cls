public inherited sharing class TPS_Persons {
    public static TPS_Bankkonto getBankkonto(String actorId) {
        return getBankkonto(actorId, false);
    }

    public static TPS_Bankkonto getBankkonto(String actorId, Boolean updatePerson) {
        TPS_Bankkonto bankkonto;

        try {
            HttpResponse resp = TPS_CalloutService.getBankAccount(actorId);

            if (resp.getStatusCode() == 200) {
                bankkonto = (TPS_Bankkonto) JSON.deserialize(resp.getBody(), TPS_Bankkonto.class);

                if (true == updatePerson) {
                    Person__c person = getPerson(
                        actorId,
                        new List<String>{ 'Id', 'INT_BankAccountNumber__c', 'INT_BankAccountNumberLastModified__c' }
                    );
                    addBankAccountNumberToPerson(person, bankkonto);
                    update person;
                }
            } else {
                handleError('Kunne ikke hente bankkontonummer', resp);
            }
        } catch (TPS_PersonsException e) {
            throw e;
        } catch (Exception e) {
            String uuid = logException(e);
            throw new TPS_PersonsException(e.getMessage() + ' LoggId: ' + uuid);
        }

        return bankkonto;
    }

    private static Person__c getPerson(String actorId, List<String> queryfields) {
        String q = new fflib_QueryFactory(Person__c.SObjectType)
            .selectFields(queryfields)
            .setCondition('INT_ActorId__c' + '= :actorId')
            .toSOQL();
        Person__c person = Database.query(q);

        return person;
    }

    @TestVisible
    private static void addBankAccountNumberToPerson(Person__c person, TPS_Bankkonto bankkonto) {
        person.INT_BankAccountNumberLastModified__c = null;
        person.INT_BankAccountNumber__c = null;

        if (bankkonto != null) {
            person.INT_BankAccountNumberLastModified__c = bankkonto.endretTidspunkt;

            if (bankkonto.bankkontoNorge != null && String.isNotBlank(bankkonto.bankkontoNorge.bankkontoummer)) {
                person.INT_BankAccountNumber__c = bankkonto.bankkontoNorge.bankkontoummer;
            } else if (
                bankkonto.bankkontoUtland != null && String.isNotBlank(bankkonto.bankkontoUtland.bankkontoummer)
            ) {
                person.INT_BankAccountNumber__c = bankkonto.bankkontoUtland.bankkontoummer;
            }
        }
    }

    private static void handleError(String message, HttpResponse resp) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('TPS');
        logger.httpError(message, resp, null, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new TPS_PersonsException(message + ' LoggId: ' + uuid);
    }

    private static String logException(Exception e) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('TPS');
        logger.exception(e);
        uuid = logger.peek().UUID__c;
        logger.publish();

        return uuid;
    }

    public class TPS_PersonsException extends Exception {
    }
}
