public with sharing class MonitorFssIntegration implements Schedulable {
    public void execute(SchedulableContext sc) {
        MonitorFssIntegration_Schedule fssIntegration=new MonitorFssIntegration_Schedule();
        System.enqueueJob(fssIntegration);
    }

}
