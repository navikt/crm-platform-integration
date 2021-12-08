@IsTest
private with sharing class WebSakFileServiceTest{
   
    @IsTest
    private static void postFile() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        WebSakFileService.WebSakFileResponse resp = new WebSakFileService().postFile('file1.txt', Blob.valueOf('test'));
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
    }

    @IsTest
    private static void postFile_whenError() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 500, 'Unable to post file');

        Test.startTest();
        WebSakFileService.WebSakFileResponse resp = new WebSakFileService().postFile('file1.txt', Blob.valueOf('test'));
        Test.stopTest();

        System.assertEquals(false, resp.success, 'Expect error');
        System.assert(resp.errorMessage.contains('Publisering av fil til WebSak feilet'), 'Expect error message');
    }

    @IsTest
    private static void postFile_withFtpsCatalogue() {
        ApiMock.setTestMock('POST_FILE_TO_WEBSAK', 200, 'OK');

        Test.startTest();
        WebSakFileService.WebSakFileResponse resp = new WebSakFileService().postFile('file1.txt', Blob.valueOf('test'), 'ftpmottakSFAAreg');
        Test.stopTest();

        System.assertEquals(true, resp.success, 'Expect success');
        System.assertEquals(null, resp.errorMessage, 'Expect no error message');
    }
}
