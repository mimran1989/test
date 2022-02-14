/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteSummaryService {
	public static List<QuoteSummaryDO> getQuoteSummaries(Id quoteId) {
		Map<String, QuoteSummaryDO> summariesByRangeName = generateSummaryDOs(quoteId);

		Map<String, QuoteSummaryDO> mapTotals = generateTotals(summariesByRangeName);
		setPercentageOfTotalFields(mapTotals, summariesByRangeName);
		for (String key : mapTotals.keySet()) {
			summariesByRangeName.put(key, mapTotals.get(key));
		}

		List<QuoteSummaryDO> summaries = summariesByRangeName.values();
		summaries.sort();
		return summaries;
	}

	private static Map<String, QuoteSummaryDO> generateSummaryDOs(Id quoteId) {
		Map<String, QuoteSummaryDO> summariesByRangeName = new Map<String, QuoteSummaryDO>();
		for (NamedRange__c namedRangeSO : NamedRangeService.getNamedRangesForSummaries(quoteId)) {
			String rangeType = getRangeType(namedRangeSO);
			String rangeName = getRangeName(namedRangeSO);

			if (rangeName == null) {
				continue;
			}

			createSummary(summariesByRangeName, namedRangeSO);

			if (rangeType == QuoteSummary.SUMMARYTYPE_ROLE) {
				createOverrideSummary(summariesByRangeName, namedRangeSO);
			}
		}

		return summariesByRangeName;
	}

	private static void createSummary(
		Map<String, QuoteSummaryDO> summariesByRangeName,
		NamedRange__c namedRangeSO
	) {
		String rangeType = getRangeType(namedRangeSO);
		String rangeName = getRangeName(namedRangeSO);
		QuoteSummaryDO summary = summariesByRangeName.get(rangeName);
		if (summary == null) {
			QuoteSummaryDO quoteStruct = new QuoteSummaryDO(rangeType, rangeName);
			quoteStruct.setSummary(namedRangeSO);
			summariesByRangeName.put(rangeName, quoteStruct);
		} else {
			summary.addToSummary(namedRangeSO);
		}
	}

	private static void createOverrideSummary(
		Map<String, QuoteSummaryDO> summariesByRangeName,
		NamedRange__c namedRangeSO
	) {
		String rangeName = getRangeName(namedRangeSO);
		String overrideName = namedRangeSO.Type__c == ProjectPhaseService.NRTYPE_QUOTE_ITEM
			? namedRangeSO.QuoteItemId__r.RoleNameOverride__c
			: null;
		String overrideSummaryName = overrideName != null ? overrideName : rangeName;
		QuoteSummaryDO overrideSummary = summariesByRangeName.get('override_' + overrideSummaryName);

		if (overrideSummary == null) {
			QuoteSummaryDO newSummary = new QuoteSummaryDO(
				QuoteSummary.SUMMARYTYPE_ROLE_OVERRIDE,
				overrideSummaryName
			);
			newSummary.setSummary(namedRangeSO);
			summariesByRangeName.put('override_' + overrideSummaryName, newSummary);
		} else {
			overrideSummary.addToSummary(namedRangeSO);
		}
	}

	private static String getRangeType(NamedRange__c range) {
		if (range.Type__c == ProjectPhaseService.NRTYPE_QUOTE_ITEM) {
			return QuoteSummary.SUMMARYTYPE_ROLE;
		} else if (range.Type__c == ProjectPhaseService.NRTYPE_QUOTE_PERIOD_GROUP) {
			return QuoteSummary.SUMMARYTYPE_PERIOD_GROUP;
		} else if (range.Type__c == ProjectPhaseService.NRTYPE_PROJECT_PHASE) {
			return QuoteSummary.SUMMARYTYPE_PROJECT_PHASE;
		}

		return null;
	}

	private static String getRangeName(NamedRange__c range) {
		if (range.Type__c == ProjectPhaseService.NRTYPE_QUOTE_ITEM) {
			return range.QuoteItemId__r.ProductId__r.Name;
		} else if (range.Type__c == ProjectPhaseService.NRTYPE_QUOTE_PERIOD_GROUP) {
			return range.QuotePeriodGroupId__r.Name;
		} else if (range.Type__c == ProjectPhaseService.NRTYPE_PROJECT_PHASE) {
			return range.ProjectPhaseId__r.Name;
		}

		return null;
	}

	private static Map<String, QuoteSummaryDO> generateTotals(
		Map<String, QuoteSummaryDO> mapQuoteStruct
	) {
		Map<String, QuoteSummaryDO> mapTotals = new Map<String, QuoteSummaryDO>();
		for (QuoteSummaryDO summaryDO : mapQuoteStruct.values()) {
			String summaryType;
			String summaryName;
			if (summaryDO.type == QuoteSummary.SUMMARYTYPE_ROLE) {
				summaryType = QuoteSummary.SUMMARYTYPE_RESOURCE_TOTALS;
				summaryName = System.Label.ResourceRoleTotals;
			} else if (summaryDO.type == QuoteSummary.SUMMARYTYPE_PROJECT_PHASE) {
				summaryType = QuoteSummary.SUMMARYTYPE_PROJECT_PHASE_TOTALS;
				summaryName = System.Label.ProjectPhaseTotals;
			} else if (summaryDO.type == QuoteSummary.SUMMARYTYPE_PERIOD_GROUP) {
				summaryType = QuoteSummary.SUMMARYTYPE_PERIOD_GROUP_TOTALS;
				summaryName = System.Label.PeriodGroupTotals;
			} else if (summaryDO.type == QuoteSummary.SUMMARYTYPE_ROLE_OVERRIDE) {
				summaryType = QuoteSummary.SUMMARYTYPE_RESOURCE_OVERRIDE_TOTALS;
				summaryName = System.Label.ResourceRoleTotals;
			}

			if (summaryName == null) {
				continue;
			}

			if (!mapTotals.containsKey(summaryType)) {
				QuoteSummaryDO quoteStructTotal = new QuoteSummaryDO(summaryType, summaryName);
				quoteStructTotal.setSummary(summaryDO);
				mapTotals.put(summaryType, quoteStructTotal);
			} else {
				mapTotals.get(summaryType).addToSummary(summaryDO);
			}
		}
		return mapTotals;
	}

	private static void setPercentageOfTotalFields(
		Map<String, QuoteSummaryDO> mapTotals,
		Map<String, QuoteSummaryDO> mapQuoteStruct
	) {
		Map<String, QuoteSummaryDO> totalsByType = new Map<String, QuoteSummaryDO>();
		for (QuoteSummaryDO totals : mapTotals.values()) {
			totalsByType.put(totals.type, totals);
		}

		for (QuoteSummaryDO summary : mapQuoteStruct.values()) {
			QuoteSummaryDO totals;
			if (summary.type == QuoteSummary.SUMMARYTYPE_ROLE) {
				totals = totalsByType.get(QuoteSummary.SUMMARYTYPE_RESOURCE_TOTALS);
			} else if (summary.type == QuoteSummary.SUMMARYTYPE_PERIOD_GROUP) {
				totals = totalsByType.get(QuoteSummary.SUMMARYTYPE_PERIOD_GROUP_TOTALS);
			} else if (summary.type == QuoteSummary.SUMMARYTYPE_PROJECT_PHASE) {
				totals = totalsByType.get(QuoteSummary.SUMMARYTYPE_PROJECT_PHASE_TOTALS);
			} else if (summary.type == QuoteSummary.SUMMARYTYPE_ROLE_OVERRIDE) {
				totals = totalsByType.get(QuoteSummary.SUMMARYTYPE_RESOURCE_OVERRIDE_TOTALS);
			}

			if (totals != null) {
				summary.calculatePercentages(totals);
			}
		}
	}
}
