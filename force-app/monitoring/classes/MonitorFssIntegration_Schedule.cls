public with sharing class MonitorFssIntegration_Schedule implements Schedulable {
   
    public void execute(SchedulableContext sc) {
       
        LoggerUtility logger = new LoggerUtility();
        logger.error('Integrasjon feilet', null);
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();
    }
}
