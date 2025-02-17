public class KodeverkBatchable implements Database.Batchable<Common_Code__c> {

    private List<Common_Code__c> codesToUpsert;

    public KodeverkBatchable(List<Common_Code__c> codes) {
        this.codesToUpsert = codes;
    }

    public Iterable<Common_Code__c> start(Database.BatchableContext context) {
        return this.codesToUpsert;
    }

    public void execute(Database.BatchableContext context, List<Common_Code__c> codes) {
        upsert codes;
        //try {
        //    insert accountsToInsert;
        //} catch(Exception e) {
        //    // Handle failure
        //}
    }

    public void finish(Database.BatchableContext context) {
        System.debug('W00t!');
    }
}
