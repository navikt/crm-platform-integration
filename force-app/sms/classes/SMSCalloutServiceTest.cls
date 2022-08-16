@isTest
private class SMSCalloutServiceTest {
    @isTest
    static void testSendSMS_SUCCESS() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = '00000000');
        SMS_Config__mdt smsConfig = [
            SELECT Domain__c, PlatformId__c, PlatformPartnerId__c, Source__c
            FROM SMS_Config__mdt
            WHERE Domain__c = 'TEST'
        ];

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT, smsConfig);
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode(), 'Error code was not 200');
    }

    @isTest
    static void testSendSMS_FAIL() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = '00000000');
        SMS_Config__mdt smsConfig = [
            SELECT Domain__c, PlatformId__c, PlatformPartnerId__c, Source__c
            FROM SMS_Config__mdt
            WHERE Domain__c = 'TEST'
        ];

        ApiMock.setTestMock('SEND_SMS', 400, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT, smsConfig);
        Test.stopTest();

        System.assertEquals(400, resp != null ? resp.getStatusCode() : 400, 'Error code was not 400');
    }

    @isTest
    static void testCheckRecipient_length() {
        SMS__c sms = new SMS__c(Recipient__c = '0');
        String msg = 'A';
        SMS_Config__mdt smsConfig = [
            SELECT Domain__c, PlatformId__c, PlatformPartnerId__c, Source__c
            FROM SMS_Config__mdt
            WHERE Domain__c = 'TEST'
        ];

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT, smsConfig);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
    }

    @isTest
    static void testCheckRecipient_numeric() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = 'AAAAAAAA');
        SMS_Config__mdt smsConfig = [
            SELECT Domain__c, PlatformId__c, PlatformPartnerId__c, Source__c
            FROM SMS_Config__mdt
            WHERE Domain__c = 'TEST'
        ];

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT, smsConfig);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
    }

    @isTest
    static void testRecipientWithAlphanumerical() {
        Test.startTest();
        String result = SMSCalloutService.checkRecipient('tlf +4712345678');
        Test.stopTest();
        System.assertEquals('+4712345678', result, 'Recipient invalid');
    }

    @isTest
    static void testRecipientIncorrectCountryCode() {
        Test.startTest();
        String result = SMSCalloutService.checkRecipient('04712345678');
        Test.stopTest();
        System.assertEquals('+4712345678', result, 'Recipient invalid');
    }

    @isTest
    static void testRecipientIncorrectCountryCode2() {
        Test.startTest();
        String result = SMSCalloutService.checkRecipient('004712345678');
        Test.stopTest();
        System.assertEquals('+4712345678', result, 'Recipient invalid');
    }

    @isTest
    static void testCheckRecipientIncorrectCountryCode3() {
        Test.startTest();
        String result = SMSCalloutService.checkRecipient('4712345678');
        Test.stopTest();
        System.assertEquals('+4712345678', result, 'Recipient invalid');
    }

    @isTest
    static void testRecipientNoCountryCode() {
        Test.startTest();
        String result = SMSCalloutService.checkRecipient('12345678');
        Test.stopTest();
        System.assertEquals('+4712345678', result, 'Recipient invalid');
    }
}
