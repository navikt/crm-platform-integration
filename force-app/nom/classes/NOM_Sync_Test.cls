@isTest
public class NOM_Sync_Test {
    @isTest
    private static void updateAllUnitsTest(){
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
        u2.INT_UnitType__c = 'DIREKTORAT';
        u2.Name = 'Direktoratet';
        NomUnit__c u3 = new NomUnit__c();
        u3.INT_isActive__c = true;
        u3.INT_NomId__c = 'bu878z';
        u3.INT_NomLevel__c = 'ARBEIDSOMRAADE';
        u3.INT_OrgLevel__c = 'ORGNIV2';
        u3.INT_UnitType__c = 'DIREKTORAT';
        u3.Name = 'Avdelingen';
        NomUnit__c u4 = new NomUnit__c();
        u4.INT_isActive__c = true;
        u4.INT_NomId__c = 'pe167m';
        u4.INT_NomLevel__c = null;
        u4.INT_OrgLevel__c = 'ORGNIV25';
        u4.INT_UnitType__c = 'DIREKTORAT';
        u4.Name = 'IT';
        NomUnit__c u5 = new NomUnit__c(); 
        u5.INT_isActive__c = true; //test
        u5.INT_NomId__c = '111111';
        u5.INT_NomLevel__c = null;
        u5.INT_OrgLevel__c = 'ORGNIV25';
        u5.INT_UnitType__c = 'DIREKTORAT';
        u5.Name = 'TestActive';
        NomUnit__c u6 = new NomUnit__c();
        u6.INT_isActive__c = false; //test
        u6.INT_NomId__c = '222222';
        u6.INT_NomLevel__c = null;
        u6.INT_OrgLevel__c = 'ORGNIV25';
        u6.INT_UnitType__c = 'DIREKTORAT';
        u6.Name = 'TestInactive';

        insert new List<NomUnit__c>{u1,u2,u3,u4,u5,u6};

        NomRole__c r1 = new NomRole__c();
        r1.CRM_NomUnit__c = u1.Id;
        r1.CRM_Role__c = 'Leder';
        r1.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r1.CRM_RoleHoldersNAVIdent__c = 'id11111';

        NomRole__c r2 = new NomRole__c();
        r2.CRM_NomUnit__c = u2.Id;
        r2.CRM_Role__c = 'Leder';
        r2.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r2.CRM_RoleHoldersNAVIdent__c = 'id11111';

        NomRole__c r3 = new NomRole__c();
        r3.CRM_NomUnit__c = u3.Id;
        r3.CRM_Role__c = 'Leder';
        r3.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r3.CRM_RoleHoldersNAVIdent__c = 'id11111';

        NomRole__c r4 = new NomRole__c();
        r4.CRM_NomUnit__c = u4.Id;
        r4.CRM_Role__c = 'Leder';
        r4.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r4.CRM_RoleHoldersNAVIdent__c = 'id11111';

        NomRole__c r5 = new NomRole__c();
        r5.CRM_NomUnit__c = u5.Id;
        r5.CRM_Role__c = 'Leder';
        r5.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r5.CRM_RoleHoldersNAVIdent__c = 'id11111';

        NomRole__c r6 = new NomRole__c();
        r6.CRM_NomUnit__c = u6.Id;
        r6.CRM_Role__c = 'Leder';
        r6.CRM_RoleHoldersEmail__c = 'fake@fakeemail.no';
        r6.CRM_RoleHoldersNAVIdent__c = 'id11111';

        insert new List<NomRole__c>{r1,r2,r3,r4,r5,r6};

        ApiMock.setTestMock('POST_NOM', 200, 'OK');

        Test.startTest();

        NOM_Sync.updateAllUnits();

        Test.stopTest();

        List<NomUnit__c> units = [SELECT Id, Name, INT_NomId__c, INT_NomLevel__c, INT_OrgLevel__c, INT_UnitType__c, INT_IsActive__c
        FROM NomUnit__c];

        System.assertEquals(8, units.size(), 'total NomUnit count does not match');

        NomUnit__c u1t,u2t,u3t,u4t,u5t,u6t,u7t,u8t;
        for(NomUnit__c u : units){
            if(u.INT_NomId__c == 'py437s'){
                u1t = u;
            }else if(u.INT_NomId__c == 'bu431e'){
                u2t = u;
            }else if(u.INT_NomId__c == 'bu878z'){
                u3t = u;
            }else if(u.INT_NomId__c == 'pe167m'){
                u4t = u;
            }else if(u.INT_NomId__c == '111111'){
                u5t = u;
            }else if(u.INT_NomId__c == '222222'){
                u6t = u;
            }else if(u.INT_NomId__c == 'da992d'){
                u7t = u;
            }else if(u.INT_NomId__c == 'vy824j'){
                u8t = u;
            }
        }
     
        System.assertEquals(true, u1t.INT_isActive__c);
        System.assertEquals('ORGNIV1', u2t.INT_OrgLevel__c);
        System.assertEquals(false, u5t.INT_isActive__c);
        System.assertEquals(false, u6t.INT_isActive__c);
        System.assertEquals(true, u7t.INT_isActive__c);
        System.assertEquals(true, u8t.INT_isActive__c);

        List<NomRole__c> roles = [SELECT Id, CRM_NomUnit__c, CRM_NomUnit__r.INT_NomId__c, CRM_Role__c, CRM_RoleHoldersEmail__c, Name, CRM_RoleHoldersNAVIdent__c, CRM_RoleHoldersSFUser__c
        FROM NomRole__c
        WHERE CRM_Role__c = 'Leder'];
        System.debug(roles);

        System.assertEquals(6, roles.size(), 'roles count');
       
    }
}