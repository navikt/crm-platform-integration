@IsTest
private class KafkaSkjermingHandlerTest {
    
    @TestSetup
    private static void makeData(){
        Person__c person=new Person__c();
        person.Name='12345678901';
        person.INT_ActorId__c='9517877887755';
        person.INT_LastName__c='Test';
        insert person;    
    }

    @IsTest
    private static void processMessages_forExistingPerson(){
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.skjermetFra=setDate(2020,1,1);
        skjerming.skjermetTil=setDate(2020,6,31);
        
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(new KafkaMessage__c(
                CRM_Topic__c = 'aapen-skjermede-personer-v1',
                CRM_Key__c = '9517877887755',
                CRM_Value__c = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(skjerming)))
        ));

        Test.startTest();
        KafkaSkjermingHandler  handler=new KafkaSkjermingHandler();
        handler.processMessages(kafkaMessages);
        Test.stopTest();

        Person__c person=[SELECT INT_NavEmployeeFromDate__c, INT_NavEmployeeToDate__c FROM Person__c WHERE INT_ActorId__c='9517877887755'];
        System.assertEquals(Date.newInstance(2020, 1, 1), person.INT_NavEmployeeFromDate__c,'From date should be set on person');
        System.assertEquals(Date.newInstance(2020, 6, 31), person.INT_NavEmployeeToDate__c,'To date should be set on person');
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
        System.assertEquals('3517877887755', skjerming.aktoerId, 'Actor id for skjerming');
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
        System.assertEquals('3517877887755', skjerming.aktoerId, 'Actor id for skjerming');
        System.assertEquals(Date.newInstance(2020, 5, 18), skjerming.skjermetFraDate, 'Skjermet fra is set');
        System.assertEquals(null, skjerming.skjermetTilDate, 'Skjermet til is null');
        
    }

    @IsTest
    private static void convertKafkaSkjermingToPersonSobject(){
        
        KafkaSkjerming skjerming=new KafkaSkjerming();
        skjerming.aktoerId='85175578877552';
        skjerming.skjermetFra=setDate(2020,2,1);
        skjerming.skjermetTil=setDate(2020,12,31);
        
        Test.startTest();
        KafkaSkjermingHandler handler=new KafkaSkjermingHandler();
        Person__c person=handler.convertKafkaSkjermingToPersonSobject(skjerming);
        Test.stopTest();

        System.assertEquals('85175578877552', person.INT_ActorId__c,'Actor Id should be set on person');
        System.assertEquals(Date.newInstance(2020, 2, 1), person.INT_NavEmployeeFromDate__c,'Employee from date should be set on person');
        System.assertEquals(Date.newInstance(2020, 12, 31), person.INT_NavEmployeeToDate__c,'Employee to date should be set on person');
    }

   
    private static List<Integer> setDate(Integer year, Integer month, Integer day){
        return new List<Integer>{year,month,day};
    }
}
