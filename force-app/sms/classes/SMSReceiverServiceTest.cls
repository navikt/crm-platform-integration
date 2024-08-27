@isTest
private class SMSReceiverServiceTest {
    @testSetup
    static void setup() {
        Account acc = new Account();
        acc.FirstName = 'Test';
        acc.LastName = 'User';
        insert acc;
        Person__c person = new Person__c();
        person.Name = '20099341781';
        person.CRM_Account__c = acc.Id;
        person.INT_KrrMobilePhone__c = 'TEST';
        insert person;
    }

    @isTest
    static void testReceiveSMS() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/receiveSMS/';
        String textMessage =
            '{' +
            '"destination": "NO-2414",' +
            '"subNumber": 9999999989,' +
            '"source": "TEST",' +
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
            ' "platformPartnerId": "20216",' +
            ' "platformServiceType": "Subnumber messages",' +
            ' "platformServiceId": "0",' +
            ' "customParameters": {},' +
            ' "number": "+4741716090",' +
            ' "startRange": "9999999980",' +
            ' "stopRange": "9999999989"' +
            '},' +
            '"gateCustomParameters": {},' +
            '"customParameters": {' +
            '  "platformPartnerId": "20216",' +
            '  "suggestedOperator": "no.telenor",' +
            '  "moReferenceId": "0",' +
            '  "queued": "2015-11-18 12:41:23",' +
            '  "serviceCentreTimeStamp": "20151118124123",' +
            '  "platformId": "0"' +
            '} }';
        req.requestBody = Blob.valueof(textMessage);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        SMSReceiverService.receiveSMS();
        Test.stopTest();

        List<SMS__c> smsList = [SELECT Id, Account__c, Message__c, Recipient__c, Domain__c, Sender__c FROM SMS__c];
        List<String> sourceList = new List<String>{'%TEST2', '%TEST', '%TEST3'};
        List<Person__c> personList = [
            SELECT Id, INT_KrrMobilePhone__c, CRM_Account__c
            FROM Person__c
            WHERE INT_KrrMobilePhone__c LIKE :sourceList
        ];
        System.assertEquals(1, personList.size(), 'Could not create person');
        System.assertEquals(1, smsList.size(), 'Could not create SMS');
        System.assertEquals(personList[0].CRM_Account__c, smsList[0].Account__c, 'Could not set Account on SMS');

        for (SMS__c record : smsList) {
            System.assertEquals('TEST', record.Sender__c, 'Could not set Sender__c');
            System.assertEquals('Hello, Dolly!', record.Message__c, 'Could not set Message__c');
            System.assertEquals('+4741716090', record.Recipient__c, 'Could not set Recipient__c');
            System.assertEquals('HOT', record.Domain__c, 'Could not set Domain__c');
        }
    }
}
