@isTest
public class NOM_OrgEnhetHelper_Test {
    @isTest
    private static void parseEnhetResponseTest() {
        String response = '{"data":{"orgEnhet":{"id":"123456"}}}';
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
    private static void getFlatHierarchyTest() {
        String response = '{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}';
        NOM_OrgEnhet hierarchy = NOM_OrgEnhetHelper.parseEnhetResponse(response);

        List<NOM_OrgEnhet> flat = NOM_OrgEnhetHelper.getFlatHierarchy(hierarchy, NOM_Retning.over);

        System.assertEquals(2, flat.size());
    }
    @isTest
    private static void getFlatMapHierarchyTest() {
        String response = '{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}';
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
}
