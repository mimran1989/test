/**
 *  Provus Services Quoting
 *  DurationCalculationHelperTest
 *  @2022 Provus Inc. All rights reserved.
 */
@IsTest
private class DurationCalcsTest {
	@IsTest
	static void aligntmentCalendarEndDateOnLastDayOfEndMonth() {
		EndDateArgs endDateReq = new EndDateArgs();
		endDateReq.timePeriods = 'Months';
		endDateReq.calendarAlignment = 'Calendar';
		endDateReq.serviceStartDate = Date.valueOf('2021-5-5');

		Date serviceEndDate = DurationCalcs.endDate(500, endDateReq);

		System.assertEquals(
			Date.valueOf('2021-8-31'),
			serviceEndDate,
			'service end date should equal \'2021-8-31\''
		);
	}

	@IsTest
	static void alignmentServiceStartAddsThreeMonthsAndThreeDaysToStartDate() {
		EndDateArgs endDateReq = new EndDateArgs();
		endDateReq.timePeriods = 'Months';
		endDateReq.calendarAlignment = 'Service Start';
		endDateReq.serviceStartDate = Date.valueOf('2021-5-5');

		Date serviceEndDate = DurationCalcs.endDate(500, endDateReq);

		System.assertEquals(
			Date.valueOf('2021-08-08'),
			serviceEndDate,
			'service end date should equal \'2021-08-08\''
		);

		// time periods = Quarters should calculate the end date the same way
		endDateReq.timePeriods = 'Quarters';
		serviceEndDate = DurationCalcs.endDate(500, endDateReq);

		System.assertEquals(
			Date.valueOf('2021-08-08'),
			serviceEndDate,
			'service end date should equal \'2021-08-08\''
		);
	}

	@IsTest
	static void alignmentServiceStartTimePeriodDaysAddSixtyTwoDaysToStartDate() {
		EndDateArgs endDateReq = new EndDateArgs();
		endDateReq.timePeriods = 'Days';
		endDateReq.calendarAlignment = 'Service Start';
		endDateReq.serviceStartDate = Date.valueOf('2021-5-5');

		Date serviceEndDate = DurationCalcs.endDate(500, endDateReq);

		System.assertEquals(
			Date.valueOf('2021-07-06'),
			serviceEndDate,
			'service end date should equal \'2021-07-06\''
		);
	}

	@IsTest
	static void alignmentServiceStartTimePeriodWeeksAddsTwoMonthsAndOneDayToStartDate() {
		EndDateArgs endDateReq = new EndDateArgs();
		endDateReq.timePeriods = 'Weeks';
		endDateReq.calendarAlignment = 'Service Start';
		endDateReq.serviceStartDate = Date.valueOf('2021-5-5');

		Date serviceEndDate = DurationCalcs.endDate(500, endDateReq);

		System.assertEquals(
			Date.valueOf('2021-07-06'),
			serviceEndDate,
			'service end date should equal \'2021-07-06\''
		);
	}

	@IsTest
	static void numberOfPeriodsMonthPeriodsNoLeftOverDays() {
		Date serviceStartDate = Date.valueOf('2021-5-5');
		Date serviceEndDate = Date.valueOf('2021-10-5');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods(
			'Months',
			serviceStartDate,
			serviceEndDate
		);

		System.assertEquals(5, numOfPeriods, 'number of periods should be \'' + 5 + '\'');
	}

	@IsTest
	static void numberOfPeriodsMonthPeriodsWith5LeftOverDaysIncrementsPeriodCount() {
		Date serviceStartDate = Date.valueOf('2021-5-5');
		Date serviceEndDate = Date.valueOf('2021-10-20');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods(
			'Months',
			serviceStartDate,
			serviceEndDate
		);

		System.assertEquals(6, numOfPeriods, 'number of periods should be \'' + 6 + '\'');
	}

	@IsTest
	static void numberOfPeriodsWeekPeriodsNoLeftOverFractionOfWeek() {
		Date serviceStartDate = Date.valueOf('2021-5-1');
		Date serviceEndDate = Date.valueOf('2021-5-28');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods('Weeks', serviceStartDate, serviceEndDate);

		System.assertEquals(4, numOfPeriods, 'number of periods should be \'' + 4 + '\'');
	}

	@IsTest
	static void numberOfPeriodsWeeksWithLeftOverFractionPeriodCountIsIncremented() {
		Date serviceStartDate = Date.valueOf('2021-5-1');
		Date serviceEndDate = Date.valueOf('2021-6-1');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods('Weeks', serviceStartDate, serviceEndDate);

		System.assertEquals(5, numOfPeriods, 'number of periods should be \'' + 5 + '\'');
	}

	@IsTest
	static void numberOfPeriodsDayPeriods() {
		Date serviceStartDate = Date.valueOf('2021-5-1');
		Date serviceEndDate = Date.valueOf('2021-5-15');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods('Days', serviceStartDate, serviceEndDate);

		System.assertEquals(14, numOfPeriods, 'number of periods should be \'' + 14 + '\'');
	}

	@IsTest
	static void numberOfPeriodsQuarterPeriodsNoLeftOver() {
		Date serviceStartDate = Date.valueOf('2021-1-1');
		Date serviceEndDate = Date.valueOf('2021-6-1');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods(
			'Quarters',
			serviceStartDate,
			serviceEndDate
		);

		System.assertEquals(2, numOfPeriods, 'number of periods should be \'' + 2 + '\'');
	}

	@IsTest
	static void numberOfPeriodsQuarterPeriodsExcessDays() {
		Date serviceStartDate = Date.valueOf('2021-1-1');
		Date serviceEndDate = Date.valueOf('2021-7-25');

		Integer numOfPeriods = DurationCalcs.numberOfPeriods(
			'Quarters',
			serviceStartDate,
			serviceEndDate
		);

		System.assertEquals(3, numOfPeriods, 'number of periods should be \'' + 3 + '\'');
	}
}
