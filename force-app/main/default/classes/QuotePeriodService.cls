/**
 *  Provus Services Quoting
 *  QuotePeriodService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuotePeriodService {
	// constants
	public static final String SOBJECT_NAME = 'QuotePeriod__c';
	public static final Integer MAX_PERIOD_COUNT = 468;
	public static final String TIME_PERIODS_ALIGNMENT_USER_DEFINED_CALENDAR = 'User Defined Calendar';
	public static final String TIME_PERIODS_ALIGNMENT_CALENDAR = 'Calendar';
	public static final String TIME_PERIODS_ALIGNMENT_SERVICE_START = 'Service Start';

	public static final String TIME_PERIODS_MONTHS = 'Months';
	public static final String TIME_PERIODS_DAYS = 'Days';
	public static final String TIME_PERIODS_WEEKS = 'Weeks';
	public static final String TIME_PERIODS_YEARS = 'Years';
	public static final String TIME_PERIODS_QUARTERS = 'Quarters';

	public static final String TIME_PERIODS_GROUP_MONTH = 'Month';
	public static final String TIME_PERIODS_GROUP_WEEK = 'Week';
	public static final String TIME_PERIODS_GROUP_QUARTER = 'Quarter';
	public static final String TIME_PERIODS_GROUP_YEAR = 'Year';

	/**
	 * Wrapper class which holds quote periods
	 */
	public class QuotePeriod {
		public Id id;
		public String name;
		public Date startDate;
		public Date endDate;
		public Decimal sequence;
		public Decimal term;
		public String periodGroupName;
		public Id periodGroupId;

		public Id projectPhaseId;
		public String projectPhaseName;
	}

	/** Gets the quote periods for a given quote
	 * @param   quoteId Id of the quote
	 * @return  List<QuotePeriod>
	 */
	public static List<QuotePeriod> getQuotePeriods(Id quoteId) {
		List<QuotePeriodService.QuotePeriod> quotePeriods = new List<QuotePeriodService.QuotePeriod>();

		for (QuotePeriodGroup__c periodGroup : [
			SELECT
				Id,
				Name,
				QuoteId__c,
				QuotePeriodGroupId__c,
				Sequence__c,
				(
					SELECT
						Id,
						Name,
						EndDate__c,
						ProjectPhaseId__c,
						ProjectPhaseId__r.Name,
						QuoteId__c,
						QuotePeriodGroupId__c,
						Sequence__c,
						StartDate__c,
						Term__c
					FROM QuotePeriods__r
					ORDER BY Sequence__c ASC
				)
			FROM QuotePeriodGroup__c
			WHERE QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		]) {
			for (QuotePeriod__c period : periodGroup.QuotePeriods__r) {
				QuotePeriodService.QuotePeriod periodStruct = new QuotePeriodService.QuotePeriod();

				periodStruct.id = period.Id;
				periodStruct.name = period.Name;
				periodStruct.startDate = period.StartDate__c;
				periodStruct.endDate = period.EndDate__c;
				periodStruct.sequence = period.Sequence__c;
				periodStruct.term = period.Term__c;
				periodStruct.periodGroupName = periodGroup.Name;
				periodStruct.periodGroupId = periodGroup.Id;

				periodStruct.projectPhaseId = period.ProjectPhaseId__c;
				periodStruct.projectPhaseName = period.ProjectPhaseId__r.Name;

				quotePeriods.add(periodStruct);
			}
		}

		return quotePeriods;
	}

	public static void createPeriodsAndPeriodGroupsFor(List<Quote__c> quoteList) {
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroupMap = new Map<QuotePeriodGroup__c, List<QuotePeriod__c>>();
		for (Quote__c quoteSO : quoteList) {
			// check for validity of dates
			if (quoteSO.ServiceStartDate__c >= quoteSO.ServiceEndDate__c) {
				quoteSO.addError(Label.QuoteServiceDateRangeError);
				quoteSO.ServiceStartDate__c.addError('');
				quoteSO.ServiceEndDate__c.addError('');
			}

			IPeriodService periodService;
			if (quoteSO.TimePeriodsAlignment__c == TIME_PERIODS_ALIGNMENT_USER_DEFINED_CALENDAR) {
				periodService = new UserDefinedPeriodService();
			} else {
				periodService = new DefaultPeriodService();
			}

			periodsByGroupMap.putAll(periodService.generatePeriods(quoteSO));
		}

		insertGroupsAndPeriods(periodsByGroupMap);
	}

	public static void insertGroupsAndPeriods(
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> periodsByGroupMap
	) {
		if (periodsByGroupMap.size() > 0) {
			Map<Integer, QuotePeriodGroup__c> qpgMap = new Map<Integer, QuotePeriodGroup__c>();
			Map<Integer, List<QuotePeriod__c>> qpListMap = new Map<Integer, List<QuotePeriod__c>>();

			Integer count = 1;
			for (QuotePeriodGroup__c qpg : periodsByGroupMap.keySet()) {
				qpgMap.put(count, qpg);
				qpListMap.put(count, periodsByGroupMap.get(qpg));
				count++;
			}
			List<QuotePeriodGroup__c> qpgList = qpgMap.values();
			SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, qpgList);
			Database.insert(qpgList);

			List<QuotePeriod__c> periodList = new List<QuotePeriod__c>();
			for (Integer cnt : qpgMap.keySet()) {
				for (QuotePeriod__c qp : qpListMap.get(cnt)) {
					qp.QuotePeriodGroupId__c = qpgMap.get(cnt).Id;
				}
				periodList.addAll(qpListMap.get(cnt));
			}
			if (periodList.size() > 0) {
				decision = Security.stripInaccessible(AccessType.CREATABLE, periodList);
				Database.insert(periodList);
			}
		}
	}

	public interface IPeriodService {
		Map<QuotePeriodGroup__c, List<QuotePeriod__c>> generatePeriods(Quote__c quoteSO);
	}
}
