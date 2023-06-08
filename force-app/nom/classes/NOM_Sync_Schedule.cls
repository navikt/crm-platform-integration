global class NOM_Sync_Schedule implements Schedulable{
    public void execute(SchedulableContext sc) {
        NOM_Sync.updateAllUnits();
    } 
}