@IsTest
private with sharing class PDL_AddressHelperTest {
    @Istest
    static void isSameAddressYES() {
        PDL_Vegadresse a = new PDL_Vegadresse();
        a.matrikkelId = 12345L;
        a.bruksenhetsnummer = 'ABCdef';
        PDL_Vegadresse b = new PDL_Vegadresse();
        b.matrikkelId = 12345L;
        b.bruksenhetsnummer = 'ABCdef';

        Test.startTest();
        System.assert(PDL_AddressHelper.isSameAddress(a, b), 'Expected the addresses to match');
        Test.stopTest();
    }

    static void isSameAddressNO() {
        PDL_Vegadresse a = new PDL_Vegadresse();
        a.matrikkelId = 12345L;
        a.bruksenhetsnummer = 'ABCdef';
        PDL_Vegadresse b = new PDL_Vegadresse();
        b.matrikkelId = 12345L;
        b.bruksenhetsnummer = 'dfsdlksjl';

        Test.startTest();
        System.assert(PDL_AddressHelper.isSameAddress(a, b), 'Expected the addresses to match');
        Test.stopTest();
    }
}
