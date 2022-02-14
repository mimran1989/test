/**
 *  Provus Services Quoting
 *  ObjectOverrideControllerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
public with sharing class ObjectOverrideControllerTest extends QuoteItemTestsBase {
	static final String SCHEDULE_SETTING_API_NAME = SObjectType.ScheduleSetting__mdt.getName();
	static final String FIELDNAME_STANDARDWEEKHOURS =
		Schema.ScheduleSetting__mdt.StandardWeekHours__c + '';
	static String testOverrideValue1 = 'Test String Value';

	@TestSetup
	static void setup() {
		Quote__c quote = newQuote('Test Override Quote');

		ObjectOverride__c objectValueOverride = new ObjectOverride__c();
		objectValueOverride.OverrideObjectApiName__c = SCHEDULE_SETTING_API_NAME;
		insert objectValueOverride;

		ValueOverride__c valueOverride = new ValueOverride__c();
		valueOverride.FieldApiName__c = FIELDNAME_STANDARDWEEKHOURS;
		valueOverride.ObjectOverrideId__c = objectValueOverride.Id;
		valueOverride.FieldValue__c = testOverrideValue1;
		insert valueOverride;

		QuoteObjectOverride__c quoteObjectOverride = new QuoteObjectOverride__c(
			ObjectOverrideId__c = objectValueOverride.Id,
			QuoteId__c = quote.Id
		);
		insert quoteObjectOverride;
	}

	@IsTest
	static void getObjectOverrideRecordAndVerifyPopulatedProperly() {
		TestData testData = retrieveTestData();

		Test.startTest();

		ObjectOverrideDTO objOverride = ObjectOverrideController.getObjectOverride(
			testData.quote.Id,
			SCHEDULE_SETTING_API_NAME
		);

		System.assertEquals(4, objOverride.valueOverrides.size(), 'should have four value overrides');

		ValueOverrideDTO selectedValueOverride;
		for (ValueOverrideDTO valueOverride : objOverride.valueOverrides) {
			if (valueOverride.fieldApiName == FIELDNAME_STANDARDWEEKHOURS) {
				selectedValueOverride = valueOverride;
				break;
			}
		}
		System.assertEquals(
			testOverrideValue1,
			selectedValueOverride.fieldValue,
			'field value should match inserted one'
		);

		Test.stopTest();
	}

	private static TestData retrieveTestData() {
		TestData testData = new TestData();

		testData.quote = [SELECT Id FROM Quote__c WHERE Name = 'Test Override Quote'];
		testData.quoteObjectOverride = [
			SELECT ObjectOverrideId__c
			FROM QuoteObjectOverride__c
			WHERE QuoteId__c = :testData.quote.Id
		];

		return testData;
	}

	private class TestData {
		public Quote__c quote;
		public QuoteObjectOverride__c quoteObjectOverride;
	}
}
