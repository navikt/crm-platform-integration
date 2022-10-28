@IsTest
public class KrrCalloutServiceTest {

    @isTest
    public static void testEndpoint(){
        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '{\"personer\":{\"additionalProp1\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}},\"additionalProp2\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}},\"additionalProp3\":{\"personident\":\"string\",\"aktiv\":true,\"kanVarsles\":true,\"reservert\":true,\"spraak\":\"string\",\"spraakOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresse\":\"string\",\"epostadresseOppdatert\":\"2022-10-17T10:12:25.864Z\",\"epostadresseVerifisert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummer\":\"string\",\"mobiltelefonnummerOppdatert\":\"2022-10-17T10:12:25.864Z\",\"mobiltelefonnummerVerifisert\":\"2022-10-17T10:12:25.864Z\",\"sikkerDigitalPostkasse\":{\"adresse\":\"string\",\"leverandoerAdresse\":\"string\",\"leverandoerSertifikat\":\"string\"}}},\"feil\":{\"additionalProp1\":\"string\",\"additionalProp2\":\"string\",\"additionalProp3\":\"string\"}}', null));

        Test.startTest();
        List<KrrCalloutService.Person> ls = KrrCalloutService.doPersonOppslag(new List<String>{'1234456'}, null);
        Test.stopTest();

        System.debug(ls);
    }
}