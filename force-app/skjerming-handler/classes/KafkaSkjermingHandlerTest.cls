@IsTest
private class KafkaSkjermingHandlerTest {
    
    @TestSetup
    private static void makeData(){
        Person__c person=new Person__c();
        person.Name='12345678901';
        person.INT_LastName__c='Test';
        insert person;    
    }

    @IsTest
    private static void processMessages_forExistingPerson(){
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.skjermetFra=setDate(2020,1,1);
        Date toDate=Date.today().addMonths(30);
        skjerming.skjermetTil=setDate(toDate.year(),toDate.month(),toDate.day());
        
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '12345678901',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming)))
        ));

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        handler.processMessages(kafkaMessages);
        Test.stopTest();

        Person__c person=[SELECT INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c, INT_IsNavEmployee__c FROM Person__c WHERE Name='12345678901'];
        System.assertEquals(Date.newInstance(2020, 1, 1), person.INT_NavEmployeeFromDate__c,'From date should be set on person');
        System.assertEquals(toDate, person.INT_NavEmployeeToDate__c,'To date should be set on person');
        System.assertEquals(true, person.INT_IsNavEmployee__c, 'Person is employee');
    }

    @IsTest
    private static void processMessages_ForOneExistingPersonAndOneNotExistingPersonIdent(){
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.skjermetFra=setDate(2020,1,1);
        Date toDate=Date.today().addMonths(30);
        skjerming.skjermetTil=setDate(toDate.year(),toDate.month(),toDate.day());
        
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
            CRM_Topic__c = 'aapen-skjermede-personer-v1',
            CRM_Key__c = '12345678901',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming)))
        ));

        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '99999999999',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming)))
        ));

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        handler.processMessages(kafkaMessages);
        Test.stopTest();

        //existing person should be updated
         Person__c person=[SELECT INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c, INT_IsNavEmployee__c FROM Person__c WHERE Name='12345678901'];
        System.assertEquals(Date.newInstance(2020, 1, 1), person.INT_NavEmployeeFromDate__c,'From date should be set on person');
        System.assertEquals(toDate, person.INT_NavEmployeeToDate__c,'To date should be set on person');
        System.assertEquals(true, person.INT_IsNavEmployee__c, 'Person is employee');

        //kafka message status
        System.assertEquals('Processed', kafkaMessages[0].CRM_Status__c, 'First kafka message should be processed');
        System.assertEquals('Error', kafkaMessages[1].CRM_Status__c, 'Second kafka messages is failing due to not existing person');
        System.assertEquals('Unknown Person Ident',kafkaMessages[1].CRM_ErrorMessage__c,'Error message for failing kafka message');
    }

    @IsTest
    private static void processMessages_WhenToDateIsInThePast(){
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.skjermetFra=setDate(2019,1,1);
        skjerming.skjermetTil=setDate(2019,6,31);
        
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
            CRM_Topic__c = 'aapen-skjermede-personer-v1',
            CRM_Key__c = '12345678901',
            CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming)))
        ));


        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        handler.processMessages(kafkaMessages);
        Test.stopTest();

        //existing person should not be updated
         Person__c person=[SELECT INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c, INT_IsNavEmployee__c FROM Person__c WHERE Name='12345678901'];
        System.assertEquals(null, person.INT_NavEmployeeFromDate__c,'From date should not be updated');
        System.assertEquals(null, person.INT_NavEmployeeToDate__c,'To date should not be updated');
        System.assertEquals(false, person.INT_IsNavEmployee__c, 'Person was employee in the past');

        //kafka message status
        System.assertEquals('Processed', kafkaMessages[0].CRM_Status__c, 'Kafka message should be processed');
    }

    @IsTest
    private static void convertKafkaToSkjerming(){
        KafkaSkjerming testSkjerming=new KafkaSkjerming();
        testSkjerming.skjermetFra=setDate(2020,2,1);
        testSkjerming.skjermetTil=setDate(2020,12,31);

        
        KafkaMessage__c msg= new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '3517877887755',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(testSkjerming)))
        );

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        KafkaSkjerming skjerming=handler.convertKafkaToSkjerming(msg);
        Test.stopTest();
        System.assertEquals('3517877887755', skjerming.personIdent, 'Person ident for skjerming');
        System.assertEquals(Date.newInstance(2020, 2, 1), skjerming.skjermetFraDate, 'Get skjermet fra');
        System.assertEquals(Date.newInstance(2020, 12, 31), skjerming.skjermetTilDate, 'Get skjermet til');
    }

    @IsTest
    private static void convertKafkaToSkjerming_forKafkaPayload(){
  
        KafkaMessage__c msg= new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '3517877887755',
                CRM_Value__c = 'eyJza2plcm1ldEZyYSI6WzIwMjAsNSwxOCwxNCw1Myw0NCw5ODc3MTkwMDBdLCJza2plcm1ldFRpbCI6bnVsbH0='
        );

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        KafkaSkjerming skjerming=handler.convertKafkaToSkjerming(msg);
        Test.stopTest();
        System.assertEquals('3517877887755', skjerming.personIdent, 'Actor id for skjerming');
        System.assertEquals(Date.newInstance(2020, 5, 18), skjerming.skjermetFraDate, 'Skjermet fra is set');
        System.assertEquals(null, skjerming.skjermetTilDate, 'Skjermet til is null');
        
    }

    @IsTest
    private static void convertKafkaSkjermingToPersonSobject_whenEmployeeInPast(){
        
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.personIdent='12345678901';
        skjerming.skjermetFra=setDate(2019,2,1);
        skjerming.skjermetTil=setDate(2019,12,31);

        Person__c testPerson=[SELECT Id, Name, INT_NavEMployeeFromDate__c, INT_NavEMployeeToDate__c, INT_IsNavEmployee__c FROM Person__c LIMIT 1];
        Map<String,Person__c> personByIdent=new Map<String,Person__c>();
        personByIdent.put(testPerson.Name,testPerson);
        
        Test.startTest();
        KafkaSkjermingHandler handler=new KafkaSkjermingHandler();
        Person__c person=handler.convertKafkaSkjermingToPersonSobject(skjerming, personByIdent,null);
        Test.stopTest();

        System.assertEquals('12345678901', person.Name,'Name / Person Ident should be set on person');
        System.assertEquals(Date.newInstance(2019, 2, 1), person.INT_NavEmployeeFromDate__c,'Employee from date should be set on person');
        System.assertEquals(Date.newInstance(2019, 12, 31), person.INT_NavEmployeeToDate__c,'Employee to date should be set on person');
        System.assertEquals(false,person.INT_IsNavEmployee__c,'Employee is in the past');
    }

    @IsTest
    private static void convertKafkaSkjermingToPersonSobject_whenEmployeeIsFromToday(){
        
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.personIdent='12345678901';
        Date dateFrom=Date.today();
        skjerming.skjermetFra=setDate(dateFrom.year(),dateFrom.month(),dateFrom.day());
        skjerming.skjermetTil=null;

        Person__c testPerson=[SELECT Id, Name, INT_NavEMployeeFromDate__c, INT_NavEMployeeToDate__c, INT_IsNavEmployee__c FROM Person__c LIMIT 1];
        Map<String,Person__c> personByIdent=new Map<String,Person__c>();
        personByIdent.put(testPerson.Name,testPerson);
        
        Test.startTest();
        KafkaSkjermingHandler handler=new KafkaSkjermingHandler();
        Person__c person=handler.convertKafkaSkjermingToPersonSobject(skjerming, personByIdent,null);
        Test.stopTest();

        System.assertEquals('12345678901', person.Name,'Name / Person Ident should be set on person');
        System.assertEquals(dateFrom, person.INT_NavEmployeeFromDate__c,'Employee from date should be set on person');
        System.assertEquals(null, person.INT_NavEmployeeToDate__c,'Employee to date should be set on person');
        System.assertEquals(true,person.INT_IsNavEmployee__c,'Employee is from today');
    }

    @IsTest
    private static void convertKafkaSkjermingToPersonSobject_whenPersonDoesNotExist(){
        
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.personIdent='999999999';
        skjerming.skjermetFra=setDate(2020,2,1);
        skjerming.skjermetTil=setDate(2020,12,31);

        Person__c testPerson=[SELECT Id, Name, INT_NavEMployeeFromDate__c, INT_NavEMployeeToDate__c FROM Person__c LIMIT 1];
        Map<String,Person__c> personByIdent=new Map<String,Person__c>();
        personByIdent.put(testPerson.Name,testPerson);
        
        Test.startTest();
        KafkaSkjermingHandler handler=new KafkaSkjermingHandler();
        Person__c person=handler.convertKafkaSkjermingToPersonSobject(skjerming, personByIdent,null);
        Test.stopTest();

        System.assertNotEquals(null, person,'Blank person is returned');
        System.assertEquals(null, person.INT_NavEmployeeFromDate__c,'Person has no eployee dates');
    }

    @IsTest
    private static void getPersonByIdent(){
        Test.startTest();
        KafkaSkjermingHandler handler=new KafkaSkjermingHandler();
        Map<String,Person__c> personByIdent=handler.getPersonByIdent(new Set<String>{'12345678901','2'});
        Test.stopTest();
        System.assertEquals(1, personByIdent.size(), 'Expecting record ids for first person ident');
        System.assertEquals('12345678901',personByIdent.get('12345678901').Name, 'Ident should match Name field on Person__c');
    }

    
    @IsTest
    private static void processMessages_forSamePersonInSameTransaction(){
        KafkaSkjerming skjerming1=new KafkaSkjerming();
        skjerming1.skjermetFra=setDate(2020,1,1);
        Date todayDate=Date.today();
        skjerming1.skjermetTil=setDate(todayDate.year(),todayDate.month(),todayDate.day());

        KafkaSkjerming skjerming2=new KafkaSkjerming();
        skjerming2.skjermetFra=setDate(todayDate.year(),todayDate.month(),todayDate.day());
        Date toDate=Date.today().addMonths(30);
        skjerming2.skjermetTil=setDate(toDate.year(),toDate.month(),toDate.day());
        
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '12345678901',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming1)))
        ));
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '12345678901',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming2)))
        ));

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        handler.processMessages(kafkaMessages);
        Test.stopTest();

        Person__c person=[SELECT INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c, INT_IsNavEmployee__c FROM Person__c WHERE Name='12345678901'];
        System.assertEquals(Date.newInstance(2020, 1, 1), person.INT_NavEmployeeFromDate__c,'From date is from first message');
        System.assertEquals(toDate, person.INT_NavEmployeeToDate__c,'To date sis from second message');
        System.assertEquals(true, person.INT_IsNavEmployee__c, 'Person is employee');
    }

    private static List<Integer> setDate(Integer year, Integer month, Integer day){
        return new List<Integer>{year,month,day};
    }
}
