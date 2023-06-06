@isTest
public class NOM_OrgEnhetHelper_Test {
    @isTest
    private static void parseEnhetResponseTest(){
        String response = '{"data":{"orgEnhet":{"id":"123456"}}}';
        Boolean exceptionThrown = false;
        try{
            NOM_OrgEnhetHelper.parseEnhetResponse(response);
        }catch(Exception e){
            System.debug(e.getMessage());
            exceptionThrown = true;
        }
        System.assertEquals(false, exceptionThrown, 'parsing failed');
    }
    @isTest
    private static void getFlatHierarchyTest(){
        String response = '{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}';
        NOM_OrgEnhet hierarchy = NOM_OrgEnhetHelper.parseEnhetResponse(response);

        List<NOM_OrgEnhet> flat = NOM_OrgEnhetHelper.getFlatHierarchy(hierarchy, NOM_Retning.over);

        System.assertEquals(2, flat.size());
    }
    @isTest
    private static void getFlatMapHierarchyTest(){
        String response = '{"data":{"orgEnhet":{"id":"123456","organiseringer":[{"retning":"over","orgEnhet":{"id":"234567"}}]}}}';
        NOM_OrgEnhet hierarchy = NOM_OrgEnhetHelper.parseEnhetResponse(response);
        System.debug(hierarchy);
        Map<String,NOM_OrgEnhet> flatHierarchy = NOM_OrgEnhetHelper.getFlatMapHierarchy(hierarchy, NOM_Retning.over);
        System.debug(flatHierarchy);
        System.assertEquals(2, flatHierarchy.size());
        System.assertEquals(true, flatHierarchy.containsKey('123456'));
        System.assertEquals(true, flatHierarchy.containsKey('234567'));
    }
}