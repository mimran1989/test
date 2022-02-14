public with sharing class UserDefinedPeriodService implements QuotePeriodService.IPeriodService {
	public static ScheduleSettingDTO scheduleSetting;
	static {
		scheduleSetting = SettingsService.getScheduleSettings();
	}

	public Map<QuotePeriodGroup__c, List<QuotePeriod__c>> generatePeriods(Quote__c quoteSO) {
		Id quoteId = quoteSO.Id;
		Date serviceStart = quoteSO.ServiceStartDate__c;
		Date serviceEnd = quoteSO.ServiceEndDate__c;
		String timePeriod = quoteSO.TimePeriod__c;
		String timePeriodGroupMethod = quoteSO.TimePeriodsGroupMethod__c;
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroupMap = new Map<QuotePeriodGroup__c, List<QuotePeriod__c>>();

		Date groupStartDate = serviceStart;
		Integer groupTotalCount = calculateGroupCount(
			groupStartDate,
			timePeriodGroupMethod,
			serviceEnd
		);
		Integer periodCountPerGroup = calculatePeriodCountPerGroup(timePeriodGroupMethod, timePeriod);
		Integer totalPeriodCount = calculateTotalPeriodCount(groupStartDate, timePeriod, serviceEnd);
		Date periodStartDate = serviceStart;
		Date periodEndDate = calculatePeriodEndDate(periodStartDate, serviceEnd, timePeriod);
		Integer periodCount = 0;
		for (Integer groupCount = 1; groupCount <= groupTotalCount; groupCount++) {
			QuotePeriodGroup__c qpg = new QuotePeriodGroup__c();
			qpg.QuoteId__c = quoteId;
			qpg.Sequence__c = groupCount;
			qpg.Name = timePeriodGroupMethod + ' ' + String.valueOf(groupCount);
			Integer currentPeriodCount = 0;
			List<QuotePeriod__c> qpList = new List<QuotePeriod__c>();
			while (
				currentPeriodCount < periodCountPerGroup &&
				periodStartDate <= periodEndDate &&
				periodCount <= totalPeriodCount
			) {
				periodCount++;
				currentPeriodCount++;
				if (periodCount > QuotePeriodService.MAX_PERIOD_COUNT) {
					throw new ApplicationException(
						'Currently maximum of ' +
						String.valueOf(QuotePeriodService.MAX_PERIOD_COUNT) +
						' periods is supported.'
					);
				}

				QuotePeriod__c qp = new QuotePeriod__c();
				qp.Name = getPeriodName(periodStartDate, periodEndDate, periodCount, timePeriod);
				qp.QuoteId__c = quoteId;
				qp.Sequence__c = periodCount;
				qp.StartDate__c = periodStartDate;
				qp.EndDate__c = periodEndDate;
				qp.Term__c = calculatePeriodTerm(periodStartDate, periodEndDate, timePeriod);

				qpList.add(qp);

				periodStartDate = periodEndDate.addDays(1);
				periodEndDate = calculatePeriodEndDate(periodStartDate, serviceEnd, timePeriod);
			}

			periodsByGroupMap.put(qpg, qpList);

			groupStartDate = periodEndDate.addDays(1);
		}
		return periodsByGroupMap;
	}

	public Integer calculateGroupCount(Date startDate, String method, Date serviceEndDate) {
		Decimal numOfMonths = calculateMonths(startDate, serviceEndDate);

		Decimal noOfGroups;
		if (method == QuotePeriodService.TIME_PERIODS_GROUP_YEAR) {
			noOfGroups = numOfMonths / 12;
		} else if (method == QuotePeriodService.TIME_PERIODS_GROUP_QUARTER) {
			noOfGroups = numOfMonths / 3;
		} else if (method == QuotePeriodService.TIME_PERIODS_GROUP_MONTH) {
			noOfGroups = numOfMonths;
		} else if (method == QuotePeriodService.TIME_PERIODS_GROUP_WEEK) {
			noOfGroups = numOfMonths * 4;
		}

		return Integer.valueOf(Math.ceil(noOfGroups));
	}

	public Integer calculateTotalPeriodCount(
		Date startDate,
		String periodMethod,
		Date serviceEndDate
	) {
		Decimal numOfMonths = calculateMonths(startDate, serviceEndDate);

		Decimal noOfPeriodCount;
		if (periodMethod == QuotePeriodService.TIME_PERIODS_MONTHS) {
			noOfPeriodCount = numOfMonths;
		} else if (periodMethod == QuotePeriodService.TIME_PERIODS_QUARTERS) {
			noOfPeriodCount = numOfMonths / 3;
		} else if (periodMethod == QuotePeriodService.TIME_PERIODS_WEEKS) {
			noOfPeriodCount =
				numOfMonths *
				scheduleSetting.standardMonthHours /
				scheduleSetting.standardWeekHours;
		} else if (periodMethod == QuotePeriodService.TIME_PERIODS_DAYS) {
			noOfPeriodCount =
				numOfMonths *
				scheduleSetting.standardMonthHours /
				scheduleSetting.standardDayHours;
		}

		return Integer.valueOf(Math.ceil(noOfPeriodCount));
	}

	public Integer calculatePeriodCountPerGroup(string groupMethod, string periodMethod) {
		Decimal noOfPeriodsPerGroup;
		Decimal groupHours = 0;
		Decimal periodHours = 0;
		switch on groupMethod {
			when 'Year' {
				groupHours = scheduleSetting.standardYearHours;
			}
			when 'Quarter' {
				groupHours = scheduleSetting.standardMonthHours * 3;
			}
			when 'Month' {
				groupHours = scheduleSetting.standardMonthHours;
			}
			when 'Week' {
				groupHours = scheduleSetting.standardWeekHours;
			}
		}

		switch on periodMethod {
			when 'Years' {
				periodHours = scheduleSetting.standardYearHours;
			}
			when 'Months' {
				periodHours = scheduleSetting.standardMonthHours;
			}
			when 'Weeks' {
				periodHours = scheduleSetting.standardWeekHours;
			}
			when 'Days' {
				periodHours = scheduleSetting.standardDayHours;
			}
		}

		noOfPeriodsPerGroup = groupHours / periodHours;
		return Integer.valueOf(Math.ceil(noOfPeriodsPerGroup));
	}

	public Date calculatePeriodEndDate(Date startDate, Date serviceEndDate, String periodType) {
		Date endDate;

		switch on periodType {
			when 'Months' {
				endDate = startDate.toStartOfMonth().addMonths(1).addDays(-1);
			}
			when 'Days' {
				endDate = startDate.addDays(1).addDays(-1);
			}
			when 'Weeks' {
				endDate = startDate.toStartOfWeek().addDays(7).addDays(-1);
			}
			when 'Quarters' {
				endDate = startDate.toStartOfMonth().addMonths(3).addDays(-1);
			}
		}

		if (endDate > serviceEndDate) {
			endDate = serviceEndDate;
		}

		return endDate;
	}

	public Decimal calculatePeriodTerm(Date startDate, Date endDate, String frequency) {
		Decimal periodTerm;
		Decimal noOfMonths = calculateMonths(startDate, endDate);
		switch on frequency {
			when 'Months' {
				periodTerm = noOfMonths;
			}
			when 'Days' {
				periodTerm = 1.00;
			}
			when 'Weeks' {
				periodTerm =
					(noOfMonths * scheduleSetting.standardMonthHours) / scheduleSetting.standardWeekHours;
			}
			when 'Quarters' {
				periodTerm =
					(noOfMonths * scheduleSetting.standardMonthHours) /
					(scheduleSetting.standardMonthHours * 3);
			}
		}

		return periodTerm;
	}

	public String getPeriodName(
		Date periodStartDate,
		Date periodEndDate,
		Integer periodCount,
		String timePeriod
	) {
		Time startTime = Time.newInstance(0, 0, 1, 0);
		Time endTime = Time.newInstance(24, 59, 59, 0);

		Datetime periodStart = Datetime.newInstance(periodStartDate, startTime);
		Datetime periodEnd = Datetime.newInstance(periodEndDate, endTime);

		String periodName;

		switch on timePeriod {
			when 'Months' {
				if (periodStart.year() != periodEnd.year() || periodStart.month() != periodEnd.month()) {
					periodName =
						periodStart.format('MMM') +
						'/' +
						periodStart.format('YYYY') +
						' to ' +
						periodEnd.format('MMM') +
						'/' +
						periodEnd.format('YYYY');
				} else {
					periodName = periodStart.format('MMM') + '/' + periodStart.format('YYYY');
				}
			}
			when 'Days' {
				periodName = 'Day ' + String.valueOf(periodCount);
			}
			when 'Weeks' {
				periodName = 'Week ' + String.valueOf(periodCount);
			}
			when 'Quaters' {
				periodName = 'Quarter ' + String.valueOf(periodCount);
			}
		}

		return periodName;
	}

	public Decimal calculateMonths(Date startDate, Date endDate) {
		Decimal noOfMonths;
		if (startDate.month() != endDate.month() || startDate.year() != endDate.year()) {
			Decimal termPart1 =
				(Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())) -
				Decimal.valueOf(startDate.day()) +
				1.00) / (Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())));
			Decimal termPart2 =
				(Decimal.valueOf(endDate.day())) /
				(Decimal.valueOf(Date.daysInMonth(endDate.year(), endDate.month())));
			Decimal termPart3 = Decimal.valueOf(startDate.monthsBetween(endDate)) - 1.00;
			noOfMonths = termPart1 + termPart2 + termPart3;
		} else {
			noOfMonths =
				(Decimal.valueOf(endDate.day()) - Decimal.valueOf(startDate.day()) + 1.00) /
				(Decimal.valueOf(Date.daysInMonth(startDate.year(), startDate.month())));
		}

		return noOfMonths;
	}
}
