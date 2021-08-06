@IsTest
private with sharing class NorgNavUnitsTest {
    @isTest
    static void getNavUnit() {
        NavUnit unit = new NavUnit();
        unit.enhetNr = '1234';
        unit.navn = 'Test Enhet1';
        unit.underEtableringDato = Date.newInstance(1970, 1, 1);

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new List<NavUnit>{ unit }), null)
        );

        NavUnit result;

        Test.startTest();
        result = NorgNavUnits.getNavUnit('123456');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did not expect null');
        System.assertEquals('1234', result.enhetNr, 'Expected to get the same enhetNr as in the mock');
    }

    @isTest
    static void getNavUnitBlankUnitNumber() {
        Boolean hasNavUnitException = false;

        Test.startTest();
        try {
            NorgNavUnits.getNavUnit('');
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getNavUnitErrorResponse() {
        Boolean hasNavUnitException = false;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Bad Request', '', null));

        Test.startTest();
        try {
            NorgNavUnits.getNavUnit('12345');
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getNavUnitContactInformation() {
        NavUnitContactInformation unit = new NavUnitContactInformation();
        unit.enhetNr = '12345';
        unit.epost = new NavUnitContactInformation.Epost();
        unit.epost.adresse = 'test@test.no';
        // unit.postadresse = new NavUnitContactInformation.Adresse('TESTVEIEN TEST', '12', 'B', 'TEST', '0001');
        unit.publikumsmottak = new List<NavUnitContactInformation.Publikumsmottak>();
        unit.publikumsmottak.add(new NavUnitContactInformation.Publikumsmottak());
        unit.publikumsmottak[0].id = 123456;
        // unit.publikumsmottak[0].besoeksadresse = new NavUnitContactInformation.Adresse(
        //     'TESTVEIEN TEST',
        //     '12',
        //     'B',
        //     'TEST',
        //     '0001'
        // );
        unit.publikumsmottak[0].aapningstider = new List<NavUnitContactInformation.Aapningstider>();
        // unit.publikumsmottak[0]
        //     .aapningstider.add(
        //         new NavUnitContactInformation.Aapningstider(
        //             123456,
        //             Date.newInstance(2020, 12, 20),
        //             '10:00',
        //             '12:00',
        //             'Test utføres'
        //         )
        //     );
        // unit.publikumsmottak[0]
        //     .aapningstider.add(new NavUnitContactInformation.Aapningstider(1234567, 'MANDAG', '08:00', '16:00', ''));
        unit.publikumsmottak.add(new NavUnitContactInformation.Publikumsmottak());
        unit.publikumsmottak[1].id = 1234567;
        unit.publikumsmottak[1].stedsbeskrivelse = 'Test mottaket';
        // unit.publikumsmottak[1].besoeksadresse = new NavUnitContactInformation.Adresse(
        //     'SFVEIEN',
        //     '1',
        //     null,
        //     'SF',
        //     '2323'
        // );
        // unit.publikumsmottak[1].aapningstider = new List<NavUnitContactInformation.Aapningstider>();
        // unit.publikumsmottak[1]
        //     .aapningstider.add(
        //         new NavUnitContactInformation.Aapningstider(
        //             123456,
        //             Date.newInstance(2020, 12, 20),
        //             '10:00',
        //             '12:00',
        //             'Test utføres'
        //         )
        //     );
        // unit.publikumsmottak[1]
        //     .aapningstider.add(new NavUnitContactInformation.Aapningstider(1234567, 'MANDAG', '08:00', '16:00', ''));

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', JSON.serialize(unit), null));

        NavUnitContactInformation result;

        Test.startTest();
        result = NorgNavUnits.getNavUnitContactInformation('12345');
        Test.stopTest();

        System.assertEquals(unit.enhetNr, result.enhetNr, 'Expected to get the same enhetNr as in the mock');
    }

    @isTest
    static void getNavUnitContactInformationBlankUnitNumber() {
        Boolean hasNavUnitException = false;
        Test.startTest();
        try {
            NorgNavUnits.getNavUnitContactInformation('');
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getNavUnitContactInformationErrorResponse() {
        Boolean hasNavUnitException = false;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Bad Request', '', null));

        Test.startTest();
        try {
            NorgNavUnits.getNavUnitContactInformation('12345');
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getPersonNavUnit() {
        Person__c p = new Person__c(
            Name = '1234567890',
            INT_LastName__c = 'Potter',
            INT_IsNavEmployee__c = false,
            INT_Confidential__c = 'UGRADERT',
            INT_MunicipalityNumber__c = '1234'
        );

        NavUnit unit = new NavUnit();
        unit.enhetNr = '1234';
        unit.navn = 'Test Enhet1';
        unit.underEtableringDato = Date.newInstance(1970, 1, 1);

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', JSON.serialize(unit), null));

        NavUnit result;

        Test.startTest();
        result = NorgNavUnits.getPersonNavUnit(p);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did not expect null');
        System.assertEquals('1234', result.enhetNr, 'Expected to get the same enhetNr as in the mock');
    }

    @isTest
    static void getPersonNavUnitNoLocation() {
        Person__c p = new Person__c(
            Name = '1234567890',
            INT_LastName__c = 'Potter',
            INT_IsNavEmployee__c = false,
            INT_Confidential__c = 'UGRADERT'
        );

        Boolean hasNavUnitException = false;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Bad Request', '', null));

        Test.startTest();
        try {
            NorgNavUnits.getPersonNavUnit(p);
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getPersonNavUnitErrorResponse() {
        Person__c p = new Person__c(
            Name = '1234567890',
            INT_LastName__c = 'Potter',
            INT_IsNavEmployee__c = false,
            INT_Confidential__c = 'UGRADERT',
            INT_MunicipalityNumber__c = '1234'
        );

        Boolean hasNavUnitException = false;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Bad Request', '', null));

        Test.startTest();
        try {
            NorgNavUnits.getPersonNavUnit(p);
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }

    @isTest
    static void getPersonNavUnitWithContactInformation() {
        Person__c p = new Person__c(
            Name = '1234567890',
            INT_LastName__c = 'Potter',
            INT_IsNavEmployee__c = false,
            INT_Confidential__c = 'UGRADERT',
            INT_MunicipalityNumber__c = '1234'
        );

        NavUnit unit = new NavUnit();
        unit.enhetNr = '1234';
        unit.navn = 'Test Enhet1';
        unit.underEtableringDato = Date.newInstance(1970, 1, 1);

        NavUnitContactInformation unitContactInformation = new NavUnitContactInformation();
        unitContactInformation.enhetNr = '12345';
        unitContactInformation.epost = new NavUnitContactInformation.Epost();
        unitContactInformation.epost.adresse = 'test@test.no';
        // unitContactInformation.postadresse = new NavUnitContactInformation.Adresse(
        //     'TESTVEIEN TEST',
        //     '12',
        //     'B',
        //     'TEST',
        //     '0001'
        // );

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'Success', JSON.serialize(unit), null));

        NavUnitWithContactInformation result;

        Test.startTest();
        result = NorgNavUnits.getPersonNavUnitWithContactInformation(p);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Did not expect null');
        System.assertEquals('1234', result.enhet.enhetNr, 'Expected to get the same enhetNr as in the mock');
    }

    // @isTest
    // static void getNavUnitWithContactInformation() {
    //     NavUnit unit = new NavUnit();
    //     unit.enhetNr = '1234';
    //     unit.navn = 'Test Enhet1';
    //     unit.underEtableringDato = Date.newInstance(1970, 1, 1);

    //     NavUnitContactInformation unitContactInformation = new NavUnitContactInformation();
    //     unitContactInformation.enhetNr = '12345';
    //     unitContactInformation.epost = new NavUnitContactInformation.Epost();
    //     unitContactInformation.epost.adresse = 'test@test.no';
    //     unitContactInformation.postadresse = new NavUnitContactInformation.Adresse(
    //         'TESTVEIEN TEST',
    //         '12',
    //         'B',
    //         'TEST',
    //         '0001'
    //     );

    //     Test.setMock(
    //         HttpCalloutMock.class,
    //         new SingleRequestMock(200, 'Success', JSON.serialize(new List<NavUnit>{ unit }), null)
    //     );

    //     NavUnitWithContactInformation result;

    //     Test.startTest();
    //     result = NorgNavUnits.getNavUnitWithContactInformation('1234');
    //     Test.stopTest();

    //     System.assertNotEquals(null, result, 'Did not expect null');
    //     System.assertEquals('1234', result.enhet.enhetNr, 'Expected to get the same enhetNr as in the mock');
    // }

    @isTest
    static void exceptionCoverage() {
        Test.startTest();
        new NorgNavUnits.NavUnitException();
        Test.stopTest();
    }

    @isTest
    static void getWorkAllocation() {
        Person__c p = new Person__c(
            Name = '1234567890',
            INT_LastName__c = 'Potter',
            INT_IsNavEmployee__c = false,
            INT_Confidential__c = 'UGRADERT',
            INT_MunicipalityNumber__c = '1234'
        );

        NavUnitWorkAllocation unit1 = new NavUnitWorkAllocation();
        unit1.navn = '12345';
        unit1.enhetNr = 'Test Enhet1';

        NavUnitWorkAllocation unit2 = new NavUnitWorkAllocation();
        unit2.navn = '54321';
        unit2.enhetNr = 'Test Enhet2';

        Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'Success', JSON.serialize(new List<NavUnitWorkAllocation>{ unit1, unit2 }), null)
        );

        List<NavUnitWorkAllocation> result;

        Test.startTest();
        result = NorgNavUnits.getWorkAllocation(p, 'themeGroupCode', 'themeCode', 'themeSubThemeCode', 'taskType');
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Expected to get both the units in the mock');
    }

    @isTest
    static void getWorkAllocationErrorResponse() {
        Boolean hasNavUnitException = false;

        Test.setMock(HttpCalloutMock.class, new SingleRequestMock(400, 'Bad Request', '', null));

        Test.startTest();
        try {
            NorgNavUnits.getWorkAllocation(null, 'themeGroupCode', 'themeCode', 'themeSubThemeCode', 'taskType');
        } catch (NorgNavUnits.NavUnitException e) {
            hasNavUnitException = true;
        } catch (Exception e) {
            System.assert(false, 'Did not throw correct exception');
        }
        Test.stopTest();

        System.assert(hasNavUnitException, 'Did not catch correct exception');
        System.assertEquals(1, [SELECT Id FROM Application_Log__c].size(), 'Excpected error to be recorded');
    }
}
