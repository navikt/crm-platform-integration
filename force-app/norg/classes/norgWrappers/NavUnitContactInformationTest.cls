@IsTest
private with sharing class NavUnitContactInformationTest {
    @IsTest
    static void NavUnitContactInformation() {
        NavUnitContactInformation contactInformation = new NavUnitContactInformation();
        contactInformation.besoeksadresse = new NavUnitContactInformation.Adresse();
        contactInformation.besoeksadresse.gatenavn = 'TESTVEIEN TEST';
        contactInformation.besoeksadresse.husnummer = '12';
        contactInformation.besoeksadresse.husbokstav = 'B';
        contactInformation.besoeksadresse.poststed = 'Test';
        contactInformation.besoeksadresse.postnummer = '0001';
        contactInformation.besoeksadresse.type = 'stedsadresse';
        contactInformation.postadresse = new NavUnitContactInformation.Adresse();
        contactInformation.postadresse.postboksanlegg = 'Test anlegg';
        contactInformation.postadresse.postboksnummer = '1234';
        contactInformation.postadresse.postnummer = '0001';
        contactInformation.postadresse.poststed = 'Test';
        contactInformation.postadresse.type = 'postboksadresse';

        Test.startTest();
        system.assertEquals('TESTVEIEN TEST 12 B, 0001 Test', contactInformation.besoeksadresse.concatenatedAddress);
        system.assertEquals('Postboks 1234 Test anlegg, 0001 Test', contactInformation.postadresse.concatenatedAddress);
        Test.stopTest();
    }
}
