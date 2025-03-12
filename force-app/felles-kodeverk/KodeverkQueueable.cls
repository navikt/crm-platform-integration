public class KodeverkQueueable implements Queueable, Database.AllowsCallouts {

    private final static Integer BATCH_SIZE = 5000;

    private String label;

    public KodeverkQueueable(String label) {
        this.label = label;
    }

    private void dontExecute() {
        new LoggerUtility(CRM_ApplicationDomain.Domain.PLATFORCE, 'Kodeverk').infoAndPublish(String.format(
            'Enqueueing not enabled, skipping fetching and storing of {0}.',
            new String[]{this.label}
        ));
    }

    private void doExecute() {
        try {
            Common_Code__c[] codes = KodeverkHelper.getCodesFromMeaningMap(this.label, KodeverkHelper.getMeaningMap(this.label));
            Database.executeBatch(new KodeverkBatchable(codes), BATCH_SIZE);
        } catch (CalloutException ce) {
            new LoggerUtility(CRM_ApplicationDomain.Domain.PLATFORCE, 'Kodeverk').errorAndPublish(
                'CalloutException occurred when attempting to fetch codes:\n' +
                ce.getMessage()
            );
        } catch (Exception e) {
            new LoggerUtility(CRM_ApplicationDomain.Domain.PLATFORCE, 'Kodeverk').criticalAndPublish(
                'Unexpected exception occurred when attempting to fetch codes:\n' +
                e.getMessage()
            );
        }
    }

    /**
     * Fetches and upserts codes, unless disabled in Kodeverk_Config__mdt.
     */
    public void execute(QueueableContext context) {
        Boolean isEnabled = Test.isRunningTest() || [
            SELECT EnqueueEnabled__c
            FROM Kodeverk_Config__mdt
            WHERE DeveloperName = 'default'
            LIMIT 1
        ].EnqueueEnabled__c;
        if (isEnabled) {
            doExecute();
        } else {
            dontExecute();
        }
    }
}
