@isTest
private class SMSCalloutServiceTest{
	@isTest static void testSendSMS_SUCCESS() {

        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS('00000000', 'Test', CRM_ApplicationDomain.Domain.HOT);
        Test.stopTest();

        System.assertEquals(200, resp.getStatusCode(), 'Error code was not 200');
	}

	@isTest static void testSendSMS_FAIL() {

        ApiMock.setTestMock('SEND_SMS', 400, 'OK');
        Test.startTest();
        HttpResponse resp = SMSCalloutService.sendSMS('00000000', 'Test', CRM_ApplicationDomain.Domain.HOT);
        Test.stopTest();

        System.assertEquals(400, resp != null ? resp.getStatusCode() : 400, 'Error code was not 400');
	}

    
	@isTest static void testCheckRecipient_length() {
        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS('0', 'Test', CRM_ApplicationDomain.Domain.HOT);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
	}
	@isTest static void testCheckRecipient_numeric() {
        ApiMock.setTestMock('SEND_SMS', 200, 'OK');
        Test.startTest();
        Boolean IsCaughtExeption = false;
        try {
            HttpResponse resp = SMSCalloutService.sendSMS('AAAAAAAA', 'Test', CRM_ApplicationDomain.Domain.HOT);
        } catch (Exception exept) {
            IsCaughtExeption = true;
        }
        Test.stopTest();
        System.assertEquals(true, IsCaughtExeption, 'Could not catch exeption.');
	}

}