public class KodeverkQueueable implements Queueable, Database.AllowsCallouts {

    private final static Integer BATCH_SIZE = 5000;

    private String label;

    public KodeverkQueueable(String label) {
        this.label = label;
    }

    public void execute(QueueableContext context) {
        try {
            Common_Code__c[] codes = KodeverkHelper.getCodesFromMeaningMap(this.label, KodeverkHelper.getMeaningMap(this.label));
            Database.executeBatch(new KodeverkBatchable(codes), BATCH_SIZE);
        } catch (CalloutException ce) {
            new LoggerUtility('Kodeverk').errorAndPublish(ce.getMessage());
        }
    }
}
