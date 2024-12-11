@IsTest
public with sharing class NOM_RessursHelper_Test {
    @isTest
    private static void getEnhetHierarchyTest(){
        ApiMock.setTestMock('POST_NOM', 200, 'OK');
        NOM_Ressurs ressurs = NOM_RessursHelper.getRessursFromIdent('Z999999');
        Assert.isNotNull(ressurs);
    }
}