@isTest
private with sharing class NorgKodeverkUtilsTest {
    @TestSetup
    static void makeData(){
        List<Common_Code__c> ccs = new List<Common_Code__c>();
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Postnummer', CRM_Code__c = '0001'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Postnummer', CRM_Code__c = '0002'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Postnummer', CRM_Code__c = '0003'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Postnummer', CRM_Code__c = '0004'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Postnummer', CRM_Code__c = '0005'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Tema', CRM_Code__c = '0001'));
        ccs.add(new Common_Code__c(CRM_Active__c = true, Name = 'OSLO', CRM_Code_Set__c = 'Tema', CRM_Code__c = '0002'));
        insert ccs;
    }
    @isTest
    private static void pushPostcodesToCommonCodesTest() {
        List<NorgKodeverk> incommingData = new List<NorgKodeverk>();
        incommingData.add(new NorgKodeverk('0001','OSLO'));
        incommingData.add(new NorgKodeverk('0002','OSLO'));
        incommingData.add(new NorgKodeverk('0003','OSLO'));
        incommingData.add(new NorgKodeverk('0004','OSLO'));
        incommingData.add(new NorgKodeverk('0005','OSLO'));
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(incommingData), null)
        );
        
        Test.startTest();
        Integer i = NorgKodeverkUtils.pushPostcodesToCommonCodes();
        Test.stopTest();

        System.assertEquals(0,i);

    }
    @isTest
    private static void pushPostcodesUpdateTest() {
        List<NorgKodeverk> incommingData = new List<NorgKodeverk>();
        incommingData.add(new NorgKodeverk('0001','TRONDHEIM'));
        incommingData.add(new NorgKodeverk('0002','OSLO'));
        incommingData.add(new NorgKodeverk('0003','BERGEN'));
        incommingData.add(new NorgKodeverk('0004','OSLO'));
        incommingData.add(new NorgKodeverk('0005','STAVANGER'));
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(incommingData), null)
        );
        
        Test.startTest();
        Integer i = NorgKodeverkUtils.pushPostcodesToCommonCodes();
        Test.stopTest();

        System.assertEquals(3,i);

    }
    @isTest
    private static void pushPostcodesDeleteTest() {
        List<NorgKodeverk> incommingData = new List<NorgKodeverk>();
        incommingData.add(new NorgKodeverk('0002','OSLO'));
        incommingData.add(new NorgKodeverk('0003','OSLO'));
        incommingData.add(new NorgKodeverk('0004','OSLO'));
        incommingData.add(new NorgKodeverk('0005','OSLO'));
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(incommingData), null)
        );
        Test.startTest();
        Integer i = NorgKodeverkUtils.pushPostcodesToCommonCodes();
        Test.stopTest();
        System.assertEquals(1,i);
    }
    @isTest
    private static void pushPostcodesInsertTest() {
        List<NorgKodeverk> incommingData = new List<NorgKodeverk>();
        incommingData.add(new NorgKodeverk('0001','OSLO'));
        incommingData.add(new NorgKodeverk('0002','OSLO'));
        incommingData.add(new NorgKodeverk('0003','OSLO'));
        incommingData.add(new NorgKodeverk('0004','OSLO'));
        incommingData.add(new NorgKodeverk('0005','OSLO'));
        incommingData.add(new NorgKodeverk('0006','OSLO'));
        incommingData.add(new NorgKodeverk('0007','OSLO'));
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(incommingData), null)
        );
        
        Test.startTest();
        Integer i = NorgKodeverkUtils.pushPostcodesToCommonCodes();
        Test.stopTest();

        System.assertEquals(2,i);

    }
    @isTest
    private static void pushPostcodesInsertDeleteUpdateTest() {
        List<NorgKodeverk> incommingData = new List<NorgKodeverk>();
        incommingData.add(new NorgKodeverk('0002','OSLO'));
        incommingData.add(new NorgKodeverk('0003','STAVANGER'));
        incommingData.add(new NorgKodeverk('0004','OSLO'));
        incommingData.add(new NorgKodeverk('0005','BERGEN'));
        incommingData.add(new NorgKodeverk('0006','OSLO'));
        incommingData.add(new NorgKodeverk('0007','TRONDHEIM'));
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(incommingData), null)
        );
        
        Test.startTest();
        Integer i = NorgKodeverkUtils.pushPostcodesToCommonCodes();
        Test.stopTest();

        System.assertEquals(5,i);

    }
    @isTest
    private static void pushPostcodesConnectionExceptionTest() {
        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(401, 'Fail', '', null)
        );
        
        Test.startTest();
        try{
            NorgKodeverkUtils.pushPostcodesToCommonCodes();
        }catch(NorgKodeverkUtils.NorgKodeverkException e){
            return;
        }
        Test.stopTest();

        System.assert(false,'No expected exceptions.');

    }
}
