/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class TimePeriodQuarter implements ITimePeriod {
	public static final String NAME = 'Quarter';
	public static final String NAME_PLURAL = 'Quarters';

	public Date calculateEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date periodEndDate = timePeriodAlignment == null ||
			timePeriodAlignment == QuotePeriodService.TIME_PERIODS_ALIGNMENT_SERVICE_START
			? startDate.addMonths(3).addDays(-1)
			: null;

		if (timePeriodAlignment == QuotePeriodService.TIME_PERIODS_ALIGNMENT_CALENDAR) {
			periodEndDate = startDate.toStartOfMonth().addMonths(3).addDays(-1);
		}

		if (periodEndDate > endDate) {
			periodEndDate = endDate;
		}

		return periodEndDate;
	}

	public Date calculateGroupEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date groupEndDate = startDate.addMonths(3).addDays(-1);

		if (groupEndDate > endDate) {
			groupEndDate = endDate;
		}

		return groupEndDate;
	}

	public Decimal calculateTerm(Date startDate, Date endDate) {
		return (startDate.daysBetween(endDate) + 1) / 90.00;
	}

	public String generateName(Date startDate, Date endDate, Integer sequence) {
		return 'Quarter ' + sequence;
	}
}
