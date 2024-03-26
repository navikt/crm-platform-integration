global class NOM_Sync_Schedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        NOM_Sync_Schedule.runUpdate();
    } 
    @future(callout=true)
    public static void runUpdate(){
        NOM_Sync.updateAllUnits();
    }
}