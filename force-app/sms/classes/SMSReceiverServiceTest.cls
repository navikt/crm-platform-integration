@isTest
private class SMSReceiverServiceTest {    
    @testSetup
    static void setup() {
        Account acc = new Account();
        Person__c person = new Person__c();
        person.Name ='20099341781';
        person.CRM_Account__c = acc.Id;
        person.INT_KrrMobilePhone__c = '41767124';
        acc.FirstName = 'Edvard';
        acc.LastName = 'Brekke';
        insert acc;
        insert person;
    }

    @isTest
    static void testReceiveSMS() {
         RestRequest req = new RestRequest(); 
         RestResponse res = new RestResponse();

         req.addHeader('httpMethod', 'POST');
         req.requestUri = '/services/apexrest/receiveSMS/';       
         String textMessage = '{' +
            '"destination": "NO-2414",' +
            '"subNumber": 9999999989,' +
            '"source": "+4741767124",' +
            '"content": {' +
             ' "type": "SMS",' +
             ' "userData": "Hello, Dolly!",' +
             ' "encoding": "TEXT"' +
           ' },' +
           ' "operator": "no.telenor",' +
           ' "timestamp": "2015-11-18T11:41:23Z",' +
           '"messageId": "0",' +
           '"operatorTimestamp": "2015-11-18T11:41:23Z",' +
           '"operatorMessageId": "0",' +
           '"route": {' +
           '  "type": "SUBNUMBER_ROUTE",' +
           '  "id": "0",' +
           '  "refId": "SubnumberRange Definition",' +
           '  "gateIds": [' +
            '"0" ],' +
            ' "platformId": "0",' +
            ' "platformPartnerId": "0",' +
            ' "platformServiceType": "Subnumber messages",' +
            ' "platformServiceId": "0",' +
            ' "customParameters": {},' +
            ' "number": "NO-2333",' +
            ' "startRange": "9999999980",' +
            ' "stopRange": "9999999989"' +
            '},' +
            '"gateCustomParameters": {},' +
            '"customParameters": {' +
            '  "platformPartnerId": "0",' +
            '  "suggestedOperator": "no.telenor",' +
            '  "moReferenceId": "0",' +
            '  "queued": "2015-11-18 12:41:23",' +
            '  "serviceCentreTimeStamp": "20151118124123",' +
            '  "platformId": "0"' +
            '} }';
         req.requestBody = Blob.valueof(textMessage);
         RestContext.request = req; 
         RestContext.response= res;
         Test.startTest();
         SMSReceiverService.receiveSMS();
         Test.stopTest();

         List<SMS__c> smsList = [SELECT Id, Account__c, Message__c, Sender__c FROM SMS__c];
         List<Person__c> personList = [SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c FROM Person__c WHERE INT_KrrMobilePhone__c LIKE '%41767124'];
         System.assertEquals(1, personList.size(), 'Could not create person');
         System.assertEquals(1, smsList.size(), 'Could not create SMS');
         System.assertEquals(smsList[0].Account__c, personList[0].CRM_Account__c , 'Could not set Account on SMS');

         for(SMS__c record : smsList) {
             System.assertEquals('+4741767124', record.Sender__c,'Could not set Sender__c');
             System.assertEquals('Hello, Dolly!', record.Message__c,'Could not set Message__c');
         }
   }
}