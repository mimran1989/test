/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class TimePeriodYear implements ITimePeriod {
	public static final String NAME = 'Year';
	public static final String NAME_PLURAL = 'Years';

	public Date calculateEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		return null; // year is not a valid period
	}

	public Date calculateGroupEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date groupEndDate = startDate.addYears(1).addDays(-1);

		if (groupEndDate > endDate) {
			groupEndDate = endDate;
		}

		return groupEndDate;
	}

	public Decimal calculateTerm(Date startDate, Date endDate) {
		return 0.0;
	}

	public String generateName(Date startDate, Date endDate, Integer sequence) {
		return '';
	}
}
