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

        /* ----- UPDATE ROLES ------ */
        List<NomRole__c> roles = getAllManagers();
        List<NomRole__c> rolesToInsert = getRolesForInsert(orgEnhetMap, unitsToInsert);
        List<NomRole__c> rolesToUpdate = getRolesForUpdate(roles,orgEnhetMap);
        List<NomRole__c> rolesToDelete = getRolesForDelete(roles,orgEnhetMap);
        
        List<NomRole__c> rolesToUpsert = new List<NomRole__c>();
        rolesToUpsert.addAll(rolesToInsert);
        rolesToUpsert.addAll(rolesToUpdate);
        try {
            upsert rolesToUpsert;
        } catch (DmlException e) {
            NOM_OrgEnhetHelper.logException(e);
        }
        try {
            delete rolesToDelete;
        } catch (DmlException e) {
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
        Set<String> enhetIds= new Set<String>(orgEnhetMap.keySet());
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
    private static List<NomRole__c> getAllManagers(){
        List<NomRole__c> roles = [
            SELECT Id, CRM_NomUnit__c, CRM_NomUnit__r.INT_NomId__c, CRM_Role__c, CRM_RoleHoldersEmail__c, Name, CRM_RoleHoldersNAVIdent__c, CRM_RoleHoldersSFUser__c
            FROM NomRole__c
            WHERE CRM_Role__c = 'Leder'
        ];
        return roles;
    }
    private static List<NomRole__c> getRolesForInsert(Map<String,NOM_OrgEnhet> orgEnhetMap, List<NomUnit__c> insertedUnits){
        List<NomRole__c> rolesForInsert = new List<NomRole__c>();
        for(NomUnit__c unit : insertedUnits){
            NOM_OrgEnhet enhet = orgEnhetMap.get(unit.INT_NomId__c);
            NomRole__c role = new NomRole__c();
            role.CRM_NomUnit__c = unit.Id;
            role.CRM_Role__c = 'Leder';
            role.CRM_RoleHoldersEmail__c = enhet.leder[0].ressurs.epost;
            role.CRM_RoleHoldersNAVIdent__c = enhet.leder[0].ressurs.navident;
            role.Name = enhet.leder[0].ressurs.visningsnavn;
            rolesForInsert.add(role);
        }
        return rolesForInsert;
    }
    private static List<NomRole__c> getRolesForUpdate(List<NomRole__c> roles, Map<String, NOM_OrgEnhet> orgEnhetMap){
        List<NomRole__c> rolesToUpdate = new List<NomRole__c>();
        for(NomRole__c role : roles){
            if(orgEnhetMap.containsKey(role.CRM_NomUnit__r.INT_NomId__c)){
                NOM_Ressurs ressurs = orgEnhetMap.get(role.CRM_NomUnit__r.INT_NomId__c).leder[0].ressurs;
                if( NOM_OrgEnhetHelper.isUpdated(role, ressurs)){
                    role.CRM_RoleHoldersEmail__c = ressurs.epost;
                    role.CRM_RoleHoldersNAVIdent__c = ressurs.navident;
                    role.Name = ressurs.visningsnavn;
                    role.CRM_RoleHoldersSFUser__c = null;
                    rolesToUpdate.add(role);
                }
            }
        }
        return rolesToUpdate;
    }
    private static List<NomRole__c> getRolesForDelete(List<NomRole__c> roles, Map<String, NOM_OrgEnhet> orgEnhetMap){
        List<NomRole__c> rolesToDelete = new List<NomRole__c>();
        for(NomRole__c role : roles){
            if(!orgEnhetMap.containsKey(role.CRM_NomUnit__r.INT_NomId__c)){
                rolesToDelete.add(role);
            }
        }
        return rolesToDelete;
    }
}