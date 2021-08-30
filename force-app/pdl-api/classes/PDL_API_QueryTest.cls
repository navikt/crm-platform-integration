@isTest
private class PDL_API_QueryTest {
    @isTest
    private static void NavnTest() {
        String expected =
        '{"variables":{"ident":"1234567890"},"query":"query($ident: ID! ){ hentPerson(ident : $ident ){ navn(historikk : false ){ fornavn mellomnavn etternavn}}}"}';
        String actual = PDL_API_Query.Navn('1234567890');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
    @isTest
    private static void AnsvarssubjektTest(){
        String expected =
        '{"variables":{"ident":"1234567890"},"query":"query($ident: ID! ){ hentPerson(ident : $ident ){ foreldreansvar(historikk : false ){ ansvarssubjekt}}}"}';
        String actual = PDL_API_Query.Ansvarssubjekt('1234567890');
        System.debug(actual);
        System.assertEquals(expected, actual);
    }
}
