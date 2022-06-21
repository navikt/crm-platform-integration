@IsTest
private with sharing class KafkaPDLHandler2Test {
    @TestSetup
    static void makeData() {
        // record for setting correct Country from Country ISO code
        List<Common_Code__c> commonCodes = new List<Common_Code__c>();

        Common_Code__c ccIND = new Common_Code__c();
        ccIND.Name = 'India';
        ccIND.CRM_Code_Set__c = 'Landkoder';
        ccIND.CRM_Code__c = 'IND';
        ccIND.CRM_Active__c = true;
        commonCodes.add(ccIND);

        Common_Code__c ccNOR = new Common_Code__c();
        ccNOR.Name = 'Norge';
        ccNOR.CRM_Code_Set__c = 'Landkoder';
        ccNOR.CRM_Code__c = 'NOR';
        ccNOR.CRM_Active__c = true;
        commonCodes.add(ccNOR);

        insert commonCodes;
    }

    /*********************
     * TESTS FOR ISO MAP *
     *********************/

    @IsTest
    static void createIsoMapTest() {
        Test.startTest();
        System.assertEquals(
            2,
            KafkaPDLHandler2.createIsoMap(
                    [
                        SELECT Name, CRM_Code__c
                        FROM Common_Code__c
                        WHERE CRM_Active__c = TRUE AND CRM_Code_Set__c IN ('Landkoder', 'LandkoderISO2')
                    ]
                )
                .size(),
            'Expected two values'
        );
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnNull() {
        Test.startTest();
        System.assertEquals(null, KafkaPDLHandler2.getCountryFromIso(null), 'Expected null in return');
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnCommonCode() {
        Test.startTest();
        System.assertNotEquals(null, KafkaPDLHandler2.getCountryFromIso('NOR'), 'Expected null in return');
        Test.stopTest();
    }

    @IsTest
    static void getCountryFromIsoReturnException() {
        Test.startTest();
        try {
            KafkaPDLHandler2.getCountryFromIso('NON-EXISTING');
            System.assertEquals(true, false, 'Expected an exception to be thrown');
        } catch (KafkaPDLHandler2.IsoCodeNotFoundException e) {
            System.assertEquals(true, true, 'Expected to catch IsoCodeNotFoundException');
        } catch (Exception e) {
            System.assertEquals(true, false, 'Expected to catch IsoCodeNotFoundException not Exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void getCountryNameFromIso() {
        Test.startTest();
        System.assertEquals('Norge', KafkaPDLHandler2.getCountryNameFromIso('NOR'), 'Expected Norge in return');
        Test.stopTest();
    }

    @IsTest
    static void getCountrySfIdFromIso() {
        Test.startTest();
        System.assertNotEquals(null, KafkaPDLHandler2.getCountryIdFromIso('NOR'), 'Did not expected null in return');
        Test.stopTest();
    }

    @IsTest
    static void crateCitizenshipStringTest() {
        Test.startTest();
        System.assertEquals(
            'Norge;India',
            KafkaPDLHandler2.crateCitizenshipString(new List<String>{ 'NOR', 'IND' }),
            'Expected list with Norge and India'
        );
        Test.stopTest();
    }

    /*******************************************
     * TESTS FOR idents *
     *******************************************/
    @isTest
    static void setNameTest(){
        KafkaPerson2 kPerson = createBaseKafkaPerson('1234567890123');

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[0].ident = '12345678901';
        kPerson.identer[0].historisk = false;
        kPerson.identer[0].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[1].ident = '12345678911';
        kPerson.identer[1].historisk = false;
        kPerson.identer[1].gruppe = PDL_IdentGruppe.NPID;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[2].ident = '52345678901';
        kPerson.identer[2].historisk = false;
        kPerson.identer[2].gruppe = PDL_IdentGruppe.AKTORID;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[3].ident = '12345678902';
        kPerson.identer[3].historisk = true;
        kPerson.identer[3].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        Person__c person = new Person__c();

        KafkaPDLHandler2.setName(kPerson, person);

        System.assertEquals('12345678901', person.Name, 'Expected non historisk FOLKEREGISTERIDENT');

        person = new Person__c();
        kPerson.identer[0].historisk = true;
        KafkaPDLHandler2.setName(kPerson, person);

        System.assertEquals('12345678911', person.Name , 'Expected non historisk NPID');
    }

    @IsTest
    static void setNameException() {
        KafkaPerson2 kPerson = createBaseKafkaPerson('1234567890123');

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[0].ident = '12345678901';
        kPerson.identer[0].historisk = true;
        kPerson.identer[0].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[1].ident = '12345678911';
        kPerson.identer[1].historisk = true;
        kPerson.identer[1].gruppe = PDL_IdentGruppe.NPID;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[2].ident = '52345678901';
        kPerson.identer[2].historisk = false;
        kPerson.identer[2].gruppe = PDL_IdentGruppe.AKTORID;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[3].ident = '12345678902';
        kPerson.identer[3].historisk = true;
        kPerson.identer[3].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        Person__c person = new Person__c();

        Test.startTest();
        try {
            KafkaPDLHandler2.setName(kPerson, person);
            System.assert(false, 'No exception thrown');
        } catch (KafkaPDLHandler2.PdlIdentException ex) {
            System.assert(true);
        } catch (Exception e) {
            System.assert(false, 'Did not catch the correct exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void setIdentsTest() {
        KafkaPerson2 kPerson = createBaseKafkaPerson('1234567890123');

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[0].ident = '12345678901';
        kPerson.identer[0].historisk = false;
        kPerson.identer[0].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[1].ident = '12345678911';
        kPerson.identer[1].historisk = false;
        kPerson.identer[1].gruppe = PDL_IdentGruppe.NPID;

        kPerson.identer.add(new PDL_IdentInformasjon());
        kPerson.identer[2].ident = '52345678901';
        kPerson.identer[2].historisk = true;
        kPerson.identer[2].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;

        kPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kPerson.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kPerson.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kPerson.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kPerson.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kPerson.folkeregisteridentifikator[0].metadata.historisk = false;

        kPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kPerson.folkeregisteridentifikator[1].identifikasjonsnummer = '52345678901';
        kPerson.folkeregisteridentifikator[1].status = PDL_IdentStatus.OPPHOERT;
        kPerson.folkeregisteridentifikator[1].type = PDL_IdentType.DNR;
        kPerson.folkeregisteridentifikator[1].metadata = new PDL_Metadata();
        kPerson.folkeregisteridentifikator[1].metadata.historisk = true;

        Person__c person = new Person__c();

        Test.startTest();
        KafkaPDLHandler2.setIdents(kPerson, person);
        Test.stopTest();

        System.assertEquals(null, person.INT_ACTORID__c, 'Expected AKTORID to be null');
        System.assertEquals('12345678901', person.INT_FNR__c, 'Expected FNR to be set');
        System.assertEquals('12345678911', person.INT_NPID__c, 'Expect NPID to be set');
        System.assertEquals('52345678901', person.INT_DNR__c, 'Expect DNR to be set');
    }

    /*******************************************
     * TESTS FOR checkLastUpdatedAndTombStones *
     *******************************************/

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the CreatedDate is older than the Person LastModifiedDate
    // KafkaMessage__c.CRM_Status__c should be set to error
    @IsTest
    static void checkLastUpdatedAndTombStonesOlderMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_WARNING,
            msg.CRM_Status__c,
            'Expected the status to be set to error'
        );
    }

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the persons INT_LastUpdatedFromPDL__c is empty
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessagesNoLastUpdated() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = null;
        insert person1;

        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // A Person exists in Salesforce and we try to process a KafkaMessage__c where the CreatedDate is after than the Person INT_LastUpdatedFromPDL__c
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesNewMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // We try to process a KafkaMessage__c where we don't have any matching person in Salesforce
    // KafkaMessage__c.CRM_Status__c should not be updated
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessages() {
        String createdDate = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        KafkaMessage__c msg = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate +
            '"}',
            KafkaMessage__c.class
        );
        msg.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg.CRM_Status__c,
            'Expected the status to be the same'
        );
    }

    //SCENARIO:
    // We try to process several KafkaMessage__c where they all have the same key and matches a Person in Salesforce
    // KafkaMessage__c.CRM_Status__c should be set to processec on only the oldest
    @IsTest
    static void checkLastUpdatedAndTombStonesNewDuplicateMessages() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate1 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(3).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate3 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate4 = Datetime.now().addDays(-2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 +
            '"}',
            KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg2.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        KafkaMessage__c msg3 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate3 +
            '"}',
            KafkaMessage__c.class
        );
        msg3.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg3.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg3.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        KafkaMessage__c msg4 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate4 +
            '"}',
            KafkaMessage__c.class
        );
        msg4.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg4.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg4.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2, msg3, msg4 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg1.CRM_Status__c,
            'Expected the status to be processed'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg2.CRM_Status__c,
            'Expected the status to be the same'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg3.CRM_Status__c,
            'Expected the status to be processed'
        );
        System.assertEquals(KafkaMessageService.STATUS_WARNING, msg4.CRM_Status__c, 'Expected the status to be error');
    }

    //SCENARIO:
    // We try to process two several KafkaMessage__c where they all have the same actorId that matches a Person in Salesforce, but one is a tombstone
    // Both KafkaMessage__c should be processed
    @IsTest
    static void checkLastUpdatedAndTombStonesDuplicateMessagesWithTombstone() {
        Person__c person1 = new Person__c();
        person1.INT_ActorId__c = '1000012345678';
        person1.Name = '20000000000';
        person1.INT_fnr__c = '20000000000';
        person1.INT_LastUpdatedFromPDL__c = Datetime.now();
        insert person1;

        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        String createdDate2 = Datetime.now().addDays(2).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":false}'));

        // The newest
        KafkaMessage__c msg2 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate2 +
            '"}',
            KafkaMessage__c.class
        );
        msg2.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg2.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg2.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1, msg2 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_WARNING,
            msg1.CRM_Status__c,
            'Expected the status to be warning'
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PENDING,
            msg2.CRM_Status__c,
            'Expected the status to be pending'
        );
    }

    //SCENARIO:
    // We try process a KafkaMessage__c where we dont have a match a Person in Salesforce, but one is a tombstone
    // KafkaMessage__c.CRM_Status__c should be set to processed
    @IsTest
    static void checkLastUpdatedAndTombStonesBrandNewMessagesWithTombstone() {
        String createdDate1 = Datetime.now().addDays(1).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        KafkaMessage__c msg1 = (KafkaMessage__c) JSON.deserializeStrict(
            '{"attributes":{"type":"KafkaMessage__c"}, "CreatedDate":"' +
            createdDate1 +
            '"}',
            KafkaMessage__c.class
        );
        msg1.CRM_Status__c = KafkaMessageService.STATUS_PENDING;
        msg1.CRM_Topic__c = 'teamnks.nks-sf-pdl-v3';
        msg1.CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}'));

        Test.startTest();
        new KafkaPDLHandler2().checkLastUpdatedAndTombStones(new List<KafkaMessage__c>{ msg1 });
        Test.stopTest();

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            msg1.CRM_Status__c,
            'Expected the status to be processed'
        );
    }

    //SCENARIO:
    // We try process a KafkaMessage__c where we have a match a Person in Salesforce, the message is a tombstone and the value is null
    // Person should get a tombstone
    @IsTest
    static void processTombstoneTest() {
        insert new Person__c(
            Name = '12345678901',
            INT_fnr__c = '12345678901',
            INT_ActorId__c = '1000012345678',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );

        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'teamnks.nks-sf-pdl-v3',
                CRM_Key__c = EncodingUtil.base64Encode(Blob.valueOf('{"aktoer_id":"1000012345678","tombstone":true}')),
                CRM_Value__c = null
            )
        );

        // Verify that we have only one Account
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert kafkaMessages;
        System.debug([SELECT Id, CRM_Topic__c, CRM_Key__c, CRM_ErrorMessage__c FROM KafkaMessage__c]);
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();
        System.debug([SELECT Id, CRM_Topic__c, CRM_Key__c, CRM_ErrorMessage__c FROM KafkaMessage__c]);

        // Assert that 1 Person Accounts have been inserted
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);

        // Assert that all Kafka Message records have been marked as processed
        System.assertEquals(
            1,
            [SELECT COUNT() FROM KafkaMessage__c WHERE CRM_Status__c = :KafkaMessageService.STATUS_PROCESSED]
        );

        Person__c p = [SELECT Id, INT_ActorId__c, INT_fnr__c, Name, INT_IsHasTombstone__c, INT_FirstName__c, INT_LastName__c FROM Person__c LIMIT 1];

        // Assert that only tombstone and id fields has values
        System.assertEquals('1000012345678', p.INT_ActorId__c,'ActorId');
        System.assertEquals('12345678901', p.INT_fnr__c, 'fnr');
        System.assertEquals('12345678901', p.Name, 'Name');
        System.assertEquals(true, p.INT_IsHasTombstone__c, 'Tombstone');
        System.assertEquals(null, p.INT_FirstName__c,'Firstname');
        System.assertEquals(null, p.INT_LastName__c,'Lastname');
    }

    /********************************
     * TESTS FOR message processing *
     ********************************/

    @isTest
    static void insertKafkaMessageOldVersion() {
        KafkaPerson2 kafkaPerson = createBaseKafkaPersonOld('11223344556');
        kafkaPerson.folkeregisterId.add('12345678901');

        KafkaMessage__c message = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        // Verify that we don't have any Person__c records
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );

        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);
        Person__c person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];

        System.assertEquals(null, person.INT_fnr__c, 'Did not expect this value to be set');
        System.assertEquals(null, person.INT_npid__c, 'Did not expect this value to be set');
        System.assertEquals(null, person.INT_dnr__c, 'Did not expect this value to be set');
        System.assertEquals('12345678901', person.Name, 'Expected NAME to be set');
        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
    }

    @isTest
    static void insertKafkaMessageDefault() {
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson.identer[1].historisk = false;
        kafkaPerson.identer[1].ident = '12345678901';
        kafkaPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaMessage__c message = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        // Verify that we don't have any Person__c records
        System.assertEquals(0, [SELECT COUNT() FROM Person__c]);

        // Act
        Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );

        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);
        Person__c person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];

        System.assertEquals('12345678901', person.INT_fnr__c, 'Expect FNR to be set');
        System.assertEquals(null, person.INT_npid__c, 'Did not expect this value to be set');
        System.assertEquals(null, person.INT_dnr__c, 'Did not expect this value to be set');
        System.assertEquals('12345678901', person.Name, 'Expected NAME to be set');
        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
    }

    @isTest
    static void insertKafkaMessageProcessed() {
        KafkaPerson2 kafkaPerson1 = createBaseKafkaPerson('11223344556');
        kafkaPerson1.identer.add(new PDL_IdentInformasjon());
        kafkaPerson1.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson1.identer[1].historisk = false;
        kafkaPerson1.identer[1].ident = '12345678901';
        kafkaPerson1.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson1.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson1.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson1.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson1.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson1.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaPerson2 kafkaPerson2 = createBaseKafkaPerson('11223344556');
        kafkaPerson2.identer.add(new PDL_IdentInformasjon());
        kafkaPerson2.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson2.identer[1].historisk = false;
        kafkaPerson2.identer[1].ident = '12345678901';
        kafkaPerson2.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson2.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson2.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson2.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson2.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson2.folkeregisteridentifikator[0].metadata.historisk = false;
        kafkaPerson2.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>();
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());

        KafkaPerson2 kafkaPerson3 = createBaseKafkaPerson('11223344556');
        kafkaPerson3.identer.add(new PDL_IdentInformasjon());
        kafkaPerson3.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson3.identer[1].historisk = false;
        kafkaPerson3.identer[1].ident = '12345678901';
        kafkaPerson3.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson3.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson3.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson3.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson3.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson3.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaMessage__c message1 = createKafkaMessageHelper(createBaseKafkaPerson('11223344557'), '11223344557', true);
        KafkaMessage__c message2 = createKafkaMessageHelper(kafkaPerson1, '11223344556', false);
        KafkaMessage__c message3 = createKafkaMessageHelper(kafkaPerson2, '11223344556', false);
        KafkaMessage__c message4 = createKafkaMessageHelper(kafkaPerson3, '11223344556', true);

        // Act
        Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3, message4 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];
        message4 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message4.Id];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_WARNING,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_WARNING,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message4.CRM_Status__c,
            '' + message4.CRM_ErrorMessage__c
        );
        System.assertEquals(0, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
    }

    @isTest
    static void insertKafkaMessageWarning() {
        KafkaPerson2 kafkaPerson1 = createBaseKafkaPerson('11223344556');
        kafkaPerson1.identer.add(new PDL_IdentInformasjon());
        kafkaPerson1.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson1.identer[1].historisk = false;
        kafkaPerson1.identer[1].ident = '12345678901';
        kafkaPerson1.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson1.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson1.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson1.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson1.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson1.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaPerson2 kafkaPerson2 = createBaseKafkaPerson('11223344556');
        kafkaPerson2.identer.add(new PDL_IdentInformasjon());
        kafkaPerson2.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson2.identer[1].historisk = false;
        kafkaPerson2.identer[1].ident = '12345678901';
        kafkaPerson2.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson2.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson2.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson2.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson2.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson2.folkeregisteridentifikator[0].metadata.historisk = false;
        kafkaPerson2.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>();
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());

        KafkaMessage__c message1 = createKafkaMessageHelper(createBaseKafkaPerson('11223344557'), '11223344557', true);
        KafkaMessage__c message2 = createKafkaMessageHelper(kafkaPerson1, '11223344556', false);
        KafkaMessage__c message3 = createKafkaMessageHelper(kafkaPerson2, '11223344556', false);

        // Act
        Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_WARNING,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        System.assertEquals(0, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
    }

    @isTest
    static void insertKafkaMessageUpdateError() {
        insert new Person__c(
            Name = '12345678901',
            INT_fnr__c = '12345678901',
            INT_ActorId__c = '11223344556',
            INT_FirstName__c = 'FNAME',
            INT_LastName__c = 'LNAME'
        );

        KafkaPerson2 kafkaPerson1 = createBaseKafkaPerson('11223344556');
        kafkaPerson1.identer.add(new PDL_IdentInformasjon());
        kafkaPerson1.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson1.identer[1].historisk = false;
        kafkaPerson1.identer[1].ident = '12345678901';
        kafkaPerson1.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson1.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson1.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson1.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson1.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson1.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaPerson2 kafkaPerson2 = createBaseKafkaPerson('11223344556');
        kafkaPerson2.identer.add(new PDL_IdentInformasjon());
        kafkaPerson2.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson2.identer[1].historisk = false;
        kafkaPerson2.identer[1].ident = '12345678901';
        kafkaPerson2.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson2.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson2.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson2.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson2.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson2.folkeregisteridentifikator[0].metadata.historisk = false;
        kafkaPerson2.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>();
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson2.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());

        KafkaPerson2 kafkaPerson3 = createBaseKafkaPerson('11223344559');
        kafkaPerson3.identer.add(new PDL_IdentInformasjon());
        kafkaPerson3.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson3.identer[1].historisk = false;
        kafkaPerson3.identer[1].ident = '12345678902';
        kafkaPerson3.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson3.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson3.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson3.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678902';
        kafkaPerson3.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson3.folkeregisteridentifikator[0].metadata.historisk = false;

        KafkaMessage__c message1 = createKafkaMessageHelper(createBaseKafkaPerson('11223344551'), '11223344551', true);
        KafkaMessage__c message2 = createKafkaMessageHelper(kafkaPerson1, '11223344556', false);
        KafkaMessage__c message3 = createKafkaMessageHelper(createBaseKafkaPerson('11223344553'), '11223344553', true);
        KafkaMessage__c message4 = createKafkaMessageHelper(kafkaPerson2, '11223344556', false);
        KafkaMessage__c message5 = createKafkaMessageHelper(createBaseKafkaPerson('11223344552'), '11223344552', true);
        KafkaMessage__c message6 = createKafkaMessageHelper(kafkaPerson3, '11223344559', false);

        // Act
        Test.startTest();
        insert new List<KafkaMessage__c>{ message1, message2, message3, message4, message5, message6 };
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        message1 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id];
        message2 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id];
        message3 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id];
        message4 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message4.Id];
        message5 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message5.Id];
        message6 = [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message6.Id];

        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message1.CRM_Status__c,
            '' + message1.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message2.CRM_Status__c,
            '' + message2.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message3.CRM_Status__c,
            '' + message3.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_ERROR,
            message4.CRM_Status__c,
            '' + message4.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message5.CRM_Status__c,
            '' + message5.CRM_ErrorMessage__c
        );
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message6.CRM_Status__c,
            '' + message6.CRM_ErrorMessage__c
        );
        System.assertEquals(1, [SELECT COUNT() FROM Person__c WHERE Name = '12345678901']);
        System.assertEquals(1, [SELECT COUNT() FROM Person__c WHERE Name = '12345678902']);
    }

    @isTest
    static void insertKafkaMessageNpidPerson() {
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');

        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[1].gruppe = PDL_IdentGruppe.NPID;
        kafkaPerson.identer[1].historisk = false;
        kafkaPerson.identer[1].ident = '12345678901';

        kafkaPerson.folkeregisterpersonstatus.clear();

        KafkaMessage__c message = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        // Act
        Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );

        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);

        Person__c person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];

        System.assertEquals(null, person.INT_fnr__c, 'Did not expect this value to be set');
        System.assertEquals('12345678901', person.INT_npid__c, 'Expect this value to be set');
        System.assertEquals(null, person.INT_dnr__c, 'Did not expect this value to be set');
        System.assertEquals('12345678901', person.Name, 'Expected NAME to be set');
        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
    }

    @isTest
    static void insertKafkaMessageNpidPersonFromNpidToFnr() {
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');

        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[1].gruppe = PDL_IdentGruppe.NPID;
        kafkaPerson.identer[1].historisk = false;
        kafkaPerson.identer[1].ident = '12345678901';

        kafkaPerson.folkeregisterpersonstatus.clear();

        KafkaMessage__c message1 = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[2].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson.identer[2].historisk = false;
        kafkaPerson.identer[2].ident = '52345678901';

        kafkaPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson.folkeregisteridentifikator[0].identifikasjonsnummer = '52345678901';
        kafkaPerson.folkeregisteridentifikator[0].type = PDL_IdentType.DNR;
        kafkaPerson.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson.folkeregisteridentifikator[0].metadata.historisk = false;

        kafkaPerson.folkeregisterpersonstatus.add('bosatt');

        KafkaMessage__c message2 = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        kafkaPerson.identer[2].historisk = true;

        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[3].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson.identer[3].historisk = false;
        kafkaPerson.identer[3].ident = '11345678901';

        kafkaPerson.folkeregisteridentifikator[0].status = PDL_IdentStatus.OPPHOERT;
        kafkaPerson.folkeregisteridentifikator[0].metadata.historisk = true;

        kafkaPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson.folkeregisteridentifikator[1].identifikasjonsnummer = '11345678901';
        kafkaPerson.folkeregisteridentifikator[1].type = PDL_IdentType.FNR;
        kafkaPerson.folkeregisteridentifikator[1].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson.folkeregisteridentifikator[1].metadata = new PDL_Metadata();
        kafkaPerson.folkeregisteridentifikator[1].metadata.historisk = false;

        KafkaMessage__c message3 = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        KafkaMessageService msgService;
        Person__c person;

        // Act
        Test.startTest();

        //Message 1
        insert message1;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message1 });
        msgService.handleMessages();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message1.Id LIMIT 1]
        );
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];
        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        System.assertEquals(null, person.INT_fnr__c, 'Did not expect FNR to be set');
        System.assertEquals('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        System.assertEquals(null, person.INT_dnr__c, 'Did not expect DNR to be set');
        System.assertEquals('12345678901', person.Name, 'Expected NAME to be same as NPID');

        //Message 2
        insert message2;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message2 });
        msgService.handleMessages();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message2.Id LIMIT 1]
        );
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];
        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        System.assertEquals(null, person.INT_fnr__c, 'Did not expect FNR to be set');
        System.assertEquals('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        System.assertEquals('52345678901', person.INT_dnr__c, 'Expected DNR to be set');
        System.assertEquals('52345678901', person.Name, 'Expected NAME to be same as DNR');

        //Message 3
        insert message3;
        msgService = new KafkaMessageService(new List<KafkaMessage__c>{ message3 });
        msgService.handleMessages();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message3.Id LIMIT 1]
        );
        System.assertEquals(1, [SELECT COUNT() FROM Person__c]);
        person = [
            SELECT FIELDS(STANDARD), INT_ActorId__c, INT_fnr__c, INT_dnr__c, INT_npid__c
            FROM Person__c
            WHERE INT_actorId__c = '11223344556'
        ];

        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        System.assertEquals('11345678901', person.INT_fnr__c, 'Expected FNR to be set');
        System.assertEquals('12345678901', person.INT_npid__c, 'Expected NPID to be set');
        System.assertEquals('52345678901', person.INT_dnr__c, 'Expect DNR to be set');
        System.assertEquals('11345678901', person.Name, 'Expected NAME to be same as FNR');

        Test.stopTest();
    }

    /***************************
     * VERIFY THE DATA MAPPING *
     **************************/

    @isTest
    static void mapFieldValuesExcludingAddresses() {
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[1].gruppe = PDL_IdentGruppe.FOLKEREGISTERIDENT;
        kafkaPerson.identer[1].historisk = false;
        kafkaPerson.identer[1].ident = '12345678901';
        kafkaPerson.folkeregisteridentifikator.add(new PDL_FolkeregisterIdentifikator());
        kafkaPerson.folkeregisteridentifikator[0].identifikasjonsnummer = '12345678901';
        kafkaPerson.folkeregisteridentifikator[0].type = PDL_IdentType.FNR;
        kafkaPerson.folkeregisteridentifikator[0].status = PDL_IdentStatus.I_BRUK;
        kafkaPerson.folkeregisteridentifikator[0].metadata = new PDL_Metadata();
        kafkaPerson.folkeregisteridentifikator[0].metadata.historisk = false;

        kafkaPerson.navn[0].fornavn = 'TEST';
        kafkaPerson.navn[0].mellomnavn = 'T.';

        kafkaPerson.foedselsdato.add('2020-02-25');

        kafkaPerson.innflyttingTilNorge.add(new PDL_InnflyttingTilNorge());
        kafkaPerson.innflyttingTilNorge[0].fraflyttingsland = 'IND';
        kafkaPerson.innflyttingTilNorge[0].fraflyttingsstedIUtlandet = 'Delhi';

        kafkaPerson.sikkerhetstiltak = new List<PersonJSONFieldObjects.Sikkerhetstiltak>();
        kafkaPerson.sikkerhetstiltak.add(new PersonJSONFieldObjects.Sikkerhetstiltak());
        kafkaPerson.sikkerhetstiltak[0].beskrivelse = 'Telefonisk utestengelse';
        kafkaPerson.sikkerhetstiltak[0].tiltaksType = 'TFUS';
        kafkaPerson.sikkerhetstiltak[0].gyldigFraOgMed = '2020-12-14';
        kafkaPerson.sikkerhetstiltak[0].gyldigTilOgMed = '2020-12-20';
        kafkaPerson.sikkerhetstiltak[0].kontaktPersonId = 'Z000000';
        kafkaPerson.sikkerhetstiltak[0].kontaktPersonEnhet = '0000';

        kafkaPerson.statsborgerskap.add('NOR');

        kafkaPerson.sivilstand.add(new PDL_Sivilstand());
        kafkaPerson.sivilstand[0].type = PDL_Sivilstandstype.GIFT;
        kafkaPerson.sivilstand[0].gyldigFraOgMed = Date.newInstance(2001, 6, 20);
        kafkaPerson.sivilstand[0].relatertVedSivilstand = '12345678910';

        kafkaPerson.kjoenn.add('MANN');

        kafkaPerson.doedsfall.add(new KafkaPerson2.Doedsfall());
        kafkaPerson.doedsfall[0].doedsdato = '2019-01-29';
        kafkaPerson.doedsfall[0].master = 'FREG';

        kafkaPerson.telefonnummer.add(new KafkaPerson2.Telefonnummer());
        kafkaPerson.telefonnummer[0].landskode = '+46';
        kafkaPerson.telefonnummer[0].nummer = '123456789';
        kafkaPerson.telefonnummer[0].prioritet = '2';
        kafkaPerson.telefonnummer.add(new KafkaPerson2.Telefonnummer());
        kafkaPerson.telefonnummer[1].landskode = '+47';
        kafkaPerson.telefonnummer[1].nummer = '987654321';
        kafkaPerson.telefonnummer[1].prioritet = '1';

        kafkaPerson.utflyttingFraNorge.add(new PDL_UtflyttingFraNorge());
        kafkaPerson.utflyttingFraNorge[0].tilflyttingsland = 'IND';
        kafkaPerson.utflyttingFraNorge[0].tilflyttingsstedIUtlandet = 'Delhi';

        kafkaPerson.talesspraaktolk = new List<String>();
        kafkaPerson.talesspraaktolk.add('NO');

        kafkaPerson.fullmakt = new List<PersonJSONFieldObjects.Fullmakt>();
        kafkaPerson.fullmakt.add(new PersonJSONFieldObjects.Fullmakt());
        kafkaPerson.fullmakt[0].motpartsRolle = 'Fullmektig';
        kafkaPerson.fullmakt[0].motpartsPersonident = '12345678910';
        kafkaPerson.fullmakt[0].omraader = new List<String>{ 'DAG' };
        kafkaPerson.fullmakt[0].gyldigFraOgMed = '2020-02-14';
        kafkaPerson.fullmakt[0].gyldigTilOgMed = '2020-02-28';

        kafkaPerson.vergemaalEllerFremtidsfullmakt = new List<PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt>();
        kafkaPerson.vergemaalEllerFremtidsfullmakt.add(new PersonJSONFieldObjects.VergemaalEllerFremtidsfullmakt());
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].type = 'stadfestetFremtidsfullmakt';
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].embete = 'Statsforvalter';
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].navn = null;
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].motpartsPersonident = '12345678910';
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].omfang = 'Personlige og/eller økonomiske interesser';
        kafkaPerson.vergemaalEllerFremtidsfullmakt[0].omfangetErInnenPersonligOmraade = true;

        KafkaMessage__c message = createKafkaMessageHelper(kafkaPerson, '11223344556', false);

        Test.startTest();
        insert message;
        AsyncRequestSchedulable.enqueueAsyncJobs();
        Test.stopTest();

        isKafkaMessageProcessed(
            [SELECT Id, CRM_Status__c, CRM_ErrorMessage__c FROM KafkaMessage__c WHERE Id = :message.Id LIMIT 1]
        );

        Person__c person = getPersonAccountByActorIdent().get('11223344556');

        System.assertEquals('11223344556', person.INT_actorId__c, 'Expected AKTØR ID to be set');
        System.assertEquals('12345678901', person.INT_fnr__c, 'Expected FNR to be set');
        System.assertEquals(null, person.INT_npid__c, 'Expected NPID to be null');
        System.assertEquals(null, person.INT_dnr__c, 'Expect DNR to be null');
        System.assertEquals('12345678901', person.Name, 'Expected NAME to be same as FNR');

        System.assertEquals('2020-02-25', person.INT_DateOfBirth__c, 'Expected ');

        System.assertEquals('TEST', person.INT_FirstName__c, 'Expected ');
        System.assertEquals('T.', person.INT_MiddleName__c, 'Expected ');
        System.assertEquals('TESTESEN', person.INT_LastName__c, 'Expected ');

        System.assertEquals('Bosatt', person.INT_LegalStatus__c, 'Expected ');

        System.assertNotEquals(null, person.INT_MovedFromCountry__c, 'Expected ');
        System.assertEquals('Delhi', person.INT_MovedFromPlace__c, 'Expected ');

        System.assertEquals('UGRADERT', person.INT_Confidential__c, 'Expected ');

        System.assert(String.isNotBlank(person.INT_SecurityMeasures__c), 'Expected ');

        System.assertEquals('Norge', person.INT_Citizenships__c, 'Expected ');

        System.assertEquals('GIFT', person.INT_MaritalStatus__c, 'Expected ');
        System.assertEquals(Date.newInstance(2001, 6, 20), person.INT_MaritalStatusDate__c, 'Expected ');
        System.assertEquals('12345678910', person.INT_MaritalRelation__c, 'Expected ');

        System.assertEquals('Mann', person.INT_Sex__c, 'Expected ');

        System.assertEquals(Date.newInstance(2019, 1, 29), person.INT_DateOfDeath__c, 'Expected ');
        System.assertEquals(true, person.INT_IsDeceased__c, 'Expected ');

        System.assertEquals('+47987654321', person.INT_Phone1__c, 'Expected ');
        System.assertEquals('+46123456789', person.INT_Phone2__c, 'Expected ');

        System.assertNotEquals(null, person.INT_MovedToCountry__c, 'Expected ');
        System.assertEquals('Delhi', person.INT_MovedToPlace__c, 'Expected ');

        System.assertEquals('NO', person.INT_SpokenLanguageIntepreter__c, 'Expected ');

        System.assert(String.isNotBlank(person.INT_PowerOfAttorney__c), 'Expected ');
        System.assert(String.isNotBlank(person.INT_GuardianshipOrFuturePowerOfAttorney__c), 'Expected ');
    }

    /***********************
     * TEST ADDRESS AND GT *
     **********************/

    @IsTest
    static void setBostedVegadresse() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.bostedsadresse.vegadresse.add(new KafkaPerson2.Vegadresse());
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = 'Testveien';
        kafkaPerson.bostedsadresse.vegadresse[0].husnummer = '1';
        kafkaPerson.bostedsadresse.vegadresse[0].husbokstav = 'A';
        kafkaPerson.bostedsadresse.vegadresse[0].postnummer = '0001';
        kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer = '4321';
        kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer = '030110';
        kafkaPerson.bostedsadresse.vegadresse[0].koordinater = 'x=354424, y=6862099, z=0';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setAddress(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(
            'Testveien 1 A',
            person.INT_ResidentialAddress__c,
            'Expected residential address to be set correctly'
        );
        System.assertEquals('0001', person.INT_ResidentialZipCode__c, 'Expected residential zip code to be set');
        System.assertEquals(
            '4321',
            person.INT_AddressMunicipalityNumber__c,
            'Expected Address Municipality number to be set'
        );
        System.assertEquals(
            '030110',
            person.INT_AddressDistrictNumber__c,
            'Expected Address District number to be set'
        );
        System.assertEquals('x=354424, y=6862099, z=0', person.INT_Coordinates__c, 'Expected coordinates to be set');

        System.assertEquals(null, person.INT_TemporaryAddress__c, 'Expected INT_TemporaryAddress__c to be null');
        System.assertEquals(null, person.INT_TemporaryZipCode__c, 'Expected INT_TemporaryZipCode__c to be null');
        System.assertEquals(
            null,
            person.INT_TemporaryMunicipalityNumber__c,
            'Expected INT_TemporaryMunicipalityNumber__c to be null'
        );
        System.assertEquals(
            null,
            person.INT_TemporaryCoordinates__c,
            'Expected INT_TemporaryCoordinates__c to be null'
        );
        System.assertEquals(
            null,
            person.INT_TemporaryCountryCode__c,
            'Expected INT_TemporaryCountryCode__c to be null'
        );
    }

    @IsTest
    static void setOppholdVegadresse() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.oppholdsadresse.vegadresse.add(new KafkaPerson2.Vegadresse());
        kafkaPerson.oppholdsadresse.vegadresse[0].adressenavn = 'Testveien';
        kafkaPerson.oppholdsadresse.vegadresse[0].husnummer = '1';
        kafkaPerson.oppholdsadresse.vegadresse[0].husbokstav = 'A';
        kafkaPerson.oppholdsadresse.vegadresse[0].postnummer = '0001';
        kafkaPerson.oppholdsadresse.vegadresse[0].kommunenummer = '4321';
        kafkaPerson.oppholdsadresse.vegadresse[0].bydelsnummer = '030110';
        kafkaPerson.oppholdsadresse.vegadresse[0].koordinater = 'x=354424, y=6862099, z=0';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setAddress(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(null, person.INT_ResidentialAddress__c, 'Expected INT_ResidentialAddress__c to be null');
        System.assertEquals(null, person.INT_ResidentialZipCode__c, 'Expected INT_ResidentialZipCode__c to be null');
        System.assertEquals(
            null,
            person.INT_AddressMunicipalityNumber__c,
            'Expected INT_AddressMunicipalityNumber__c to be null'
        );
        System.assertEquals(
            null,
            person.INT_AddressDistrictNumber__c,
            'Expected INT_AddressDistrictNumber__c to be null'
        );
        System.assertEquals(null, person.INT_Coordinates__c, 'Expected INT_Coordinates__c to be null');

        System.assertEquals(
            'Testveien 1 A',
            person.INT_TemporaryAddress__c,
            'Expected residential address to be set correctly'
        );
        System.assertEquals('0001', person.INT_TemporaryZipCode__c, 'Expected residential zip code to be set');
        System.assertEquals(
            '4321',
            person.INT_TemporaryMunicipalityNumber__c,
            'Expected Address Municipality number to be set'
        );
        System.assertEquals(
            'x=354424, y=6862099, z=0',
            person.INT_TemporaryCoordinates__c,
            'Expected coordinates to be set'
        );
        System.assertEquals(
            null,
            person.INT_TemporaryCountryCode__c,
            'Expected INT_TemporaryCountryCode__c to be null'
        );
    }
    @IsTest
    static void setGTFromKommunenummer() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.kommunenummerFraGt = '0301';
        kafkaPerson.bydelsnummerFraGt = '030101';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(
            '0301',
            person.INT_GTMunicipalityNumber__c,
            'Expected INT_GTMunicipalityNumber__c to be set'
        );
        System.assertEquals('030101', person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('03', person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('0301', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('030101', person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    @IsTest
    static void setGTFromKommunenummerNoDistrict() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.kommunenummerFraGt = '0301';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(
            '0301',
            person.INT_GTMunicipalityNumber__c,
            'Expected INT_GTMunicipalityNumber__c to be set'
        );
        System.assertEquals(null, person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('03', person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('0301', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    @IsTest
    static void setGTFromKommunenummerFromAddressOnly() {
        Person__c person = new Person__c(INT_Confidential__c = 'UGRADERT');
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson('11223344556');
        kafkaPerson.bostedsadresse.vegadresse.add(new KafkaPerson2.Vegadresse());
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = 'Testveien';
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = '1';
        kafkaPerson.bostedsadresse.vegadresse[0].adressenavn = 'A';
        kafkaPerson.bostedsadresse.vegadresse[0].postnummer = '0001';
        kafkaPerson.bostedsadresse.vegadresse[0].kommunenummer = '4321';
        kafkaPerson.bostedsadresse.vegadresse[0].bydelsnummer = '030110';
        kafkaPerson.bostedsadresse.vegadresse[0].koordinater = 'x=354424, y=6862099, z=0';

        Test.startTest();
        KafkaPDLHandler2 handler = new KafkaPDLHandler2();
        handler.setAddress(person, kafkaPerson);
        handler.setMunicipalityAndGT(person, kafkaPerson);
        Test.stopTest();

        System.assertEquals(null, person.INT_GTMunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_GTDistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals(null, person.INT_RegionNumber__c, 'Expected INT_RegionNumber__c to be set');
        System.assertEquals('4321', person.INT_MunicipalityNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
        System.assertEquals('030110', person.INT_DistrictNumber__c, 'Expected INT_GTMunicipalityNumber__c to be set');
    }

    /***********
     * HELPERS *
     **********/
    private static void isKafkaMessageProcessed(KafkaMessage__c message) {
        System.assertEquals(
            KafkaMessageService.STATUS_PROCESSED,
            message.CRM_Status__c,
            'Expected message to be processed but it is ' +
            message.CRM_Status__c +
            '. CRM_ErrorMessage__c: ' +
            message.CRM_ErrorMessage__c
        );
    }

    private static KafkaPerson2 createBaseKafkaPersonOld(String actorId) {
        KafkaPerson2 kafkaPerson = createBaseKafkaPerson(actorId);
        kafkaPerson.aktoerId = actorId;
        kafkaPerson.folkeregisterId = new List<String>();
        kafkaPerson.folkeregisteridentifikator = null;
        kafkaPerson.identer = null;
        return kafkaPerson;
    }

    private static KafkaPerson2 createBaseKafkaPerson(String actorId) {
        KafkaPerson2 kafkaPerson = new KafkaPerson2();
        kafkaPerson.identer = new List<PDL_IdentInformasjon>();
        kafkaPerson.folkeregisteridentifikator = new List<PDL_Folkeregisteridentifikator>();
        kafkaPerson.foedselsdato = new List<String>();
        kafkaPerson.folkeregisterpersonstatus = new List<String>();
        kafkaPerson.navn = new List<PDL_Navn>();
        kafkaPerson.bostedsadresse = new KafkaPerson2.Adresser();
        kafkaPerson.bostedsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>();
        kafkaPerson.bostedsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>();
        kafkaPerson.bostedsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>();
        kafkaPerson.bostedsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>();
        kafkaPerson.oppholdsadresse = new KafkaPerson2.Adresser();
        kafkaPerson.oppholdsadresse.vegadresse = new List<KafkaPerson2.Vegadresse>();
        kafkaPerson.oppholdsadresse.matrikkeladresse = new List<KafkaPerson2.Matrikkeladresse>();
        kafkaPerson.oppholdsadresse.utenlandskAdresse = new List<KafkaPerson2.UtenlandskAdresse>();
        kafkaPerson.oppholdsadresse.ukjentBosted = new List<KafkaPerson2.UkjentBosted>();
        kafkaPerson.innflyttingTilNorge = new List<PDL_InnflyttingTilNorge>();
        kafkaPerson.utflyttingFraNorge = new List<PDL_UtflyttingFraNorge>();
        kafkaPerson.adressebeskyttelse = new List<String>();
        kafkaPerson.kommunenummerFraGt = '<UKJENT_FRA_PDL>';
        kafkaPerson.bydelsnummerFraGt = '<UKJENT_FRA_PDL>';
        kafkaPerson.sivilstand = new List<PDL_Sivilstand>();
        kafkaPerson.statsborgerskap = new List<String>();
        kafkaPerson.kjoenn = new List<String>();
        kafkaPerson.doedsfall = new List<KafkaPerson2.Doedsfall>();
        kafkaPerson.telefonnummer = new List<KafkaPerson2.Telefonnummer>();

        //Default values
        //Ident
        kafkaPerson.identer.add(new PDL_IdentInformasjon());
        kafkaPerson.identer[0].gruppe = PDL_IdentGruppe.AKTORID;
        kafkaPerson.identer[0].historisk = false;
        kafkaPerson.identer[0].ident = actorId;
        //Person status
        kafkaPerson.folkeregisterpersonstatus.add('bosatt');
        //Navn
        kafkaPerson.navn.add(new PDL_Navn());
        kafkaPerson.navn[0].etternavn = 'TESTESEN';
        kafkaPerson.adressebeskyttelse.add('UGRADERT');

        return kafkaPerson;
    }

    private static KafkaMessage__c createKafkaMessageHelper(
        KafkaPerson2 kafkaPerson,
        String aktorId,
        Boolean tombstone
    ) {
        KafkaMessage__c kafkaMessage = new KafkaMessage__c(
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(kafkaPerson))),
            CRM_Key__c = EncodingUtil.base64Encode(
                Blob.valueOf('{"aktoer_id":"' + aktorId + '","tombstone":' + tombstone + '}')
            ),
            CRM_Topic__c = 'teamnks.nks-sf-pdl-v3'
        );

        return kafkaMessage;
    }

    private static Map<String, Person__c> getPersonAccountByActorIdent() {
        Map<String, Person__c> personByActorIdent = new Map<String, Person__c>();
        for (Person__c person : [
            SELECT
                Id,
                Name,
                INT_ActorId__c,
                INT_AddressDistrictNumber__c,
                INT_AddressMunicipalityNumber__c,
                INT_Citizenships__c,
                INT_Confidential__c,
                INT_Coordinates__c,
                INT_DateOfBirth__c,
                INT_DateOfDeath__c,
                INT_DistrictNumber__c,
                INT_dnr__c,
                INT_FamilyRelations__c,
                INT_fnr__c,
                INT_FirstName__c,
                INT_GTDistrictNumber__c,
                INT_GTMunicipalityNumber__c,
                INT_GuardianshipOrFuturePowerOfAttorney__c,
                INT_IsDeceased__c,
                INT_IsNavEmployee__c,
                INT_LastName__c,
                INT_LastUpdatedFromPDL__c,
                INT_LastUpdatedFromKRR__c,
                INT_LegalStatus__c,
                INT_MaritalRelation__c,
                INT_MaritalStatus__c,
                INT_MaritalStatusDate__c,
                INT_MiddleName__c,
                INT_MovedFromCountry__c,
                INT_MovedFromPlace__c,
                INT_MovedToCountry__c,
                INT_MovedToPlace__c,
                INT_MunicipalityNumber__c,
                INT_npid__c,
                INT_Phone1__c,
                INT_Phone2__c,
                INT_PowerOfAttorney__c,
                INT_RegionNumber__c,
                INT_ResidentialAddress__c,
                INT_ResidentialZipCode__c,
                INT_SecurityMeasures__c,
                INT_Sex__c,
                INT_SpokenLanguageIntepreter__c,
                INT_TemporaryAddress__c,
                INT_TemporaryCountryCode__c,
                INT_TemporaryMunicipalityNumber__c,
                INT_TemporaryZipCode__c,
                INT_TemporaryCoordinates__c
            FROM Person__c
        ]) {
            personByActorIdent.put(person.INT_ActorId__c, person);
        }
        return personByActorIdent;
    }
}
