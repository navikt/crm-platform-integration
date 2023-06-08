public with sharing class NOM_Sync {
    public static void updateAllUnits(){

        String rootId = NOM_OrgEnhetHelper.getRootUnit();

        Map<String,NOM_OrgEnhet> orgEnhetMap = NOM_OrgEnhetHelper.getFlatMapHierarchy(NOM_OrgEnhetHelper.getEnhetHierarchy(rootId, NOM_Retning.under, 10),NOM_Retning.under);
        List<NomUnit__c> nomUnits  = getAllNomUnits();
        List<NomUnit__c> unitsToUpdate = getUnitsForUpdate(nomUnits, orgEnhetMap);
        List<NomUnit__c> unitsToInsert = getUnitsForInsert(nomUnits, orgEnhetMap);

        List<NomUnit__c> unitsToUpsert = new List<NomUnit__c>();
        unitsToUpsert.addAll(unitsToInsert);
        unitsToUpsert.addAll(unitsToUpdate);

        try{
            upsert unitsToUpsert;
        }catch(DmlException e){
            NOM_OrgEnhetHelper.logException(e);
        }
    }

    private static List<NomUnit__c> getAllNomUnits(){
        List<NomUnit__c> nomUnits = [
            SELECT Id, Name, INT_NomId__c, INT_NomLevel__c, INT_OrgLevel__c, INT_UnitType__c, INT_IsActive__c
            FROM NomUnit__c
        ];
        return nomUnits;
    }
    private static List<NomUnit__c> getUnitsForUpdate(List<NomUnit__c> nomUnits, Map<String,NOM_OrgEnhet> orgEnhetMap){

        List<NomUnit__c> unitsToUpdate = new List<NomUnit__c>();
        for(NomUnit__c unit : nomUnits){
            if(orgEnhetMap.keySet().contains(unit.INT_NomId__c)){
                if(NOM_OrgEnhetHelper.isUpdated(unit, orgEnhetMap.get(unit.INT_NomId__c))){
                    unit.Name = orgEnhetMap.get(unit.INT_NomId__c).navn;
                    unit.INT_UnitType__c = orgEnhetMap.get(unit.INT_NomId__c).orgEnhetsType?.name();
                    unit.INT_NomLevel__c = orgEnhetMap.get(unit.INT_NomId__c).nomNivaa?.name();
                    unit.INT_OrgLevel__c = orgEnhetMap.get(unit.INT_NomId__c).orgNiv;
                    unit.INT_IsActive__c = true;
                    unitsToUpdate.add(NOM_OrgEnhetHelper.updateNomUnitFromOrgEnhet(unit, orgEnhetMap.get(unit.INT_NomId__c)));
                    
                }
            }else{
                if(unit.INT_isActive__c == true){
                    unit.INT_IsActive__c = false;
                    unitsToUpdate.add(unit);
                }
            }
        }
        return unitsToUpdate;
    }
    private static List<NomUnit__c> getUnitsForInsert(List<NomUnit__c> nomUnits, Map<String,NOM_OrgEnhet> orgEnhetMap){
        Set<String> existingUnitIds = new Set<String>();
        for(NomUnit__c unit : nomUnits){
            existingUnitIds.add(unit.INT_NomId__c);
        }
        List<NomUnit__c> unitsToInsert = new List<NomUnit__c>();
        Set<String> enhetIds= orgEnhetMap.keySet();
        enhetIds.removeAll(existingUnitIds);
        for(String enhetId : enhetIds){
            NomUnit__c nu = NOM_OrgEnhetHelper.orgEnhetToNomUnit(
                orgEnhetMap.get(enhetId)
            );
            nu.INT_isActive__c = true;
            unitsToInsert.add(
                nu
            );
        }
        return unitsToInsert;
    }
    private static Set<String> getUnitsNomIds(List<NomUnit__c> units){
        Set<String> unitsIds = new Set<String>();
        for(NomUnit__c unit : units){
            unitsIds.add(unit.INT_NomId__c);
        }
        return unitsIds;
    }
}