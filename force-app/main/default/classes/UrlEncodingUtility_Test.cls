@IsTest
private with sharing class UrlEncodingUtility_Test {
    
    @IsTest 
    private static void test_encodeUrl_withSpecialCharacters(){
        String fileName='test med æøå & ÆØÅ + spesialtegn!';

        Test.startTest();
        String encodedUrl=UrlEncodingUtility.encodeUrl(fileName);
        Test.stopTest();
        
        String expected='test%20med%20%C3%A6%C3%B8%C3%A5%20%26%20%C3%86%C3%98%C3%85%20%2B%20spesialtegn%21';
        System.assertEquals(expected,encodedUrl,'Url should be encoded');
    }

    @IsTest 
    private static void test_encodeUrl_withNoSpecialCharacters(){
        String fileName='testFil.xlsx';

        Test.startTest();
        String encodedUrl=UrlEncodingUtility.encodeUrl(fileName);
        Test.stopTest();
        
        System.assertEquals(fileName,encodedUrl,'Same url should be returned');
    }
}
