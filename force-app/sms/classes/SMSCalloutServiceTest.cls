@isTest
private class SMSCalloutServiceTest{

	@testSetup static void setup(){

		
	}

	@isTest static void testMethod1() {
		Map<String,String> messages = new Map<String,String>();
        messages.put('00000000', 'Test');
        SMSCalloutService.sendSMS(messages);

        //HOW DO WE TEST THIS??
	}

}