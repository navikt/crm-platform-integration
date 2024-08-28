@isTest
public with sharing class FullmaktServiceTest {
    @IsTest
    static void testGetFullmaktsgiver(){
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER.name(), 200, 'OK');
        String identNr = '123456790';

        Test.startTest();
        HttpResponse resp = FullmaktService.getFullmaktsgiver(identNr);
        Test.stopTest();

        Assert.areEqual(resp.getStatusCode(), 200);
    }

    
    @IsTest
    static void testGetFullmaktsgiverHistorikk(){
        ApiMock.setTestMock(FullmaktService.services.GET_FULLMAKTSGIVER_HISTORIKK.name(), 200, 'OK');
        String identNr = '123456790';

        Test.startTest();
        HttpResponse resp = FullmaktService.getFullmaktsgiverHistorikk(identNr);
        Test.stopTest();

        Assert.areEqual(resp.getStatusCode(), 200);
    }
}