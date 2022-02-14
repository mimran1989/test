/**
 *  Provus Services Quoting
 *  DurationCalculationHelper
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class DurationCalcs {
	/**
	 * Derives end date based on total estimated duration hours, start date and for given time period preference
	 * @param totalDuration total estimated duration of time in hours
	 * @param serviceEndDateReq end date request object details
	 *
	 * @return returns derived end date
	 */
	public static Date endDate(Decimal totalDuration, EndDateArgs serviceEndDateReq) {
		Date serviceEndDate;
		String timePeriods = serviceEndDateReq.timePeriods;
		Date serviceStartDate = Date.valueOf(serviceEndDateReq.serviceStartDate);

		// get org schedule settings
		ScheduleSettingDTO scheduleSetting = UserDefinedPeriodService.scheduleSetting;

		switch on timePeriods {
			when 'Months', 'Quarters' {
				Decimal noOfMonths = totalDuration / scheduleSetting.standardMonthHours;
				Integer noOfMonthsInt = (Integer) Math.floor(noOfMonths);
				Decimal remainderMonths = noOfMonths - Math.floor(noOfMonthsInt);
				Decimal numberOfDaysInMonth =
					scheduleSetting.standardMonthHours / scheduleSetting.standardDayHours;
				Integer additionalDays = Integer.valueOf(Math.ceil(numberOfDaysInMonth * remainderMonths));
				serviceEndDate = serviceStartDate.addMonths(noOfMonthsInt).addDays(additionalDays);
			}
			when 'Days' {
				serviceEndDate = serviceStartDate
					.addDays((Integer) Math.floor(totalDuration / scheduleSetting.standardDayHours));
			}
			when 'Weeks' {
				// determine number of days in a week
				Integer numberOfDaysInWeek = (Integer) Math.floor(
					scheduleSetting.standardWeekHours / scheduleSetting.standardDayHours
				);
				// multiply number of weeks times number of days in a week to get total number of duration days
				Decimal numberOfTotalDays =
					(totalDuration / scheduleSetting.standardWeekHours) * numberOfDaysInWeek;
				serviceEndDate = serviceStartDate.addDays((Integer) Math.floor(numberOfTotalDays));
			}
		}

		if (serviceEndDateReq.calendarAlignment == 'Calendar') {
			// for time period alignment Calendar make the service end date (SED) day the last day of the SED end month.
			Integer noOfDays = Date.daysInMonth(serviceEndDate.year(), serviceEndDate.month());
			serviceEndDate = serviceEndDate.addDays(noOfDays - serviceEndDate.day());
		}

		return serviceEndDate;
	}

	/**
	 * @param timePeriod time period unit
	 * @param startDate start date of time span
	 * @param endDate end date of time span
	 *
	 * @return number of period units calculated
	 */
	public static Integer numberOfPeriods(String timePeriod, Date startDate, Date endDate) {
		Integer numberOfPeriods;
		Decimal numOfPeriodFraction;
		switch on timePeriod {
			when 'Quarters' {
				numOfPeriodFraction = monthBasedPeriods(startDate, endDate);
				Decimal quarters = (numOfPeriodFraction / 3);
				numberOfPeriods = (Integer) Math.ceil(quarters);
			}
			when 'Months' {
				numberOfPeriods = monthBasedPeriods(startDate, endDate);
			}
			when 'Days' {
				numberOfPeriods = startDate.daysBetween(endDate);
			}
			when 'Weeks' {
				Decimal days = startDate.daysBetween(endDate);
				Decimal weeks = (days / 7);
				numberOfPeriods = (Integer) Math.ceil(weeks);
			}
		}

		return numberOfPeriods;
	}

	/**
	 * Calculates number of time period units for a task
	 * @param timePeriod time period unit
	 * @param itemDuration estimated hours for task
	 *
	 * @return time period units
	 */
	public static Decimal itemPeriodSpan(String timePeriod, Decimal itemDuration) {
		Decimal itemPeriodSpan;
		ScheduleSettingDTO scheduleSetting = UserDefinedPeriodService.scheduleSetting;
		switch on timePeriod {
			when 'Quarters' {
				itemPeriodSpan = (itemDuration / (scheduleSetting.standardMonthHours * 3)).setScale(2);
			}
			when 'Months' {
				itemPeriodSpan = (itemDuration / scheduleSetting.standardMonthHours).setScale(2);
			}
			when 'Days' {
				itemPeriodSpan = (itemDuration / scheduleSetting.standardDayHours).setScale(2);
			}
			when 'Weeks' {
				itemPeriodSpan = (itemDuration / scheduleSetting.standardWeekHours).setScale(2);
			}
		}

		return itemPeriodSpan;
	}

	/**
	 * Gets number of months from start to end date and rounds up to next whole number if left over fraction of month
	 * @param startDate start date of time span
	 * @param endDate end date of time span
	 *
	 * @return whole number of month based periods between dates
	 */
	private static Integer monthBasedPeriods(Date startDate, Date endDate) {
		Integer monthPeriods = startDate.monthsBetween(endDate);
		Integer minusMonths = monthPeriods * -1;
		Date dateMinusMonths = endDate.addMonths(minusMonths);
		Integer days = startDate.daysBetween(dateMinusMonths);
		if (days > 0) {
			monthPeriods = monthPeriods + 1;
		}

		return monthPeriods;
	}
}
