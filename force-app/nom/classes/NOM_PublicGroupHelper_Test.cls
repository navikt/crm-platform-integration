@IsTest
private with sharing class NOM_PublicGroupHelper_Test {
    @IsTest
    static void testCreateNewPublicGroup() {
        NomUnit__c u1 = new NomUnit__c();
        u1.INT_isActive__c = false; //test
        u1.INT_NomId__c = 'py437s';
        u1.INT_NomLevel__c = null;
        u1.INT_OrgLevel__c = 'ORGNIV0';
        u1.INT_UnitType__c = null;
        u1.Name = 'NAV';

        NomUnit__c u2 = new NomUnit__c();
        u2.INT_isActive__c = true;
        u2.INT_NomId__c = 'bu431e';
        u2.INT_NomLevel__c = 'DRIFTSENHET';
        u2.INT_OrgLevel__c = 'ORGNIV0'; //test
        u2.INT_UnitType__c = 'DIR';
        u2.Name = 'Direktoratet';

        Test.startTest();
        insert new List<NomUnit__c>{ u1, u2 };
        Test.stopTest();

        Map<String, Group> groupMap = new Map<String, Group>();

        for (Group g : [SELECT Id, Name, DeveloperName FROM Group]) {
            groupMap.put(g.DeveloperName, g);
        }

        Assert.isNotNull(groupMap.get('nom_py437s'), 'Expected to find a group with the developername nom_py437s');
        Assert.isNotNull(groupMap.get('nom_bu431e'), 'Expected to find a group with the developername nom_bu431e');
    }

    @IsTest
    static void testUpdatePublicGroup() {
        NomUnit__c u1 = new NomUnit__c();
        u1.INT_isActive__c = false; //test
        u1.INT_NomId__c = 'py437s';
        u1.INT_NomLevel__c = null;
        u1.INT_OrgLevel__c = 'ORGNIV0';
        u1.INT_UnitType__c = null;
        u1.Name = 'NAV';

        NomUnit__c u2 = new NomUnit__c();
        u2.INT_isActive__c = true;
        u2.INT_NomId__c = 'bu431e';
        u2.INT_NomLevel__c = 'DRIFTSENHET';
        u2.INT_OrgLevel__c = 'ORGNIV0'; //test
        u2.INT_UnitType__c = 'DIR';
        u2.Name = 'Direktoratet';
        insert new List<NomUnit__c>{ u1, u2 };

        u1.Name += 'TEST';
        u2.Name += 'TEST';

        Test.startTest();
        update new List<NomUnit__c>{ u1, u2 };
        Test.stopTest();

        Map<String, Group> groupMap = new Map<String, Group>();

        for (Group g : [SELECT Id, Name, DeveloperName FROM Group]) {
            groupMap.put(g.DeveloperName, g);
        }

        Assert.areEqual('NOM - NAVTEST', groupMap.get('nom_py437s').Name, 'Expected to have name updated');
        Assert.areEqual('NOM - DirektoratetTEST', groupMap.get('nom_bu431e').Name, 'Expected to have name updated');
    }

    @IsTest
    static void testDeletePublicGroup() {
        NomUnit__c u1 = new NomUnit__c();
        u1.INT_isActive__c = false; //test
        u1.INT_NomId__c = 'py437s';
        u1.INT_NomLevel__c = null;
        u1.INT_OrgLevel__c = 'ORGNIV0';
        u1.INT_UnitType__c = null;
        u1.Name = 'NAV';

        NomUnit__c u2 = new NomUnit__c();
        u2.INT_isActive__c = true;
        u2.INT_NomId__c = 'bu431e';
        u2.INT_NomLevel__c = 'DRIFTSENHET';
        u2.INT_OrgLevel__c = 'ORGNIV0'; //test
        u2.INT_UnitType__c = 'DIR';
        u2.Name = 'Direktoratet';
        insert new List<NomUnit__c>{ u1, u2 };

        Test.startTest();
        delete new List<NomUnit__c>{ u1, u2 };
        Test.stopTest();

        Map<String, Group> groupMap = new Map<String, Group>();

        for (Group g : [SELECT Id, name, DeveloperName FROM Group]) {
            groupMap.put(g.DeveloperName, g);
        }

        Assert.isNull(
            groupMap.get('nom_py437s'),
            'Expected that the group with developername nom_py437s had been deleted'
        );
        Assert.isNull(
            groupMap.get('nom_bu431e'),
            'Expected that the group with developername nom_bu431e had been deleted'
        );
    }

    @IsTest
    static void createWithoutExistingGroups() {
        Integer numberOfLogsAtStart = Database.countQuery(
            'SELECT COUNT() FROM Application_Log__c',
            AccessLevel.SYSTEM_MODE
        );
        Test.startTest();
        NOM_PublicGroupHelper.NomUnitSync sync = new NOM_PublicGroupHelper.NomUnitSync();
        sync.action = NOM_PublicGroupHelper.SyncAction.CREATE.name();
        sync.nomUnitId = 'asdkjasld';

        try {
            NOM_PublicGroupHelper.invokeGroupUpdate(new List<NOM_PublicGroupHelper.NomUnitSync>{ sync });
        } catch (Exception e) {
            Assert.fail('Did not expect any exception');
        }
        Test.stopTest();

        List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c WITH SYSTEM_MODE];
        Map<String, Group> groupMap = new Map<String, Group>();

        for (Group g : [SELECT Id, name, DeveloperName FROM Group]) {
            groupMap.put(g.DeveloperName, g);
        }

        Assert.isNull(groupMap.get('nom_asdkjasld'), 'Expected to find a group with the developername nom_py437s');
        Assert.isTrue(numberOfLogsAtStart < logs.size(), 'Expected that the number of logs had increased');
    }

    @IsTest
    static void deleteWithoutExistingGroups() {
        Integer numberOfLogsAtStart = Database.countQuery(
            'SELECT COUNT() FROM Application_Log__c',
            AccessLevel.SYSTEM_MODE
        );

        Test.startTest();
        NOM_PublicGroupHelper.NomUnitSync sync = new NOM_PublicGroupHelper.NomUnitSync();
        sync.action = NOM_PublicGroupHelper.SyncAction.REMOVE.name();
        sync.nomUnitId = 'asdkjasld';

        try {
            NOM_PublicGroupHelper.invokeGroupUpdate(new List<NOM_PublicGroupHelper.NomUnitSync>{ sync });
        } catch (Exception e) {
            Assert.fail('Did not expect any exception');
        }
        Test.stopTest();

        List<Application_Log__c> logs = [SELECT Id FROM Application_Log__c WITH SYSTEM_MODE];
        Assert.isTrue(numberOfLogsAtStart < logs.size(), 'Expected that the number of logs had increased');
    }
}
