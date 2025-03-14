/**
 * Transforms each meaning in a batch to a common code, then upserts the
 * batch
 */
public class KodeverkBatchable implements Database.Batchable<Common_Code__c> {

    private List<Common_Code__c> codes;

    /**
     * boilerplate
     */
    public KodeverkBatchable(List<Common_Code__c> codes) {
        this.codes = codes;
    }

    /**
     * boilerplate
     */
    public Iterable<Common_Code__c> start(Database.BatchableContext context) {
        return this.codes;
    }

    private Integer countFailures(Database.UpsertResult[] urs) {
        Integer sum = 0;
        for (Integer i = 0; i < urs.size(); i++) {
            if (!urs[i].isSuccess()) {
                sum++;
            }
        }
        return sum;
    }

    private Integer getFirstError(Database.UpsertResult[] urs) {
        for (Integer i = 0; i < urs.size(); i++) {
            if (!urs[i].isSuccess()) {
                return i;
            }
        }
        throw new IllegalArgumentException('Attempted to get an error from a successful upsert result.');
    }

    private String errorMessages(Database.Error[] errors) {
        String[] messages = new List<String>();
        for (Integer i = 0; i < errors.size(); i++) {
            messages.add(errors[i].getMessage());
        }
        return String.join(messages, ', ');
    }

    /**
     * upserts the records. allows partial upsert and gives a brief error
     * message if one or more fail.
     */
    public void execute(Database.BatchableContext context, List<Common_Code__c> codes) {
        Database.UpsertResult[] urs = Database.upsert(
            codes,
            Common_Code__c.Fields.Id,
            false
        );
        Integer failures = countFailures(urs);
        if (failures > 0) {
            Integer firstError = getFirstError(urs);
            new LoggerUtility('Kodeverk').errorAndPublish(
                String.format(
                    'Failure to upsert {0} out of {1} records. The first offender had code set {2}, code {3}, name {4}, and failed with the following errors: {5}',
                    new Object[] {
                        failures,
                        urs.size(),
                        codes[firstError].CRM_Code_Set__c,
                        codes[firstError].CRM_Code__c,
                        codes[firstError].Name,
                        errorMessages(urs[firstError].getErrors())
                    }
                )
            );
        }
    }

    /**
     * boilerplate
     */
    public void finish(Database.BatchableContext context) {
    }
}
