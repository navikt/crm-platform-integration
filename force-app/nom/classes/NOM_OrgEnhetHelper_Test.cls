@isTest
public class NOM_OrgEnhetHelper_Test {
    @isTest
    private static void parseEnhetResponseTest(){
        NOM_Response response = (NOM_Response) JSON.deserialize('{"data":{"orgEnhet":{"id":"123456"}}}',NOM_Response.class);
        Boolean exceptionThrown = false;
        try {
            NOM_OrgEnhetHelper.parseEnhetResponse(response);
        } catch (Exception e) {
            System.debug(e.getMessage());
            exceptionThrown = true;
        }
        System.assertEquals(false, exceptionThrown, 'parsing failed');
    }
    @isTest
    private static void getFlatHierarchyTest(){
        NOM_Response response = (NOM_Response) JSON.deserialize('{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}',NOM_Response.class);
        NOM_OrgEnhet hierarchy = NOM_OrgEnhetHelper.parseEnhetResponse(response);

        List<NOM_OrgEnhet> flat = NOM_OrgEnhetHelper.getFlatHierarchy(hierarchy, NOM_Retning.over);

        System.assertEquals(2, flat.size());
    }
    @isTest
    private static void getFlatMapHierarchyTest(){
        NOM_Response response = (NOM_Response) JSON.deserialize('{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}',NOM_Response.class);
        NOM_OrgEnhet hierarchy = NOM_OrgEnhetHelper.parseEnhetResponse(response);
        System.debug(hierarchy);
        Map<String, NOM_OrgEnhet> flatHierarchy = NOM_OrgEnhetHelper.getFlatMapHierarchy(hierarchy, NOM_Retning.over);
        System.debug(flatHierarchy);
        System.assertEquals(2, flatHierarchy.size());
        System.assertEquals(true, flatHierarchy.containsKey('123456'));
        System.assertEquals(true, flatHierarchy.containsKey('234567'));
    }

    @isTest
    static void getEnhetHierarchiesTest() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('NOM_OrgEnhetHelperTest_getEnhetHierarchiesTest');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        List<NOM_OrgEnhetResult> result;

        Test.startTest();
        result = NOM_OrgEnhetHelper.getEnhetHierarchies(new List<String>{ '' }, NOM_Retning.over, 10);
        Test.stopTest();

        Assert.isNotNull(result, 'Expected to get a response');
        Assert.areEqual(2, result.size(), 'Expected two entries returned from the mock');
        Assert.areEqual(
            0,
            Database.countQuery('SELECT Count() FROM Application_Log__c'),
            'Did not expect any application logs'
        );
    }

    @isTest
    static void getEnhetHierarchiesTest404() {
        SingleRequestMock mock = new SingleRequestMock(
            404,
            'Not Found',
            '',
            new Map<String, String>{ 'Content-Type' => 'application/json' }
        );

        Test.setMock(HttpCalloutMock.class, mock);

        List<NOM_OrgEnhetResult> result;

        Test.startTest();
        try {
            NOM_OrgEnhetHelper.getEnhetHierarchies(new List<String>{ '' }, NOM_Retning.over, 10);
            Assert.fail('Expected NOM_HelperException exeption to be thrown');
        } catch (Exception ex) {
            Assert.isInstanceOfType(
                ex,
                NOM_OrgEnhetHelper.NOM_HelperException.class,
                'Did not return the expected exception'
            );
        }
        Test.stopTest();

        Assert.areEqual(
            1,
            Database.countQuery('SELECT Count() FROM Application_Log__c'),
            'Did not expect any application logs'
        );
    }

    @isTest
    static void getEnhetHierarchiesTestCalloutException() {
        CalloutExceptionRequestMock mock = new CalloutExceptionRequestMock('Some callout exception');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            NOM_OrgEnhetHelper.getEnhetHierarchies(new List<String>{ '' }, NOM_Retning.over, 10);
            Assert.fail('Expected NOM_HelperException exeption to be thrown');
        } catch (Exception ex) {
            Assert.isInstanceOfType(
                ex,
                NOM_OrgEnhetHelper.NOM_HelperException.class,
                'Did not return the expected exception'
            );
        }
        Test.stopTest();

        Assert.areEqual(
            1,
            Database.countQuery('SELECT Count() FROM Application_Log__c'),
            'Did not expect any application logs'
        );
    }

    @isTest
    static void getEnhetHierarchiesTestError() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('Test_GenericGraphQlError');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        try {
            NOM_OrgEnhetHelper.getEnhetHierarchies(new List<String>{ '' }, NOM_Retning.over, 10);
            Assert.fail('Expected NOM_HelperException exeption to be thrown');
        } catch (Exception ex) {
            Assert.isInstanceOfType(
                ex,
                NOM_OrgEnhetHelper.NOM_HelperException.class,
                'Did not return the expected exception'
            );
        }
        Test.stopTest();

        Assert.areEqual(
            0,
            Database.countQuery('SELECT Count() FROM Application_Log__c'),
            'Did not expect any application logs'
        );
    }

    @isTest
    static void getEnhetHierarchiesMap() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('NOM_OrgEnhetHelperTest_getEnhetHierarchiesTest');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        Test.setMock(HttpCalloutMock.class, mock);

        Map<String, NOM_OrgEnhet> result;

        Test.startTest();
        result = NOM_OrgEnhetHelper.getEnhetHierarchiesMap(new List<String>{ '' }, NOM_Retning.over, 10);
        Test.stopTest();

        Assert.areEqual(2, result.size(), 'Esxpected two hierarchies');
        Assert.isNotNull(result.get('bu878z'), 'Expected to find a unit');
        Assert.areEqual(
            'bu431e',
            result.get('bu878z').organiseringer[0].orgEnhet.id,
            'Expected to find the next unit in the hierarchy'
        );

        Assert.areEqual(
            0,
            Database.countQuery('SELECT Count() FROM Application_Log__c'),
            'Did not expect any application logs'
        );
    }

    @isTest
    private static void getEnhetHierarchyTest(){
        ApiMock.setTestMock('POST_NOM', 200, 'OK');
        NOM_OrgEnhet enhet = NOM_OrgEnhetHelper.getEnhetHierarchy('test', NOM_Retning.over, 5);
        System.assertNotEquals(null, enhet);
    }
    @isTest
    private static void getEnhetQueryTest(){
        String query = NOM_OrgEnhetHelper.getEnhetQuery('test', NOM_Retning.over, 1);
        System.assertEquals('{"variables":{"id":"test"},"query":"query HentHierarki($id: String! ){ orgEnhet(where : {id : $id } ){ leder{ ressurs{ navident epost visningsnavn}} id agressoId navn orgNiv nomNivaa orgEnhetsType organiseringer(retning : over ){ orgEnhet{ agressoId id navn orgNiv nomNivaa orgEnhetsType leder{ ressurs{ navident epost visningsnavn}}} retning gyldigFom gyldigTom}}}"}',
            query
        );
    }
    @isTest
    private static void getEnhetIdForNavIdQueryTest(){
        String query = NOM_OrgEnhetHelper.getEnhetIdForNavIdQuery('test');
        System.assertEquals(
            '{"variables":{"navId":"test"},"query":"query ($navId: String! ){ ressurs(where : {navident : $navId } ){ orgTilknytning{ orgEnhet{ id} gyldigFom gyldigTom}}}"}',
            query
        );
    }
    @isTest
    private static void orgEnhetToNomUnitTest(){
        NOM_OrgEnhet enhet = new NOM_OrgEnhet();
        enhet.Id = 'testid';
        enhet.navn = 'Test Name';
        enhet.orgEnhetsType = NOM_OrgEnhetsType.DIR;
        enhet.nomNivaa =  NOM_OrgEnhetsKategori.ARBEIDSOMRAADE;
        enhet.orgNiv = null;
        NomUnit__c unit = NOM_OrgEnhetHelper.orgEnhetToNomUnit(enhet);
        System.assertEquals(enhet.Id, unit?.INT_NomId__c);
    }
    @isTest
    private static void nomUnitToOrgEnhetTest(){
        NomUnit__c unit = new NomUnit__c();
        unit.INT_NomId__c = 'testid';
        unit.Name = 'Test Name';
        unit.INT_UnitType__c = NOM_OrgEnhetsType.DIR.name();
        unit.INT_NomLevel__c = NOM_OrgEnhetsKategori.ARBEIDSOMRAADE.name();
        unit.INT_OrgLevel__c = null;
        NOM_OrgEnhet enhet = NOM_OrgEnhetHelper.nomUnitToOrgEnhet(unit);
        System.assertEquals(unit.INT_NomId__c, enhet.id);
    }
    @isTest
    private static void updateNomUnitFromOrgEnhetTest(){
        NOM_OrgEnhet enhet = new NOM_OrgEnhet();
        enhet.Id = 'testid';
        enhet.navn = 'Test Name';
        enhet.orgEnhetsType = NOM_OrgEnhetsType.DIR;
        enhet.nomNivaa =  NOM_OrgEnhetsKategori.ARBEIDSOMRAADE;
        enhet.orgNiv = null;
        NomUnit__c unit = new NomUnit__c();
        unit = NOM_OrgEnhetHelper.updateNomUnitFromOrgEnhet(unit, enhet);
        System.assertEquals(enhet.navn, unit.Name);
    }
    @isTest
    private  static void isUpdatedTest(){
        NOM_OrgEnhet enhet = new NOM_OrgEnhet();
        enhet.Id = 'testid';
        enhet.navn = 'Test Name';
        enhet.orgEnhetsType = NOM_OrgEnhetsType.DIR;
        enhet.nomNivaa =  NOM_OrgEnhetsKategori.ARBEIDSOMRAADE;
        enhet.orgNiv = null;
        NomUnit__c unit = new NomUnit__c();
        unit.INT_IsActive__c = true;
        unit.INT_NomId__c = 'testid';
        unit.Name = 'Test Name';
        unit.INT_UnitType__c = NOM_OrgEnhetsType.DIR.name();
        unit.INT_NomLevel__c = NOM_OrgEnhetsKategori.ARBEIDSOMRAADE.name();
        unit.INT_OrgLevel__c = null;
        System.assertEquals(false, NOM_OrgEnhetHelper.isUpdated(unit,enhet));
        unit.INT_IsActive__c = false;
        System.assertEquals(true, NOM_OrgEnhetHelper.isUpdated(unit,enhet));
    }
}
