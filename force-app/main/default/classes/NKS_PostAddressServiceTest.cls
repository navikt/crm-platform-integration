@isTest
public with sharing class NKS_PostAddressServiceTest {
    @isTest
    public static void getPostAddressTest() {
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 200, 'OK');
        NKS_PostAddressService.NKS_PostAddressResponse response = NKS_PostAddressService.getPostAddress('ident');
        System.assertEquals('200', response.status);
        System.assertEquals('Norge', response.adresse.land);
    }

    @isTest
    public static void getPostAddressTestFailed() {
        ApiMock.setTestMock('POST_REGOPPSLAG_API', 500, 'ERROR');
        NKS_PostAddressService.NKS_PostAddressResponse response = NKS_PostAddressService.getPostAddress('ident');
        System.assertEquals('500', response.status);
    }
}
