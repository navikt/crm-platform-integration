/**
 * Helper class for creating public groups when a NOM unit is created or removed
 * Can be called from flow
 *
 * Why not create all of this as a flow? At the moment of creation it was not possible to test async record triggered flows
 *
 * @author Tor Håkon Sigurdsen
 * @since 2023-06-24
 */
@SuppressWarnings('PMD.ApexDoc') //To avoid the annoying missing @documentation tag
public inherited sharing class NOM_PublicGroupHelper {
    public enum SyncAction {
        CREATE,
        MAINTAIN,
        REMOVE
    }
    private final String GROUP_DEVELOPER_NAME_TEMPLATE = 'nom_{0}';
    private final String GROUP_NAME_TEMPLATE = 'NOM - {0}';
    private final String LOG_MESSAGE_TEMPLATE = '{0} NOM public groups failed - {1}';
    private LoggerUtility logger = new LoggerUtility('NOM');

    /**
     * Invokable method that can be called from flows. It will call the async insert methods in order to create, update or delete the public groups
     * @param nomUnits a list of NOM_PublicGroupHelper.NomUnitSync objects
     */
    @InvocableMethod(
        label='NOM - Update public groups'
        description='Update public groups for NOM units'
        iconName='slds:action:edit_groups'
        category='NOM'
    )
    public static void invokeGroupUpdate(List<NomUnitSync> nomUnits) {
        Set<String> createNomUnitIdSet = new Set<String>();
        Set<String> maintainNomUnitIdSet = new Set<String>();
        Set<String> removeNomUnitIdSet = new Set<String>();

        for (NomUnitSync nomUnit : nomUnits) {
            switch on SyncAction.valueOf(nomUnit.action) {
                when CREATE {
                    createNomUnitIdSet.add(nomUnit.nomUnitId);
                }
                when MAINTAIN {
                    maintainNomUnitIdSet.add(nomUnit.nomUnitId);
                }
                when REMOVE {
                    removeNomUnitIdSet.add(nomUnit.nomUnitId);
                }
            }
        }

        if (createNomUnitIdSet.size() > 0) {
            NOM_PublicGroupHelper.syncPublicGroupCreateAsync(createNomUnitIdSet);
        }

        if (maintainNomUnitIdSet.size() > 0) {
            NOM_PublicGroupHelper.syncPublicGroupMaintainAsync(maintainNomUnitIdSet);
        }

        if (removeNomUnitIdSet.size() > 0) {
            NOM_PublicGroupHelper.syncPublicGroupDeleteAsync(removeNomUnitIdSet);
        }
    }

    /**
     * Async method for creating public groups from NOM units
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    @Future
    public static void syncPublicGroupCreateAsync(Set<String> nomIdSet) {
        new NOM_PublicGroupHelper().syncPublicGroupCreate(nomIdSet);
    }

    /**
     * Async method for updating public groups from NOM units
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    @Future
    public static void syncPublicGroupMaintainAsync(Set<String> nomIdSet) {
        new NOM_PublicGroupHelper().syncPublicGroupMaintain(nomIdSet);
    }

    /**
     * Async method for deleting public groups from NOM units
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    @Future
    public static void syncPublicGroupDeleteAsync(Set<String> nomIdSet) {
        new NOM_PublicGroupHelper().syncPublicGroupDelete(nomIdSet);
    }

    /**
     * Create a public group based on a NOM unit.
     * The group will be created with the following parameters where Name and Developername is decided by an internal constant:
     * Name = "NOM - <NomUnit__c.Name>"
     * DeveloperName => "nom_<NomUnit__c.INT_NomId__c>"
     * DoesIncludeBosses => false;
     * Type => "Regular"
     *
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    public void syncPublicGroupCreate(Set<String> nomIdSet) {
        List<Group> newGroups = new List<Group>();
        List<NomUnit__c> units = this.getNomUnitsSystemMode(nomIdSet);

        if (units.isEmpty()) {
            this.noNomUnitsFound(SyncAction.MAINTAIN, nomIdSet).logger.publish();
            return;
        }

        for (NomUnit__c unit : units) {
            Group g = new Group();
            g.DeveloperName = String.format(GROUP_DEVELOPER_NAME_TEMPLATE, new List<Object>{ unit.INT_NomId__c });
            g.Name = String.format(GROUP_NAME_TEMPLATE, new List<Object>{ unit.Name });
            g.DoesIncludeBosses = false;
            g.Type = 'Regular';
            newGroups.add(g);
        }

        List<Database.SaveResult> srList = Database.insert(newGroups, true, AccessLevel.SYSTEM_MODE);

        this.handleSaveResult(srList, SyncAction.MAINTAIN);

        this.logger.publish();
    }

    /**
     * Update a public group based on a NOM unit.
     * The group will be updated with the following parameters where Developername is decided by an internal constant:
     * Name = "NOM - <NomUnit__c.Name>"
     * DoesIncludeBosses => false;
     *
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    public void syncPublicGroupMaintain(Set<String> nomIdSet) {
        List<Group> groupsToUpdate = new List<Group>();
        Map<String, Group> groupMap = getGroupMap(nomIdSet);

        List<NomUnit__c> units = this.getNomUnitsSystemMode(nomIdSet);

        if (groupMap.isEmpty()) {
            this.logger.logMessage(
                LoggerUtility.LogLevel.Warning,
                null,
                'NomUnit__c',
                createLogMessage(SyncAction.MAINTAIN, false, 'No NOM Units to sync from found in Salesforce'),
                JSON.serializePretty(nomIdSet),
                null,
                CRM_ApplicationDomain.Domain.CRM
            );

            this.logger.publish();
            return;
        }

        if (units.isEmpty()) {
            this.noNomUnitsFound(SyncAction.MAINTAIN, nomIdSet).logger.publish();
            return;
        }

        for (NomUnit__c unit : this.getNomUnitsSystemMode(nomIdSet)) {
            String groupDeveloperName = String.format(
                GROUP_DEVELOPER_NAME_TEMPLATE,
                new List<Object>{ unit.INT_NomId__c }
            );

            Group g = groupMap.get(groupDeveloperName);
            g.Name = String.format(GROUP_NAME_TEMPLATE, new List<Object>{ unit.Name });
            g.DoesIncludeBosses = false;
            groupsToUpdate.add(g);
        }

        List<Database.SaveResult> srList = Database.update(groupsToUpdate, true, AccessLevel.SYSTEM_MODE);

        this.handleSaveResult(srList, SyncAction.MAINTAIN);

        this.logger.publish();
    }

    /**
     * Delete public groups based on a set of NOM unit Ids.
     *
     * @param nomIdSet Set containing the NOM Id, not the NOM Agresso Id
     */
    public void syncPublicGroupDelete(Set<String> nomIdSet) {
        Map<String, Group> groupMap = getGroupMap(nomIdSet);

        if (groupMap.isEmpty()) {
            this.noNomGroupsFound(SyncAction.REMOVE, nomIdSet).logger.publish();
            return;
        }

        Database.delete(groupMap.values(), true, AccessLevel.SYSTEM_MODE);

        this.logger.publish();
    }

    /**
     * Class used as input in the invokable method "NOM - Update public groups" (NOM_PublicGroupHelper.invokeGroupUpdate)
     */
    public class NomUnitSync {
        @InvocableVariable(label='NOM Unit Id' description='The NOM Id' required=true)
        public String nomUnitId;
        @InvocableVariable(label='Action' description='Can be CREATE, MAINTAIN or REMOVE' required=true)
        public String action;
    }

    /**
     * Get a map of NOM public groups with the group developername as key
     * @param   `Set<String>` nomIdSet
     * @returns  `Map<String, Group>`
     */
    private Map<String, Group> getGroupMap(Set<String> nomIdSet) {
        Set<String> groupDeveloperNameSet = new Set<String>();
        Map<String, Group> groupMap = new Map<String, Group>();

        for (NomUnit__c unit : this.getNomUnitsSystemMode(nomIdSet)) {
            groupDeveloperNameSet.add(
                String.format(GROUP_DEVELOPER_NAME_TEMPLATE, new List<Object>{ unit.INT_NomId__c })
            );
        }

        for (Group g : [SELECT Id, Name, DeveloperName FROM Group WHERE DeveloperName IN :groupDeveloperNameSet]) {
            groupMap.put(g.DeveloperName, g);
        }

        return groupMap;
    }

    /**
     * Get a list of NomUnit__c records from
     *
     * @param nomIdSet
     * @return  `List<NomUnit__c>`
     */
    private List<NomUnit__c> getNomUnitsSystemMode(Set<String> nomIdSet) {
        return [SELECT Id, Name, INT_NomId__c FROM NomUnit__c WHERE INT_NomId__c IN :nomIdSet WITH SYSTEM_MODE];
    }

    private String createLogMessage(SyncAction action, Boolean isFailure, String description) {
        return action.name() + ' NOM public groups ' + (isFailure ? 'failure - ' : ' - ') + ' - ' + description;
    }

    private void handleSaveResult(List<Database.SaveResult> srList, SyncAction action) {
        List<Database.Error> errors = new List<Database.Error>();

        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                continue;
            }
            errors.addAll(sr.getErrors());
        }

        if (errors.size() > 0) {
            this.logger.logMessage(
                LoggerUtility.LogLevel.Error,
                null,
                'NomUnit__c',
                createLogMessage(action, true, 'Database.SaveResult errors related to NOM public groups in Salesforce'),
                JSON.serializePretty(errors),
                null,
                CRM_ApplicationDomain.Domain.CRM
            );
        }
    }

    private NOM_PublicGroupHelper noNomUnitsFound(SyncAction action, Set<String> nomIdSet) {
        this.logger.logMessage(
            LoggerUtility.LogLevel.Warning,
            null,
            'NomUnit__c',
            createLogMessage(action, false, 'Could not find the relevant NOM units in Salesforce'),
            JSON.serializePretty(nomIdSet),
            null,
            CRM_ApplicationDomain.Domain.CRM
        );

        return this;
    }

    private NOM_PublicGroupHelper noNomGroupsFound(SyncAction action, Set<String> nomIdSet) {
        this.logger.logMessage(
            LoggerUtility.LogLevel.Warning,
            null,
            'NomUnit__c',
            createLogMessage(action, false, 'No NOM groups found'),
            JSON.serializePretty(nomIdSet),
            null,
            CRM_ApplicationDomain.Domain.CRM
        );

        return this;
    }
}
