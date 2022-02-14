/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class TimePeriodDay implements ITimePeriod {
	public static final String NAME = 'Day';
	public static final String NAME_PLURAL = 'Days';

	public Date calculateEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		Date periodEndDate = startDate.addDays(1).addDays(-1);

		if (periodEndDate > endDate) {
			periodEndDate = endDate;
		}

		return periodEndDate;
	}

	public Date calculateGroupEndDate(Date startDate, Date endDate, String timePeriodAlignment) {
		return null; // day is not a valid period group
	}

	public Decimal calculateTerm(Date startDate, Date endDate) {
		return 1.00;
	}

	public String generateName(Date startDate, Date endDate, Integer sequence) {
		return 'Day ' + sequence;
	}
}
