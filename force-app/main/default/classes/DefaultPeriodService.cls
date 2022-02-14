public with sharing class DefaultPeriodService implements QuotePeriodService.IPeriodService {
	public static ScheduleSettingDTO scheduleSetting;
	static {
		scheduleSetting = SettingsService.getScheduleSettings();
	}

	public Map<QuotePeriodGroup__c, List<QuotePeriod__c>> generatePeriods(Quote__c quoteSO) {
		Id quoteId = quoteSO.Id;
		Date serviceStart = quoteSO.ServiceStartDate__c;
		Date serviceEnd = quoteSO.ServiceEndDate__c;
		String timePeriod = quoteSO.TimePeriod__c;
		String timePeriodAlignment = quoteSO.TimePeriodsAlignment__c;
		String timePeriodGroupMethod = quoteSO.TimePeriodsGroupMethod__c;
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroup = new Map<QuotePeriodGroup__c, List<QuotePeriod__c>>();
		ITimePeriod timePeriodCalc = TimePeriodFactory.newTimePeriod(timePeriod);
		ITimePeriod periodGroupCalc = TimePeriodFactory.newTimePeriod(timePeriodGroupMethod);

		// can't generate periods when they're not specified
		if (timePeriodCalc == null || periodGroupCalc == null) {
			return periodsByGroup;
		}

		Date groupStartDate = serviceStart;
		Date groupEndDate = periodGroupCalc.calculateGroupEndDate(
			groupStartDate,
			serviceEnd,
			timePeriodAlignment
		);

		Date periodStartDate = serviceStart;
		Date periodEndDate = timePeriodCalc.calculateEndDate(
			periodStartDate,
			serviceEnd,
			timePeriodAlignment
		);

		Integer groupSequence = 1;
		Integer periodSequence = 1;
		while (groupStartDate < serviceEnd) {
			QuotePeriodGroup__c groups = new QuotePeriodGroup__c();
			groups.QuoteId__c = quoteId;
			groups.Sequence__c = groupSequence;
			groups.Name = timePeriodGroupMethod + ' ' + groupSequence;
			groupSequence += 1;

			List<QuotePeriod__c> periods = new List<QuotePeriod__c>();
			while (periodStartDate <= groupEndDate) {
				if (periodSequence > QuotePeriodService.MAX_PERIOD_COUNT) {
					throw new ApplicationException(
						'Currently maximum of ' +
						String.valueOf(QuotePeriodService.MAX_PERIOD_COUNT) +
						' periods is supported.'
					);
				}

				QuotePeriod__c period = new QuotePeriod__c(
					Name = timePeriodCalc.generateName(periodStartDate, periodEndDate, periodSequence),
					QuoteId__c = quoteId,
					Sequence__c = periodSequence,
					StartDate__c = periodStartDate,
					EndDate__c = periodEndDate,
					Term__c = timePeriodCalc.calculateTerm(periodStartDate, periodEndDate)
				);

				periodSequence += 1;
				periods.add(period);

				periodStartDate = periodEndDate.addDays(1);
				periodEndDate = timePeriodCalc.calculateEndDate(periodStartDate, serviceEnd, null);
			}

			periodsByGroup.put(groups, periods);

			groupStartDate = groupEndDate.addDays(1);
			groupEndDate = periodGroupCalc.calculateGroupEndDate(
				groupStartDate,
				serviceEnd,
				timePeriodAlignment
			);
		}
		return periodsByGroup;
	}
}
