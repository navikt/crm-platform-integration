@IsTest
private class PopulateIsNavEmployee_ScheduleTest {
    
    @TestSetup
    private static void makeData(){

        List<Person__c> persons=new List<Person__c>();
        //person with skjerming from today
        Person__c person1=new Person__c();
        person1.Name='1';
        person1.INT_ActorId__c='1';
        person1.INT_LastName__c='Test';
        person1.INT_NavEmployeeFromDate__c=Date.today();
        person1.INT_IsNavEmployee__c=false;
        persons.add(person1);

        //person with skjerming in future
        Person__c person2=new Person__c();
        person2.Name='2';
        person2.INT_ActorId__c='2';
        person2.INT_LastName__c='Test';
        person2.INT_NavEmployeeFromDate__c=Date.today().addDays(3);
        person2.INT_NavEmployeeToDate__c=Date.today().addDays(30);
        person2.INT_IsNavEmployee__c=false;
        persons.add(person2);

        //person with no skjerming from today
        Person__c person3=new Person__c();
        person3.Name='3';
        person3.INT_ActorId__c='3';
        person3.INT_LastName__c='Test';
        person3.INT_NavEmployeeFromDate__c=Date.today().addMonths(-1);
        person3.INT_NavEmployeeToDate__c=Date.today().addDays(-1);
        person3.INT_IsNavEmployee__c=true;
        persons.add(person3);

        //person with no skjerming
        Person__c person4=new Person__c();
        person4.Name='4';
        person4.INT_ActorId__c='5';
        person4.INT_LastName__c='Test';
        person4.INT_IsNavEmployee__c=false;
        persons.add(person4);
         
        insert persons;
    }

    @IsTest
	private static void testBatchExecute() {

		Test.startTest();
		PopulateIsNavEmployee_Schedule btch = new PopulateIsNavEmployee_Schedule();
		Database.executeBatch( btch, 2000 );
		Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Person__c WHERE INT_IsNavEmployee__c=true], 'One person is nav employee');
        System.assertEquals(1, [SELECT count() FROM Person__c WHERE INT_IsNavEmployee__c=true AND Name='1'], 'First person is nav employee');
	}

	@IsTest
	private static void testScheduleExecute() {

		Test.startTest();
		PopulateIsNavEmployee_Schedule  scheduleClass = new PopulateIsNavEmployee_Schedule ();
		String chron = '0 0 23 * * ?';
		System.schedule( 'Populate is Nav employee', chron, scheduleClass );
		Test.stopTest();
		System.assertEquals( 1, [SELECT count() FROM CronTrigger], 'A job should be scheduled' );
	}
}
