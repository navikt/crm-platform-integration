@isTest
private class SMSReceiverServiceTest {    
    @testSetup
    static void setup() {
    }

    @isTest
    static void testMethod1() {
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

        List<SMS__c> smsList = [SELECT Id, Message__c FROM SMS__c];
        System.debug('Inkommende SMS' + smsList.size());
        System.assertEquals(1, smsList.size(), 'Could not create SMS');
        for(SMS__c record : smsList) {
            System.debug('Melding :' + record.Message__c);
        }
   }
}