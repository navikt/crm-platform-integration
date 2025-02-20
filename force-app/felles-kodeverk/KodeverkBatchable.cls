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

    /**
     * the heavy work is done here. transform the responses into records and
     * upserts them.
     */
    public void execute(Database.BatchableContext context, List<Common_Code__c> codes) {
        upsert codes;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('W00t!');
    }
}
