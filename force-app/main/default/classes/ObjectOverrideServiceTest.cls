/**
 *  Provus Services Quoting
 *  ObjectOverrideServiceTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class ObjectOverrideServiceTest extends QuoteItemTestsBase {
	static final String SCHEDULE_SETTING_API_NAME = SObjectType.ScheduleSetting__mdt.getName();
	static final String PROVUS_CONFIGURATOR_SETTING_API_NAME = SObjectType.ProvusConfiguratorSetting__mdt.getName();
	static final String FIELDNAME_STANDARDWEEKHOURS =
		Schema.ScheduleSetting__mdt.StandardWeekHours__c + '';
	static final String FIELDNAME_STANDARDDAYOURS =
		Schema.ScheduleSetting__mdt.StandardDayHours__c + '';
	static final String FIELDNAME_HIDDENFIELDS =
		Schema.ProvusConfiguratorSetting__mdt.HiddenFields__c + '';
	static String testOverrideValue1 = 'Test String Value';
	static String testOverrideValue2 = 'Test String Value 2';

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

		ValueOverride__c valueOverride2 = new ValueOverride__c();
		valueOverride2.FieldApiName__c = FIELDNAME_STANDARDDAYOURS;
		valueOverride2.ObjectOverrideId__c = objectValueOverride.Id;
		valueOverride2.FieldValue__c = testOverrideValue2;
		insert valueOverride2;

		QuoteObjectOverride__c quoteObjectOverride = new QuoteObjectOverride__c(
			ObjectOverrideId__c = objectValueOverride.Id,
			QuoteId__c = quote.Id
		);
		insert quoteObjectOverride;

		ValueOverride__c valueOverrideSO = new ValueOverride__c();
		valueOverrideSO.FieldApiName__c = FIELDNAME_HIDDENFIELDS;
		valueOverrideSO.FieldValue__c = testOverrideValue1;
		ValueOverrideDTO valueOverrideDto = new ValueOverrideDTO(valueOverrideSO);

		ObjectOverrideDTO objectOverrideDto = new ObjectOverrideDTO(
			PROVUS_CONFIGURATOR_SETTING_API_NAME
		);
		objectOverrideDto.valueOverrides.add(valueOverrideDto);

		ObjectOverrideService.commitObjectOverride(objectOverrideDto);
	}

	@IsTest
	static void getObjectOverrideReturnsObjectOverrideAndTwoFieldValueOverrides() {
		TestData testData = retrieveTestData();

		Test.startTest();

		QuoteObjectOverride__c junctionRecord = ObjectOverrideService.getObjectOverrideId(
			testData.quote.Id,
			SCHEDULE_SETTING_API_NAME
		);

		ObjectOverrideDTO objectOverride = ObjectOverrideService.getObjectOverride(
			junctionRecord.ObjectOverrideId__c
		);

		List<ValueOverrideDTO> valueOverrides = objectOverride.valueOverrides;

		System.assertEquals(
			4,
			valueOverrides.size(),
			'should return four value field override records'
		);

		ValueOverrideDTO valueOverride1 = getOverrideByApiName(
			FIELDNAME_STANDARDDAYOURS,
			valueOverrides
		);
		System.assertNotEquals(null, valueOverride1.id, 'id should not be null');
		System.assertEquals(
			testOverrideValue2,
			valueOverride1.fieldValue,
			'field value should be equal to the test override value 1'
		);
		System.assertEquals('8.0', valueOverride1.defaultFieldValue, 'expect default value of \'8.0\'');
		System.assertEquals(
			'Hours in a standard day',
			valueOverride1.fieldLabel,
			'should return field label of \'Hours in a standard day\''
		);

		ValueOverrideDTO valueOverride2 = getOverrideByApiName(
			FIELDNAME_STANDARDWEEKHOURS,
			valueOverrides
		);
		System.assertNotEquals(null, valueOverride2.id, 'value override record id should not be null');
		System.assertEquals(
			testOverrideValue1,
			valueOverride2.fieldValue,
			'field value should be equal to the test override value 1'
		);

		Test.stopTest();
	}

	@IsTest
	static void commitObjectOverrideWithInvalidApiNameNoDmlTransactionOccurs() {
		String overrideObjectApiName = 'Invalid API Name';

		ObjectOverrideDTO objectOverrideDto = new ObjectOverrideDTO(overrideObjectApiName);

		Test.startTest();

		ObjectOverrideResult validation = ObjectOverrideService.commitObjectOverride(objectOverrideDto);
		System.assertEquals(false, validation.isValid(), 'isValid should return false');
		System.assertEquals(
			1,
			validation.errorMsgs.size(),
			'there should be one validation error message'
		);
		String expectedErrorMessage = Label.InvalidObjectAPIName.replace('{0}', overrideObjectApiName);
		System.assertEquals(
			expectedErrorMessage,
			validation.errorMsgs[0],
			'Expect invalid object API name validation message'
		);

		Test.stopTest();
	}

	@IsTest
	static void commitObjectOverrideWithInvalidFieldApiNameNoDmlTransactionOccurs() {
		String fieldApiName = 'Invalid field API Name';

		ValueOverride__c valueOverrideSO = new ValueOverride__c();
		valueOverrideSO.FieldApiName__c = fieldApiName;
		valueOverrideSO.FieldValue__c = testOverrideValue1;
		ValueOverrideDTO valueOverrideDto = new ValueOverrideDTO(valueOverrideSO);

		ObjectOverrideDTO objectOverrideDto = new ObjectOverrideDTO(
			PROVUS_CONFIGURATOR_SETTING_API_NAME
		);
		objectOverrideDto.valueOverrides.add(valueOverrideDto);

		Test.startTest();

		ObjectOverrideResult validation = ObjectOverrideService.commitObjectOverride(objectOverrideDto);
		System.assertEquals(false, validation.isValid(), 'isValid should return false');
		System.assertEquals(
			1,
			validation.errorMsgs.size(),
			'there should be one validation error message'
		);
		String expectedErrorMessage = Label.InvalidFieldAPIName.replace('{0}', fieldApiName);
		System.assertEquals(
			expectedErrorMessage,
			validation.errorMsgs[0],
			'Expect invalid field API name validation message'
		);

		Test.stopTest();
	}

	@IsTest
	static void commitObjectOverrideWithValidObjectAndFieldApiName() {
		Id objectOverrideId = getObjectOverrideIdByApiName(PROVUS_CONFIGURATOR_SETTING_API_NAME);

		Test.startTest();

		ObjectOverrideDTO objectOverrideDto = ObjectOverrideService.getObjectOverride(objectOverrideId);
		ObjectOverrideResult validation = ObjectOverrideService.commitObjectOverride(objectOverrideDto);

		System.assertEquals(true, validation.isValid(), 'isValid should return false');
		ObjectOverrideDTO objectOverrideDtoFromDb = validation.objectOverrideDtos[0];
		System.assertNotEquals(
			null,
			objectOverrideDtoFromDb.id,
			'id field of DTO object should NOT be null'
		);
		System.assertNotEquals(
			null,
			objectOverrideDtoFromDb.sO.Id,
			'id field of SO object should NOT be null'
		);
		System.assertNotEquals(
			null,
			objectOverrideDtoFromDb.valueOverrides[0].id,
			'id field of DTO value override object should NOT be null'
		);
		System.assertNotEquals(
			null,
			objectOverrideDtoFromDb.valueOverrides[0].sO.Id,
			'id field of SO value override object should NOT be null'
		);

		ObjectOverride__c objectOverrideSO = [
			SELECT
				Id,
				OverrideObjectApiName__c,
				(
					SELECT Id, FieldApiName__c, FieldValue__c, ObjectOverrideId__c
					FROM ObjectValueOverrides__r
				)
			FROM ObjectOverride__c
			WHERE Id = :objectOverrideDtoFromDb.id
		];

		System.assertNotEquals(
			null,
			objectOverrideSO,
			'object override SO exists in DB and is not null'
		);
		System.assertEquals(
			1,
			objectOverrideSO.ObjectValueOverrides__r.size(),
			'list of value override SOs exists in DB and list should have one entry'
		);
		System.assertEquals(
			FIELDNAME_HIDDENFIELDS,
			objectOverrideSO.ObjectValueOverrides__r[0].FieldApiName__c,
			'The object\'s field API name should equal '
		);
		System.assertEquals(
			testOverrideValue1,
			objectOverrideSO.ObjectValueOverrides__r[0].FieldValue__c,
			'make sure the correct field value is committed to the DB'
		);

		Test.stopTest();
	}

	@IsTest
	static void commitObjectOverrideClearValueOverrideListAllRecordsAreDeleted() {
		Test.startTest();

		Id objectOverrideId = getObjectOverrideIdByApiName(PROVUS_CONFIGURATOR_SETTING_API_NAME);

		ObjectOverrideDTO objectOverride = ObjectOverrideService.getObjectOverride(objectOverrideId);
		objectOverride.valueOverrides = new List<ValueOverrideDTO>();

		ObjectOverrideService.commitObjectOverride(objectOverride);

		try {
			// retrieve record
			ObjectOverrideService.getObjectOverride(objectOverrideId);
		} catch (Exception ex) {
			// should be empty/null
			System.assertEquals(
				'System.QueryException',
				ex.getTypeName(),
				'we expect an exception to be thrown of type QueryException'
			);
			System.assertEquals(
				'List has no rows for assignment to SObject',
				ex.getMessage(),
				'we expect error message indicating that a list has no rows for assignment'
			);
		}

		Test.stopTest();
	}

	private static Id getObjectOverrideIdByApiName(String objectApiName) {
		return [SELECT Id FROM ObjectOverride__c WHERE OverrideObjectApiName__c = :objectApiName].Id;
	}

	private static ValueOverrideDTO getOverrideByApiName(
		String fieldApiName,
		List<ValueOverrideDTO> valueOverrides
	) {
		ValueOverrideDTO selectedValueOverride;
		for (ValueOverrideDTO valueOverride : valueOverrides) {
			if (valueOverride.fieldApiName == fieldApiName) {
				selectedValueOverride = valueOverride;
				break;
			}
		}
		return selectedValueOverride;
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
