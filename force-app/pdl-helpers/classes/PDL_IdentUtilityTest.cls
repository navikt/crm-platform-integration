@IsTest
private with sharing class PDL_IdentUtilityTest {
    @IsTest
    static void testGetValues() {
        Test.startTest();
        System.assertEquals(
            '1234567890123',
            PDL_IdentUtility.getAktorId(getIdentList()),
            'Expected to get the AKTORID'
        );
        System.assertEquals('12345678911', PDL_IdentUtility.getNpid(getIdentList()), 'Expected to get the NPID');
        System.assertEquals('12345678901', PDL_IdentUtility.getFnr(getIdentList()), 'Expected to get the FNR');
        System.assertEquals('52345678901', PDL_IdentUtility.getDnr(getIdentList()), 'Expected to get the DNR');
        Test.stopTest();
    }

    @IsTest
    static void testGetActiveDnr() {
        PDL_IdentInformasjon dnr = new PDL_IdentInformasjon();
        dnr.gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        dnr.historisk = false;
        dnr.ident = '52345678901';

        PDL_IdentInformasjon npid = new PDL_IdentInformasjon();
        npid.gruppe = PDL_IdentGruppe.NPID;
        npid.historisk = false;
        npid.ident = '12345678911';

        Test.startTest();
        System.assertEquals(
            '52345678901',
            PDL_IdentUtility.getDnr(new List<PDL_IdentInformasjon>{ dnr, npid }),
            'Expected to get the DNR'
        );
        System.assertEquals(
            '52345678901',
            PDL_IdentUtility.getDnr(getIdentList()),
            'Expected to get the DNR 52345678901'
        );
        Test.stopTest();
    }

    @IsTest
    static void getIdentsFromListTest() {
        PDL_IdentUtility.PersonIdent result;

        Test.startTest();
        result = PDL_IdentUtility.getIdentsFromList(getIdentList());
        Test.stopTest();

        System.assertEquals('1234567890123', result.actorId, 'Expected to have the actorId set correctly');
        System.assertEquals('12345678911', result.npid, 'Expected to have the npid set correctly');
        System.assertEquals('12345678901', result.fnr, 'Expected to have the fnr set correctly');
        System.assertEquals('52345678901', result.dnr, 'Expected to have the dnr set correctly');
    }

    private static List<PDL_IdentInformasjon> getIdentList() {
        List<PDL_IdentInformasjon> identList = new List<PDL_IdentInformasjon>();
        identList.add(new PDL_IdentInformasjon());
        identList[0].gruppe = PDL_IdentGruppe.AKTORID;
        identList[0].historisk = false;
        identList[0].ident = '1234567890123';

        identList.add(new PDL_IdentInformasjon());
        identList[1].gruppe = PDL_IdentGruppe.NPID;
        identList[1].historisk = false;
        identList[1].ident = '12345678911';

        identList.add(new PDL_IdentInformasjon());
        identList[2].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identList[2].historisk = false;
        identList[2].ident = '12345678901';

        identList.add(new PDL_IdentInformasjon());
        identList[3].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        identList[3].historisk = true;
        identList[3].ident = '52345678901';

        return identList;
    }
    @isTest
    static void getIdfromPDLResponseTest(){
        String dataString = '{"data":{"hentPerson":{"fo' +
        'lkeregisteridentifikator":[{"identifikasjonsnummer":"12106519356",' +
        '"status":"I_BRUK","type":"FNR","folkeregistermetadata":{"ajourhold' +
        'stidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09-0' +
        '2T10:17:35","opphoerstidspunkt":null,"kilde":"srvdolly","aarsak":n' +
        'ull,"sekvens":null},"metadata":{"opplysningsId":"33be3e25-ccd5-4f9' +
        '7-8f21-bbac3c444877","master":"FREG","endringer":[{"type":"OPPRETT"' +
        ',"registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret' +
        '","systemkilde":"FREG","kilde":"srvdolly"}],"historisk":false}}]}' +
        ',"hentIdenter":{"identer":[{"ident":"12106519356","historisk":false,"' +
        'gruppe":"FOLKEREGISTERIDENT"},{"ident":"2762473496911","historisk":f' +
        'alse,"gruppe":"AKTORID"}]}' +
        '}}';
        HttpResponse hr = new HttpResponse();
        hr.setBody(dataString);
        hr.setStatusCode(200);
        PDL_API_Response person = PDL_API_Response.fromHttpResponse(hr);

        Test.startTest();
        String resultActorId = PDL_IdentUtility.getAktorId(person);
        String resultDNR = PDL_IdentUtility.getDNR(person);
        String resultFNR = PDL_IdentUtility.getFNR(person);
        String resultNPID = PDL_IdentUtility.getNPID(person);
        Test.stopTest();

        System.assertEquals('2762473496911',resultActorId,'Expected to get the AKTORID');
        System.assertEquals(null,resultDNR,'Expected to get the D-nummer');
        System.assertEquals('12106519356',resultFNR,'Expected to get the fødselsnummer');
        System.assertEquals(null,resultNPID,'Expected to get the NPID');

    }
}
