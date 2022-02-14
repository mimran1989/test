/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class TimePeriodMonth implements ITimePeriod {
	public static final String NAME = 'Month';
	public static final String NAME_PLURAL = 'Months';

	public Date calculateEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date periodEndDate = timePeriodAlignment == null ||
			timePeriodAlignment == QuotePeriodService.TIME_PERIODS_ALIGNMENT_SERVICE_START
			? startDate.addMonths(1).addDays(-1)
			: null;

		if (timePeriodAlignment == QuotePeriodService.TIME_PERIODS_ALIGNMENT_CALENDAR) {
			periodEndDate = startDate.toStartOfMonth().addMonths(1).addDays(-1);
		}

		if (periodEndDate > endDate) {
			periodEndDate = endDate;
		}

		return periodEndDate;
	}

	public Date calculateGroupEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date groupEndDate = startDate.addMonths(1).addDays(-1);

		if (groupEndDate > endDate) {
			groupEndDate = endDate;
		}

		return groupEndDate;
	}

	public Decimal calculateTerm(Date startDate, Date endDate) {
		if (startDate.month() != endDate.month() || startDate.year() != endDate.year()) {
			Decimal termPart1 =
				(Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())) -
				Decimal.valueOf(startDate.day()) +
				1.00) / (Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())));
			Decimal termPart2 =
				(Decimal.valueOf(endDate.day())) /
				(Decimal.valueOf(Date.daysInMonth(endDate.year(), endDate.month())));
			Decimal termPart3 = Decimal.valueOf(startDate.monthsBetween(endDate)) - 1.00;
			return termPart1 + termPart2 + termPart3;
		} else {
			return (Decimal.valueOf(endDate.day()) - Decimal.valueOf(startDate.day()) + 1.00) /
				(Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())));
		}
	}

	public String generateName(Date startDate, Date endDate, Integer sequence) {
		Datetime periodStart = Datetime.newInstance(startDate, Time.newInstance(0, 0, 1, 0));
		Datetime periodEnd = Datetime.newInstance(endDate, Time.newInstance(24, 59, 59, 0));

		if (periodStart.year() == periodEnd.year() && periodStart.month() == periodEnd.month()) {
			return periodStart.format('MMM') + '/' + periodStart.format('YYYY');
		} else if (periodStart.year() != periodEnd.year() && periodStart.month() == periodEnd.month()) {
			return generateDifferingYearSameMonth(periodStart, periodEnd);
		} else if (periodStart.year() == periodEnd.year() && periodStart.month() != periodEnd.month()) {
			return generateSameYearDifferingMonth(periodStart, periodEnd);
		} else if (periodStart.year() != periodEnd.year() && periodStart.month() != periodEnd.month()) {
			return generateDifferingYearAndMonth(periodStart, periodEnd);
		}

		return '';
	}

	private String generateDifferingYearSameMonth(Datetime periodStart, Datetime periodEnd) {
		return periodStart.format('MMM') +
			'/' +
			periodStart.format('YYYY') +
			' to ' +
			periodEnd.format('MMM') +
			'/' +
			periodEnd.format('YYYY');
	}

	private String generateSameYearDifferingMonth(Datetime periodStart, Datetime periodEnd) {
		return periodStart.format('MMM') +
			' to ' +
			periodEnd.format('MMM') +
			'/' +
			periodEnd.format('YYYY');
	}

	private String generateDifferingYearAndMonth(Datetime periodStart, Datetime periodEnd) {
		return periodStart.format('MMM') +
			'/' +
			periodStart.format('YYYY') +
			' to ' +
			periodEnd.format('MMM') +
			'/' +
			periodEnd.format('YYYY');
	}
}
