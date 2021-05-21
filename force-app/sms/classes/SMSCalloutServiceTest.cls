@isTest
private class SMSCalloutServiceTest {
    @isTest
    static void testSendSMS_SUCCESS() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = '00000000');

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT);
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode(), 'Error code was not 200');
    }

    @isTest
    static void testSendSMS_FAIL() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = '00000000');

        ApiMock.setTestMock('SEND_SMS', 400, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT);
        Test.stopTest();

        System.assertEquals(400, resp != null ? resp.getStatusCode() : 400, 'Error code was not 400');
    }

    @isTest
    static void testCheckRecipient_length() {
        SMS__c sms = new SMS__c(Recipient__c = '0');
        String msg = 'A';

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
    }
    @isTest
    static void testCheckRecipient_numeric() {
        SMS__c sms = new SMS__c(Message__c = 'Test', Recipient__c = 'AAAAAAAA');

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS(sms, CRM_ApplicationDomain.Domain.HOT);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
    }
}
