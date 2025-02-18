public class KodeverkBatchable implements Database.Batchable<KodeverkResponse> {

    private List<KodeverkResponse> codesToHandle;

    public KodeverkBatchable(List<KodeverkResponse> codes) {
        this.codesToHandle = codes;
    }

    public Iterable<KodeverkResponse> start(Database.BatchableContext context) {
        return this.codesToHandle;
    }

    public void execute(Database.BatchableContext context, List<KodeverkResponse> codes) {
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
