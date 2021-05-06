@isTest
private class SMSCalloutServiceTest{

	@testSetup static void setup(){

		
	}

	@isTest static void testMethod1() {
        SMSCalloutService.sendSMS('00000000', 'Test', CRM_ApplicationDomain.Domain.HOT);

        //HOW DO WE TEST THIS??
        //Mock-greier.
	}

}