/**
 *  Provus Services Quoting
 *  ProjectPhaseTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class SettingsServiceTest extends QuoteItemTestsBase {
	@TestSetup
	static void setup() {
		newQuote('Test Override Quote');
	}

	@IsTest
	static void getProvusSetupExpectProvusSetupDtoWithPopulatedFields() {
		ProvusSetupDTO provusSetupDTO = SettingsService.getProvusSetup();
		System.assertNotEquals(
			null,
			provusSetupDTO.sO,
			'provus setup DTO sO property should not be null'
		);
		System.assertNotEquals(
			null,
			provusSetupDTO.scheduleSettingDTO,
			'provus setup DTO scheduleSettingDTO property should not be null'
		);
		System.assertEquals(
			8,
			provusSetupDTO.scheduleSettingDTO.sO.StandardDayHours__c,
			'StandardDayHours__c field value should equal 8'
		);
		System.assertEquals(
			40,
			provusSetupDTO.scheduleSettingDTO.sO.StandardWeekHours__c,
			'StandardWeekHours__c field value should equal 40'
		);
		System.assertEquals(
			160,
			provusSetupDTO.scheduleSettingDTO.sO.StandardMonthHours__c,
			'StandardMonthHours__c field value should equal 160'
		);
		System.assertEquals(
			1920,
			provusSetupDTO.scheduleSettingDTO.sO.StandardYearHours__c,
			'StandardYearHours__c field value should equal 1920'
		);
		System.assertEquals(
			8,
			provusSetupDTO.scheduleSettingDTO.standardDayHours,
			'standardDayHours field value should equal 8'
		);
		System.assertEquals(
			40,
			provusSetupDTO.scheduleSettingDTO.standardWeekHours,
			'standardWeekHours field value should equal 40'
		);
		System.assertEquals(
			160,
			provusSetupDTO.scheduleSettingDTO.standardMonthHours,
			'standardMonthHours field value should equal 160'
		);
		System.assertEquals(
			1920,
			provusSetupDTO.scheduleSettingDTO.standardYearHours,
			'standardYearHours field value should equal 1920'
		);
	}

	@IsTest
	static void getScheduleSettingsForQuoteScheduleSettingDtoWithPopulatedFields() {
		TestData testD = retrieveTestData();

		ScheduleSettingDTO scheduleSettingDTO = SettingsService.getScheduleSettingsForQuote(
			testD.quote.Id
		);
		System.assertNotEquals(null, scheduleSettingDTO, 'schedule setting DTO should not be null');
		System.assertEquals(
			8,
			scheduleSettingDTO.standardDayHours,
			'standardDayHours value should equal 8'
		);
		System.assertEquals(
			40,
			scheduleSettingDTO.standardWeekHours,
			'standardWeekHours value should equal 40'
		);
		System.assertEquals(
			160,
			scheduleSettingDTO.standardMonthHours,
			'standardMonthHours value should equal 160'
		);
		System.assertEquals(
			1920,
			scheduleSettingDTO.standardYearHours,
			'standardYearHours value should equal 1920'
		);
	}

	private static TestData retrieveTestData() {
		TestData testData = new TestData();

		testData.quote = [SELECT Id FROM Quote__c WHERE Name = 'Test Override Quote'];

		return testData;
	}

	private class TestData {
		public Quote__c quote;
	}
}
