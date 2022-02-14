/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */

@IsTest
private class DefaultPeriodServiceTest extends TestBase {
	@IsTest
	static void shouldCreateDaysInWeekSingle() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/1/2022');
		quoteSO.ServiceEndDate__c = Date.parse('1/7/2022');
		quoteSO.TimePeriod__c = TimePeriodDay.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodWeek.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 week');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(7, periods.size(), 'week should contain 7 days');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateDaysInWeeksMultiple() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/1/2022');
		quoteSO.ServiceEndDate__c = Date.parse('12/31/2022');
		quoteSO.TimePeriod__c = TimePeriodDay.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodWeek.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(52, periodsByGroup.size(), 'should contain 52 weeks');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(7, periods.size(), 'weeks should contain 7 days');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateQuartersInYearSingle() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/1/2022');
		quoteSO.ServiceEndDate__c = Date.parse('12/31/2022');
		quoteSO.TimePeriod__c = TimePeriodQuarter.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 year');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(4, periods.size(), 'year should contain 4 quarters');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateQuartersInYearSingleServiceStart() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('2/2/2022');
		quoteSO.ServiceEndDate__c = Date.parse('2/1/2023');
		quoteSO.TimePeriod__c = TimePeriodQuarter.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Service Start';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 year');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(4, periods.size(), 'year should contain 4 quarters');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateQuartersInYearsMultiple() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/1/2022');
		quoteSO.ServiceEndDate__c = Date.parse('12/31/2031');
		quoteSO.TimePeriod__c = TimePeriodQuarter.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(10, periodsByGroup.size(), 'should contain 10 years');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(4, periods.size(), 'years should contain 4 quarters');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateQuartersInYearSingleCalendar() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/21/2022');
		quoteSO.ServiceEndDate__c = Date.parse('1/20/2023');
		quoteSO.TimePeriod__c = TimePeriodQuarter.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 year');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(5, periods.size(), 'year should contain 5 quarters');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateWeeksInYearSingle() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('1/1/2022');
		quoteSO.ServiceEndDate__c = Date.parse('12/31/2022');
		quoteSO.TimePeriod__c = TimePeriodWeek.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 year');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(53, periods.size(), 'years should contain 53 weeks');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateWeeksInYearMultipleOffsetCalendar() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('2/15/2022');
		quoteSO.ServiceEndDate__c = Date.parse('2/29/2024');
		quoteSO.TimePeriod__c = TimePeriodWeek.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodYear.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(3, periodsByGroup.size(), 'should contain 3 years');
		System.assertEquals(53, periodsByGroup.values()[0].size(), 'year 1 should contain 53 weeks'); // 2/15/2022 => 2/18/2023
		System.assertEquals(52, periodsByGroup.values()[1].size(), 'year 2 should contain 52 weeks'); // 2/19/2023 => 2/17/2024
		System.assertEquals(2, periodsByGroup.values()[2].size(), 'year 3 should contain 2 weeks'); // 2/18/2024 => 2/29/2024
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateWeekInMonthSingleServiceStart() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('2/15/2022');
		quoteSO.ServiceEndDate__c = Date.parse('3/14/2022');
		quoteSO.TimePeriod__c = TimePeriodWeek.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodMonth.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Service Start';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 month');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(4, periods.size(), 'month should contain 4 weeks');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateWeekInMonthSingleCalendar() {
		Quote__c quoteSO = newQuote();
		quoteSO.ServiceStartDate__c = Date.parse('2/15/2022');
		quoteSO.ServiceEndDate__c = Date.parse('3/14/2022');
		quoteSO.TimePeriod__c = TimePeriodWeek.NAME_PLURAL;
		quoteSO.TimePeriodsGroupMethod__c = TimePeriodMonth.NAME;
		quoteSO.TimePeriodsAlignment__c = 'Calendar';
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		DefaultPeriodService service = new DefaultPeriodService();
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = service.generatePeriods(
			quoteSO
		);
		System.assertEquals(1, periodsByGroup.size(), 'should contain 1 month');
		for (List<QuotePeriod__c> periods : periodsByGroup.values()) {
			System.assertEquals(5, periods.size(), 'month should contain 5 weeks');
		}
		Test.stopTest();
	}
}
