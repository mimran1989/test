/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public interface ITimePeriod {
	Date calculateEndDate(Date startDate, Date endDate, String timePeriodAlignment);
	Date calculateGroupEndDate(Date startDate, Date endDate, String timePeriodAlignment);
	Decimal calculateTerm(Date startDate, Date endDate);
	String generateName(Date startDate, Date endDate, Integer sequence);
}
