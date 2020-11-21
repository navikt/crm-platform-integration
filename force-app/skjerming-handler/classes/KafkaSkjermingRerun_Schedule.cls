/* rerun skjerming kafka messages who has failed */
public with sharing class KafkaSkjermingRerun_Schedule implements Schedulable, Database.Batchable<SObject> {
   
    private final String SKJERMING_FAILED_KAFKA_QUERY='SELECT CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE LastModifiedDate>=YESTERDAY AND CRM_Topic__c = \'aapen-skjermede-personer-v1\' AND CRM_Status__c=\'Error\'';
    public void execute( SchedulableContext sc ) {
		KafkaSkjermingRerun_Schedule  btch = new KafkaSkjermingRerun_Schedule ();
		Database.executeBatch( btch, 2000 );
	}

	public Database.QueryLocator start( Database.BatchableContext BC ) {
		return Database.getQueryLocator( SKJERMING_FAILED_KAFKA_QUERY);
	}

	public void execute( Database.BatchableContext BC, List<KafkaMessage__c> scope ) {
        for(KafkaMessage__c msg:scope){
            msg.CRM_Status__c= KafkaMessageService.STATUS_PENDING;
            msg.CRM_ErrorMessage__c=null;
        }
        update scope;
    }

    public void finish( Database.BatchableContext BC ) {
	}
}
