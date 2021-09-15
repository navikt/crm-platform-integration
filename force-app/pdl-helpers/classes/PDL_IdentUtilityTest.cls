@IsTest
private with sharing class PDL_IdentUtilityTest {
    @IsTest
    static void testGetValues() {
        Test.startTest();
        System.assertEquals(
            '1234567890123',
            Pdl_IdentUtility.getAktorId(getIdentList()),
            'Expected to get the AKTORID'
        );
        System.assertEquals('12345678911', Pdl_IdentUtility.getNpid(getIdentList()), 'Expected to get the NPID');
        System.assertEquals('12345678901', Pdl_IdentUtility.getFnr(getIdentList()), 'Expected to get the FNR');
        System.assertEquals('52345678901', Pdl_IdentUtility.getDnr(getIdentList()), 'Expected to get the DNR');
        Test.stopTest();
    }

    @IsTest
    static void testGetActiveDnr() {
        PDL_Ident dnr = new PDL_Ident();
        dnr.gruppe = PDL_Ident.IdentGruppe.FOLKEREGISTERIDENT;
        dnr.historisk = false;
        dnr.ident = '52345678901';

        PDL_Ident npid = new PDL_Ident();
        npid.gruppe = PDL_Ident.IdentGruppe.NPID;
        npid.historisk = false;
        npid.ident = '12345678911';

        Test.startTest();
        System.assertEquals(
            '52345678901',
            Pdl_IdentUtility.getDnr(new List<PDL_Ident>{ dnr, npid }),
            'Expected to get the DNR'
        );
        System.assertEquals(
            '52345678901',
            Pdl_IdentUtility.getDnr(getIdentList()),
            'Expected to get the DNR 52345678901'
        );
        Test.stopTest();
    }

    @IsTest
    static void getIdentsFromListTest() {
        Pdl_IdentUtility.PersonIdent result;

        Test.startTest();
        result = Pdl_IdentUtility.getIdentsFromList(getIdentList());
        Test.stopTest();

        System.assertEquals('1234567890123', result.actorId, 'Expected to have the actorId set correctly');
        System.assertEquals('12345678911', result.npid, 'Expected to have the npid set correctly');
        System.assertEquals('12345678901', result.fnr, 'Expected to have the fnr set correctly');
        System.assertEquals('52345678901', result.dnr, 'Expected to have the dnr set correctly');
    }

    private static List<PDL_Ident> getIdentList() {
        List<PDL_Ident> identList = new List<PDL_Ident>();
        identList.add(new PDL_Ident());
        identList[0].gruppe = PDL_Ident.IdentGruppe.AKTORID;
        identList[0].historisk = false;
        identList[0].ident = '1234567890123';

        identList.add(new PDL_Ident());
        identList[1].gruppe = PDL_Ident.IdentGruppe.NPID;
        identList[1].historisk = false;
        identList[1].ident = '12345678911';

        identList.add(new PDL_Ident());
        identList[2].gruppe = PDL_Ident.IdentGruppe.FOLKEREGISTERIDENT;
        identList[2].historisk = false;
        identList[2].ident = '12345678901';

        identList.add(new PDL_Ident());
        identList[3].gruppe = PDL_Ident.IdentGruppe.FOLKEREGISTERIDENT;
        identList[3].historisk = true;
        identList[3].ident = '52345678901';

        return identList;
    }
}
