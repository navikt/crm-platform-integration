
@IsTest(isParallel=true)
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs') //No need for runAs in this test class
public class KrrCalloutServiceTest {

    @IsTest private static void getPersonsNullInput() {
        System.Test.startTest();
        List<KrrCalloutService.Person> response = KrrCalloutService.doPersonOppslag2(null,null);
        System.Test.stopTest();
        System.Assert.isNotNull(response, 'Response should be null for null input');
        System.Assert.isTrue(response.isEmpty(), 'Response should be empty for null input');
    }

    @IsTest private static void testGetPersons() {
        String json = '{"personer": {"25498944097": {"personident": "25498944097","aktiv": true,"kanVarsles": false,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2025-05-06T11:15:37.514155Z","epostadresse": "   test@test.no"}}, "feil": {}}';

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            json,
            null
        );
        Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        List<KrrCalloutService.Person> response = KrrCalloutService.doPersonOppslag2(new List<String>{ '25498944097' },'');
        System.Test.stopTest();

        System.Assert.isNotNull(response, 'Response should not be null.');
        System.Assert.areEqual(1, response.size(), 'Response should contain one person.');
        System.Assert.isTrue(response[0].personident == '25498944097', 'The person identifier should match.');
    }

    @IsTest
    private static void getCalloutExceptionOnRun() {
        CalloutExceptionRequestMock mock = new CalloutExceptionRequestMock('Something went wrong');
        Exception ex;
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        KrrCalloutService service = new KrrCalloutService();

        try {
            service.getPersons(new List<String>{ '1234456' });
        } catch (CalloutException e) {
            ex = e;
        }
        Test.stopTest();
        // Verify that the exception was thrown
        System.Assert.isInstanceOfType(ex, CalloutException.class, 'Expected CalloutException to be thrown');

        List<Application_Log__c> allApplicationLogs = [SELECT Id, Log_Message__c, Log_Level__c, Application_Domain__c, Category__c FROM Application_Log__c];
        List<Application_Log__c> applicationLogs = [SELECT Id, Log_Message__c, Log_Level__c, Application_Domain__c, Category__c FROM Application_Log__c WHERE Application_Domain__c = :CRM_ApplicationDomain.Domain.PLATFORCE.name() AND Category__c = 'KRR'];
        System.Assert.isFalse(allApplicationLogs?.isEmpty(), 'Expected application logs to be created');
        System.Assert.isFalse(applicationLogs?.isEmpty(), 'Expected application logs to be created');
        System.Assert.areEqual(allApplicationLogs.size(), applicationLogs.size(), 'Expected that only KRR logs are created');
        System.Assert.areEqual(1, applicationLogs.size(), 'Expected only one application log to be created');
        System.Assert.isTrue(applicationLogs[0].Log_Message__c.contains('Something went wrong'), 'Expected log message to contain "Something went wrong"');
        System.Assert.areEqual('Critical',applicationLogs[0].Log_Level__c, 'Expected log message to be critical');
    }

    @IsTest
    private static void testParsing() {
        String json = '{"personer": {"25498944097": {"personident": "25498944097","aktiv": true,"kanVarsles": false,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2025-05-06T11:15:37.514155Z","epostadresse": "test@test.no","epostadresseOppdatert": "2025-05-06T11:15:37.514151Z","epostadresseVerifisert": "2025-05-06T11:15:37.514153Z","mobiltelefonnummer": "+4712345678","mobiltelefonnummerOppdatert": "2025-05-06T11:15:37.514136Z","mobiltelefonnummerVerifisert": "2025-05-06T11:15:37.51414Z"}},"feil": {"254989440973": "person_ikke_funnet"}}';

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            json,
            null
        );
        Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        KrrCalloutService.KrrResponse response = new KrrCalloutService().getPersons(new List<String>{ '25498944097', '254989440973' });
        System.Test.stopTest();

        System.Assert.isNotNull(response, 'Response should not be null.');
        System.Assert.areEqual(1, response.personer.size(), 'Response should contain one person.');
        System.Assert.areEqual(1, response.feil.size(), 'Response should contain one error.');

        System.Assert.isTrue(response.personer.containsKey('25498944097'), 'The person identifier should match.');
        System.Assert.isNotNull(response.personer.get('25498944097'), 'Person response for person identifier 25498944097 should not be null.');
        System.Assert.isFalse(response.feil.containsKey('25498944097'), 'Should not have an entry in feil for person identifier 25498944097.');

        System.Assert.isFalse(response.personer.containsKey('254989440973'), 'The person identifier 254989440973 should not exist in the personer map.');
        System.Assert.areEqual(response.feil.get('254989440973'), 'person_ikke_funnet', 'Error message for person identifier 254989440973 should be "person_ikke_funnet".');
    }

    @IsTest
    private static void testPerson() {
        String json = '{"personer": {"25498944097": {"personident": "25498944097","aktiv": true,"kanVarsles": false,"reservasjonOppdatert": "2025-05-06T11:15:37.514112Z","reservert": true,"spraak": "nb","spraakOppdatert": "2025-05-06T11:15:37.514155Z","epostadresse": "test@test.no","epostadresseOppdatert": "2025-05-06T11:15:37.514151Z","epostadresseVerifisert": "2025-05-06T11:15:37.514153Z","mobiltelefonnummer": "+4712345678","mobiltelefonnummerOppdatert": "2025-05-06T11:15:37.514136Z","mobiltelefonnummerVerifisert": "2025-05-06T11:15:37.51414Z", "sikkerDigitalPostkasse": {"adresse": "asd.no","leverandoerAdresse": "984661185","leverandoerSertifikat": "MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY..."}}},"feil": {}}';

        SingleRequestMock mock = new SingleRequestMock(
            200,
            'OK',
            json,
            null
        );
        Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        KrrCalloutService.KrrResponse response = new KrrCalloutService().setIncludeSecureDigitalPost(true).getPersons(new List<String>{ '25498944097', '254989440973' },true);
        System.Test.stopTest();

        System.Assert.isNotNull(response, 'Response should not be null.');
        System.Assert.areEqual(1, response.personer.size(), 'Response should contain one person.');
        System.Assert.areEqual(0, response.feil.size(), 'Response should contain no errors.');

        System.Assert.isTrue(response.personer.containsKey('25498944097'), 'The person identifier should match.');
        System.Assert.isNotNull(response.personer.get('25498944097'), 'Person response for person identifier 25498944097 should not be null.');
        System.Assert.isFalse(response.feil.containsKey('25498944097'), 'Should not have an entry in feil for person identifier 25498944097.');

        KrrCalloutService.Person person = response.personer.get('25498944097');

        System.Assert.areEqual('25498944097', person.personident, 'Personident should match.');
        System.Assert.isTrue(person.aktiv, 'Person should be active.');
        System.Assert.isFalse(person.kanVarsles, 'Person should not be able to be notified.');
        System.Assert.areEqual(DateTime.valueOfGmt('2025-05-06 11:15:37.514112Z'), person.reservasjonOppdatert, 'Reservation updated should match.');
        System.Assert.isTrue(person.reservert, 'Person should be reserved.');
        System.Assert.areEqual('nb', person.spraak, 'Language should be Norwegian.');
        System.Assert.isNotNull(person.spraakOppdatert, 'Language updated should not be null.');
        System.Assert.areEqual('test@test.no', person.epostadresse, 'Email address should match.');
        System.Assert.areEqual(DateTime.valueOfGmt('2025-05-06 11:15:37.514151Z'), person.epostadresseOppdatert, 'Email address updated should match.');
        System.Assert.areEqual(DateTime.valueOfGmt('2025-05-06 11:15:37.514153Z'), person.epostadresseVerifisert, 'Email address verified should match.');
        System.Assert.areEqual('+4712345678', person.mobiltelefonnummer, 'Mobile phone number should match.');
        System.Assert.areEqual(DateTime.valueOfGmt('2025-05-06 11:15:37.514136Z'), person.mobiltelefonnummerOppdatert, 'Mobile phone number updated should match.');
        System.Assert.areEqual(DateTime.valueOfGmt('2025-05-06 11:15:37.51414Z'), person.mobiltelefonnummerVerifisert, 'Mobile phone number verified should match.');
        System.Assert.isNotNull(person.sikkerDigitalPostkasse, 'Digital postkasse should not be null.');
        System.Assert.areEqual('asd.no', person.sikkerDigitalPostkasse.adresse, 'Secure digital mailbox address should match.');
        System.Assert.areEqual('984661185', person.sikkerDigitalPostkasse.leverandoeradresse, 'Secure digital mailbox provider address should match.');
        System.Assert.areEqual('MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY...', person.sikkerDigitalPostkasse.leverandoerSertifikat, 'Secure digital mailbox provider certificate should match.');
    }

    @IsTest private static void nullInput() {
        Exception ex;
        System.Test.startTest();
        try {
            new KrrCalloutService().getPersons(null);
        } catch (Exception e) {
            ex = e;
        }
        System.Test.stopTest();
        System.Assert.isInstanceOfType(ex, IllegalArgumentException.class, 'Expected IllegalArgumentException to be thrown');
        List<Application_Log__c> applicationLogs = [SELECT Id, Log_Message__c, Log_Level__c, Application_Domain__c, Category__c FROM Application_Log__c];
        System.Assert.isTrue(applicationLogs.isEmpty(), 'Expected no application logs to be created');
    }

    @IsTest private static void emptyListInput() {
        Exception ex;
        System.Test.startTest();
        try {
            new KrrCalloutService().getPersons(new List<String>());
        } catch (Exception e) {
            ex = e;
        }
        System.Test.stopTest();
        System.Assert.isInstanceOfType(ex, IllegalArgumentException.class, 'Expected IllegalArgumentException to be thrown');
        List<Application_Log__c> applicationLogs = [SELECT Id, Log_Message__c, Log_Level__c, Application_Domain__c, Category__c FROM Application_Log__c];
        System.Assert.isTrue(applicationLogs.isEmpty(), 'Expected no application logs to be created');
    }

    @IsTest private static void internalServerErrorResponse() {
        SingleRequestMock mock = new SingleRequestMock(
            500,
            'Internal Server Error',
            '',
            null
        );
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        KrrCalloutService.KrrResponse response = new KrrCalloutService().getPersons(new List<String>{ '1234456' });
        System.Test.stopTest();

        List<Application_Log__c> applicationLogs = [SELECT Id, Log_Message__c, Log_Level__c, Application_Domain__c, Category__c FROM Application_Log__c];

        System.Assert.areEqual(1, applicationLogs?.size(), 'Expected only one application log to be created');
        System.Assert.areEqual('Error', applicationLogs?.get(0)?.Log_Level__c, 'Expected application to be error');
        System.Assert.areEqual('PLATFORCE', applicationLogs?.get(0)?.Application_Domain__c, 'Expected application domain to be KRR');
        System.Assert.areEqual('KRR', applicationLogs?.get(0)?.Category__c, 'Expected category to be KRR');
        System.Assert.isNull(response, 'Response should be null.');
    }
}
