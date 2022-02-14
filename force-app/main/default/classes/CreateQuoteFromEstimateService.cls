/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateQuoteFromEstimateService {
	//String Values
	private static final String STATUS_DRAFT = 'Draft';
	public static final String SKILL_LEVEL_FIELD = Schema.RateCardItem__c.SkillLevel__c + '';
	public static final String FIELD_NAME_LOCATION_DISPLAY_NAME =
		Schema.RateCardItem__c.LocationDisplayName__c + '';

	public class ResourceRoleDetail {
		@AuraEnabled
		public String resourceRoleName;
		@AuraEnabled
		public Map<String, List<String>> skillMap;
		@AuraEnabled
		public String defaultSkill;
		@AuraEnabled
		public String defaultLocation;
		@AuraEnabled
		public Integer sequence;

		public ResourceRoleDetail(RateCardItem__c rateCardItem) {
			resourceRoleName = rateCardItem.ProductId__r.Name;
			skillMap = new Map<String, List<String>>{
				rateCardItem.SkillLevel__c => new List<String>{ rateCardItem.LocationDisplayName__c }
			};
		}
	}

	public class ResourceRolePreferences {
		@AuraEnabled
		public String role;
		@AuraEnabled
		public String skillLevel;
		@AuraEnabled
		public String location;
	}

	public static QuoteDO getEstimateQuoteDetails(Estimate__c estimateSO) {
		QuoteDO quoteData = new QuoteDO();
		quoteData.isPrimary = true;
		quoteData.accountId = estimateSO.AccountId__c;
		quoteData.description = estimateSO.Description__c;
		quoteData.opportunityId = estimateSO.OpportunityId__c;
		quoteData.rateCardId = estimateSO.RateCardId__c;
		quoteData.estimateId = estimateSO.Id;
		quoteData.status = STATUS_DRAFT;
		quoteData.serviceId = estimateSO.ServiceId__c;
		quoteData.practice = estimateSO.ServiceId__r.Practice__c;
		quoteData.groupValue = estimateSO.ServiceId__r.Group__c;

		return quoteData;
	}

	public static void convertEntitiesFromEstimate(
		Quote__c quote,
		Map<Id, ResourceRolePreferences> prefsByRoleId
	) {
		createSections(quote, prefsByRoleId);

		NamedRangeTotal__c quoteNamedRangeTotal = new NamedRangeTotal__c();
		NamedRangeTotal__c quoteTotalNamedRangeTotal = new NamedRangeTotal__c();
		quoteNamedRangeTotal.QuoteId__c = quote.Id;
		quoteTotalNamedRangeTotal.QuoteId__c = quote.Id;
		CRUDUtility.insertRecords(
			new List<NamedRangeTotal__c>{ quoteNamedRangeTotal, quoteTotalNamedRangeTotal }
		);

		NamedRange__c quoteNamedRange = new NamedRange__c();
		quoteNamedRange.NamedRangeTotalId__c = quoteNamedRangeTotal.Id;
		quoteNamedRange.QuoteId__c = quote.Id;
		quoteNamedRange.Type__c = NamedRange.TYPE_QUOTE_LABOR;
		quoteNamedRange.Name = NamedRange.LABOR_AMOUNT_NAME;

		NamedRange__c quoteTotalNamedRange = new NamedRange__c();
		quoteTotalNamedRange.NamedRangeTotalId__c = quoteTotalNamedRangeTotal.Id;
		quoteTotalNamedRange.QuoteId__c = quote.Id;
		quoteTotalNamedRange.Type__c = NamedRange.TYPE_QUOTE;
		quoteTotalNamedRange.Name = NamedRange.QUOTE_TOTALS_NAME;

		CRUDUtility.insertRecords(new List<NamedRange__c>{ quoteNamedRange, quoteTotalNamedRange });
	}

	private static void createSections(
		Quote__c quoteSO,
		Map<Id, ResourceRolePreferences> prefsByRoleId
	) {
		List<ActivityGroup__c> groups = ActivityGroupService.getApplicableGroups(quoteSO.EstimateId__c);
		Set<Id> orderedRoleIds = getOrderedResourceRoles(quoteSO.EstimateId__c);

		List<QuoteSection__c> sections = new List<QuoteSection__c>();
		Map<String, Decimal> durationsBySectionRole = new Map<String, Decimal>();
		List<Set<Id>> groupRoleIds = new List<Set<Id>>();
		Integer sequence = 1;
		for (ActivityGroup__c grp : groups) {
			if (grp.RoleSummaries__r != null && grp.RoleSummaries__r.size() > 0) {
				QuoteSection__c section = new QuoteSection__c();
				section.Name = grp.Name;
				section.Sequence__c = grp.Sequence__c;
				section.QuoteId__c = quoteSO.Id;
				sections.add(section);
				sequence += 1;

				Set<Id> roleIds = new Set<Id>();
				for (TaskRoleSummary__c summary : grp.RoleSummaries__r) {
					String durationRoleKey = summary.ResourceRoleId__c + '-' + section.Sequence__c;
					durationsBySectionRole.put(durationRoleKey, summary.TotalEstimatedDuration__c);
					roleIds.add(summary.ResourceRoleId__c);
				}

				groupRoleIds.add(filterOrderedRoles(orderedRoleIds, roleIds));
			}
		}

		CRUDUtility.insertRecords(sections);

		List<QuoteItem__c> items = createQuoteItems(sections, groupRoleIds, prefsByRoleId);
		CRUDUtility.insertRecords(items);
		if (!items.isEmpty()) {
			createQuoteItemCells(quoteSO, items, durationsBySectionRole);
		}
	}

	private static Set<Id> filterOrderedRoles(Set<Id> orderedRoleIds, Set<Id> toFilter) {
		Set<Id> sortedApplicableRoleIds = new Set<Id>();
		for (Id roleId : orderedRoleIds) {
			if (toFilter.contains(roleId)) {
				sortedApplicableRoleIds.add(roleId);
			}
		}

		return sortedApplicableRoleIds;
	}

	private static List<QuoteItem__c> createQuoteItems(
		List<QuoteSection__c> sections,
		List<Set<Id>> groupRoleIds,
		Map<Id, ResourceRolePreferences> prefsByRoleId
	) {
		List<QuoteItem__c> items = new List<QuoteItem__c>();
		for (Integer i = 0; i < sections.size(); i++) {
			Set<Id> roleIds = groupRoleIds[i];
			QuoteSection__c section = sections[i];
			Integer sectionSequence = 1;
			for (Id roleId : roleIds) {
				ResourceRolePreferences pref = prefsByRoleId.get(roleId);
				QuoteItem__c item = new QuoteItem__c();
				item.QuoteId__c = section.QuoteId__c;
				item.QuoteSectionId__c = section.Id;
				item.Sequence__c = section.Sequence__c;
				item.SectionSequence__c = sectionSequence;
				item.ProductId__c = roleId;
				item.SkillLevel__c = pref?.skillLevel;
				item.LocationDisplayName__c = pref?.location;
				item.LocationCountry__c = pref?.location?.split('/')?.get(0);
				items.add(item);
				sectionSequence += 1;
			}
		}

		return items;
	}

	private static String durationRoleKey(QuoteItem__c quoteItem) {
		return quoteItem.ProductId__c + '-' + quoteItem.Sequence__c;
	}

	private static void createQuoteItemCells(
		Quote__c quoteSO,
		List<QuoteItem__c> quoteItems,
		Map<String, Decimal> durationByRole
	) {
		List<QuoteItemCell__c> itemCells = new List<QuoteItemCell__c>();
		Integer currentCellPos = 1;
		Id currentSection = quoteItems.get(0).QuoteSectionId__c;
		Integer numOfPeriods = DurationCalcs.numberOfPeriods(
			quoteSO.TimePeriod__c,
			quoteSO.ServiceStartDate__c,
			quoteSO.ServiceEndDate__c
		);
		Integer startCellPos = 1;

		for (QuoteItem__c quoteItemSO : quoteItems) {
			String durationRoleKey = durationRoleKey(quoteItemSO);
			Decimal itemDuration = durationByRole.get(durationRoleKey);

			if (currentSection != quoteItemSO.QuoteSectionId__c) {
				currentSection = quoteItemSO.QuoteSectionId__c;
				startCellPos = currentCellPos;
			}

			if (currentCellPos <= numOfPeriods) {
				// get number of time period units
				Decimal periodSpan = DurationCalcs.itemPeriodSpan(quoteSO.TimePeriod__c, itemDuration);
				QuoteItemCellService.QuoteItemCellResponse itemCellResp = QuoteItemCellService.createQuoteItemCell(
					periodSpan,
					quoteItemSO,
					startCellPos
				);

				itemCells.add(itemCellResp.quoteItemCell);

				if (itemCellResp.endCellPos > currentCellPos) {
					currentCellPos = Math.min(numOfPeriods, itemCellResp.endCellPos);
				}
			}
		}
		CRUDUtility.insertRecords(itemCells);
	}

	private static Set<Id> getOrderedResourceRoles(Id estimateId) {
		Set<Id> orderedResources = new Set<Id>();
		List<ActivityGroup__c> groups = [
			SELECT
				Id,
				(SELECT ResourceRoleId__c FROM Tasks__r ORDER BY Path__c),
				(SELECT ResourceRoleId__c FROM RoleSummaries__r)
			FROM ActivityGroup__c
			WHERE EstimateId__c = :estimateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c
		];

		for (ActivityGroup__c grp : groups) {
			for (Task__c task : grp.Tasks__r) {
				orderedResources.add(task.ResourceRoleId__c);
			}

			for (TaskRoleSummary__c summary : grp.RoleSummaries__r) {
				orderedResources.add(summary.ResourceRoleId__c);
			}
		}

		return orderedResources;
	}

	public static Map<String, ResourceRoleDetail> getResourceRoles(Id estimateId, Id rateCardId) {
		Map<String, ResourceRoleDetail> resourceRoleDetails = new Map<String, ResourceRoleDetail>();
		Set<Id> resourceRoleIds = getOrderedResourceRoles(estimateId);
		List<Id> orderedRoles = new List<Id>(resourceRoleIds); // allows indexOf vs a set

		List<RateCardItem__c> rateCardItems = RateCardItemService.getRateCardItems(
			rateCardId,
			resourceRoleIds
		);
		Map<String, ResourceDefault__c> resourceByProductAttribute = getResourceDefaults(estimateId);

		for (RateCardItem__c rateCardItem : rateCardItems) {
			if (!resourceRoleDetails.containsKey(rateCardItem.ProductId__c)) {
				ResourceRoleDetail roleStruct = new ResourceRoleDetail(rateCardItem);
				roleStruct.defaultSkill = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + SKILL_LEVEL_FIELD
					)
					?.TextValue__c;

				roleStruct.defaultLocation = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + FIELD_NAME_LOCATION_DISPLAY_NAME
					)
					?.TextValue__c;

				roleStruct.sequence = orderedRoles.indexOf(rateCardItem.ProductId__c);
				resourceRoleDetails.put(rateCardItem.ProductId__c, roleStruct);
			} else {
				ResourceRoleDetail roleStruct = resourceRoleDetails.get(rateCardItem.ProductId__c);
				if (!roleStruct.skillMap.containsKey(rateCardItem.SkillLevel__c)) {
					roleStruct.skillMap.put(
						rateCardItem.SkillLevel__c,
						new List<String>{ rateCardItem.LocationDisplayName__c }
					);
				} else {
					roleStruct.skillMap.get(rateCardItem.SkillLevel__c)
						.add(rateCardItem.LocationDisplayName__c);
				}
			}
		}

		return resourceRoleDetails;
	}

	private static Map<String, ResourceDefault__c> getResourceDefaults(Id estimateId) {
		Map<String, ResourceDefault__c> resourceByProductAttribute = new Map<String, ResourceDefault__c>();
		for (ResourceDefault__c resourceDefault : [
			SELECT Id, FieldAPIName__c, TextValue__c, ProductId__c, EstimateId__c
			FROM ResourceDefault__c
			WHERE EstimateId__c = :estimateId
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		]) {
			resourceByProductAttribute.put(
				resourceDefault.ProductId__c + resourceDefault.FieldAPIName__c,
				resourceDefault
			);
		}

		return resourceByProductAttribute;
	}
}
