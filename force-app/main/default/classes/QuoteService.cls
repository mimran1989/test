/**
 *  Provus Services Quoting
 *  QuoteService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteService {
	// constants
	public static final String RECORDTYPE_NAME_COLLABORATION = 'Collaboration';
	public static final String RECORDTYPE_NAME_QUOTE = 'Quote';
	public static final String RECORDTYPE_NAME_SCENARIO = 'Scenario';
	public static final String RECORDTYPE_NAME_TEMPLATE = 'Template';

	public static final String STATUS_ACTIVE = 'Active';

	public static final String TIMEPERIOD_MONTHS = 'Months';
	public static final String TIMEPERIODSGROUPMETHOD_YEAR = 'Year';
	public static final String TIMEPERIODSALIGNMENT_CALENDAR = 'Calendar';

	// runtime context
	public Quote__c quoteSO;
	public Id rateCardId;
	public String quotePractice;
	public String quoteGroup;
	public Boolean isScenarioPricePending;
	public Boolean hasAddOns;
	public String currencyCode;
	public Decimal currencyConversionRatio;

	// constructor
	public QuoteService(Id quoteId) {
		Id addOnRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
			.get(ProductService.RECORDTYPE_NAME_ANCILLARY)
			.getRecordTypeId();

		QueryRequest queryQuoteItems = new QueryRequest(
			SystemUtility.getInverseRName(Schema.Quote__c.SObjectType, Schema.QuoteItem__c.SObjectType)
		);
		queryQuoteItems.requestedFields = new Set<String>{ SObjectUtility.FIELD_ID };

		queryQuoteItems.setFilterBy(
			new Map<String, String>{
				SystemUtility.getChildRName(
					Schema.QuoteItem__c.ProductId__c,
					Schema.Product2.RecordtypeId
				) => addOnRecordTypeId
			}
		);

		QueryRequest queryRequest = new QueryRequest(Quote__c.SObjectType);
		Set<String> requestedFields = new Set<String>{
			SObjectUtility.FIELD_ID,
			Schema.Quote__c.Type__c + '',
			Schema.Quote__c.Group__c + '',
			Schema.Quote__c.MarginPercent__c + '',
			Schema.Quote__c.Practice__c + '',
			Schema.Quote__c.SectionHierarchy__c + '',
			Schema.Quote__c.RateCardId__c + '',
			Schema.Quote__c.TimePeriod__c + '',
			Schema.Quote__c.TimePeriodsGroupMethod__c + '',
			Schema.Quote__c.TotalAmount__c + '',
			Schema.Quote__c.CurrencyConversionRatio__c + ''
		};

		if (MultiCurrencyService.isMultiCurrencyEnabled()) {
			requestedFields.add(MultiCurrencyService.CURRENCY_ISO_CODE);
		}

		queryRequest.requestedFields = requestedFields;
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => quoteId });
		queryRequest.innerQueries = new List<QueryRequest>{ queryQuoteItems };
		List<Quote__c> quotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);
		quoteSO = quotes[0];

		currencyConversionRatio = quoteSO.CurrencyConversionRatio__c;
		if (MultiCurrencyService.isMultiCurrencyEnabled()) {
			currencyCode = (String) quoteSO.get(MultiCurrencyService.CURRENCY_ISO_CODE);
		}
		rateCardId = quoteSO.RateCardId__c;
		quotePractice = quoteSO.Practice__c;
		quoteGroup = quoteSO.Group__c;
		isScenarioPricePending = RECORDTYPE_NAME_SCENARIO == quoteSO.Type__c;
		hasAddOns = quoteSO.QuoteItems__r.size() > 0;
	}

	public static Quote__c cloneQuote(Id sourceQuoteId, Set<Id> quoteSectionIds) {
		SObjectType quoteType = Schema.Quote__c.SObjectType;
		QueryRequest queryRequest = new QueryRequest(quoteType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(quoteType);
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => sourceQuoteId });
		List<Quote__c> sourceQuotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);

		Quote__c clonedQuote;
		if (sourceQuotes.size() > 0) {
			Quote__c sourceQuote = sourceQuotes[0];
			clonedQuote = sourceQuote.clone(false, true);
			clonedQuote.DerivedFromId__c = sourceQuote.Id;
			clonedQuote.TemplateId__c = null;
			clonedQuote.ServiceId__c = sourceQuote.ServiceId__c;

			CRUDUtility.insertRecords(clonedQuote);
			QuoteService.copyQuoteChildEntities(sourceQuote.Id, clonedQuote.Id, quoteSectionIds);
		}

		return clonedQuote;
	}

	public static Quote__c cloneQuote(Id sourceQuoteId) {
		return cloneQuote(sourceQuoteId, null);
	}

	/**
	 * @param quotes list of quotes
	 */
	public static void applyQuoteTemplateAfter(List<Quote__c> quotes) {
		Map<Id, Set<Id>> quotesByTemplateId = new Map<Id, Set<Id>>();

		// STEP I - Order the Quote Items by their Template Id
		for (Quote__c quote : quotes) {
			if (quote.TemplateId__c != null && quote.Type__c != RECORDTYPE_NAME_COLLABORATION) {
				Set<Id> quotesForTemplate = quotesByTemplateId.get(quote.TemplateId__c);
				if (quotesForTemplate == null) {
					quotesForTemplate = new Set<Id>();
					quotesByTemplateId.put(quote.TemplateId__c, quotesForTemplate);
				}

				quotesForTemplate.add(quote.Id);
			}
		}

		if (!quotesByTemplateId.isEmpty()) {
			copyQuoteChildEntities(quotesByTemplateId, null);
		}
	}

	public static void copyQuoteChildEntities(Id fromQuote, Id toQuote, Set<Id> quoteSectionIds) {
		copyQuoteChildEntities(
			new Map<Id, Set<Id>>{ fromQuote => new Set<Id>{ toQuote } },
			quoteSectionIds
		);
	}

	public static void copyQuoteChildEntities(
		Map<Id, Set<Id>> oldQuoteToNewQuotes,
		Set<Id> quoteSectionIds
	) {
		Map<Id, Map<Id, SObject>> mapQuoteSectionSO = copyQuoteSections(
			oldQuoteToNewQuotes,
			quoteSectionIds
		);

		Map<Id, Map<Id, SObject>> mapQuoteItemSO = copyQuoteItems(
			oldQuoteToNewQuotes,
			mapQuoteSectionSO,
			quoteSectionIds
		);

		Map<Id, Id> newItemIdBySourceItemId = new Map<Id, Id>();
		for (Map<Id, SObject> itemBySourceId : mapQuoteItemSO.values()) {
			for (Id sourceId : itemBySourceId.keySet()) {
				newItemIdBySourceItemId.put(sourceId, itemBySourceId.get(sourceId).Id);
			}
		}
		copyNamedRangeTotals(oldQuoteToNewQuotes, newItemIdBySourceItemId);

		AdjustmentService.AdjustmentCloneInfo adjCloneInfo = new AdjustmentService.AdjustmentCloneInfo(
			mapQuoteItemSO
		);
		Map<Id, Adjustment__c> adjustmentsToInsert = AdjustmentService.getAdjustmentsToInsert(
			adjCloneInfo
		);
		CRUDUtility.insertRecords(adjustmentsToInsert.values());

		AdjustmentService.updateAdjustmentIdOnQuoteItems(adjustmentsToInsert);
		List<QuoteItemCell__c> quoteItemCellsToInsert = AdjustmentService.getQuoteItemCellsToInsert(
			adjCloneInfo
		);
		CRUDUtility.insertRecords(quoteItemCellsToInsert);
	}

	private static Map<Id, Map<Id, SObject>> copyQuoteSections(
		Map<Id, Set<Id>> oldQuoteToNewQuotes,
		Set<Id> quoteSectionIds
	) {
		// TODO: Define a Setting for all applicable objects
		// STEP I - Clone the quote sections from the template to the new quote
		Map<Id, Map<Id, SObject>> newQuoteSections = SystemUtility.cloneChildEntities(
			Schema.QuoteSection__c.SObjectType,
			QuoteSectionService.RELATED_QUOTE_ID,
			oldQuoteToNewQuotes
		);

		List<QuoteSection__c> quoteSectionsToInsert = getQuoteSectionsToInsert(
			newQuoteSections,
			quoteSectionIds
		);

		CRUDUtility.insertRecords(quoteSectionsToInsert);

		return newQuoteSections;
	}

	private static List<QuoteSection__c> getQuoteSectionsToInsert(
		Map<Id, Map<Id, SObject>> newQuoteSections,
		Set<Id> quoteSectionIds
	) {
		List<QuoteSection__c> quoteSectionsToInsert = new List<QuoteSection__c>();
		for (Id targetQuoteId : newQuoteSections.keySet()) {
			for (Id sourceSectionId : newQuoteSections.get(targetQuoteId).keySet()) {
				QuoteSection__c targetSection = (QuoteSection__c) newQuoteSections.get(targetQuoteId)
					.get(sourceSectionId);
				targetSection.DerivedFromId__c = sourceSectionId;

				if (quoteSectionIds != null) {
					if (quoteSectionIds.contains(sourceSectionId)) {
						quoteSectionsToInsert.add(targetSection);
					}
				} else {
					quoteSectionsToInsert.add(targetSection);
				}
			}
		}
		return quoteSectionsToInsert;
	}

	private static Map<Id, Map<Id, SObject>> copyNamedRangeTotals(
		Map<Id, Set<Id>> oldQuoteToNewQuotes,
		Map<Id, Id> newItemIdBySourceItemId
	) {
		Map<Id, Map<Id, SObject>> namedRangeTotals = SystemUtility.cloneChildEntities(
			NamedRangeTotal__c.SObjectType,
			NamedRangeTotal.FIELD_NAME_QUOTE_ID,
			oldQuoteToNewQuotes
		);

		List<NamedRangeTotal__c> namedRangeTotalsToInsert = getNamedRangeTotalsToInsert(
			namedRangeTotals
		);
		CRUDUtility.insertRecords(namedRangeTotalsToInsert);

		List<NamedRange__c> namedRangesToInsert = copyNamedRanges(
			oldQuoteToNewQuotes,
			namedRangeTotals,
			newItemIdBySourceItemId
		);
		CRUDUtility.insertRecords(namedRangesToInsert);

		return namedRangeTotals;
	}

	private static List<NamedRangeTotal__c> getNamedRangeTotalsToInsert(
		Map<Id, Map<Id, SObject>> namedRangeTotals
	) {
		List<NamedRangeTotal__c> namedRangeTotalsToInsert = new List<NamedRangeTotal__c>();
		for (Map<Id, SObject> namedRangeTotalsByOldId : namedRangeTotals.values()) {
			namedRangeTotalsToInsert.addAll((List<NamedRangeTotal__c>) namedRangeTotalsByOldId.values());
		}
		return namedRangeTotalsToInsert;
	}

	private static List<NamedRange__c> copyNamedRanges(
		Map<Id, Set<Id>> oldQuoteToNewQuotes,
		Map<Id, Map<Id, SObject>> namedRangeTotals,
		Map<Id, Id> newItemIdBySourceItemId
	) {
		List<NamedRange__c> namedRangesToInsert = new List<NamedRange__c>();
		Map<Id, Map<Id, SObject>> namedRanges = SystemUtility.cloneChildEntities(
			NamedRange__c.SObjectType,
			Schema.NamedRange__c.QuoteId__c + '',
			oldQuoteToNewQuotes
		);

		if (namedRanges.size() > 0) {
			for (Id oldParentId : namedRanges.keySet()) {
				for (Id oldNamedRangeId : namedRanges.get(oldParentId).keySet()) {
					NamedRange__c namedRange = (NamedRange__c) namedRanges.get(oldParentId)
						.get(oldNamedRangeId);
					NamedRangeTotal__c namedRangeTotal = (NamedRangeTotal__c) namedRangeTotals.get(
							oldParentId
						)
						.get(namedRange.NamedRangeTotalId__c);

					namedRange.QuoteItemId__c = newItemIdBySourceItemId.get(namedRange.QuoteItemId__c);
					namedRange.NamedRangeTotalId__c = namedRangeTotal.Id;
					namedRangesToInsert.add(namedRange);
				}
			}
		}
		return namedRangesToInsert;
	}

	private static Map<Id, Map<Id, SObject>> copyQuoteItems(
		Map<Id, Set<Id>> oldQuoteToNewQuotes,
		Map<Id, Map<Id, SObject>> mapQuoteSectionSO,
		Set<Id> quoteSectionIds
	) {
		Map<String, Set<Id>> filterSetByFieldName = new Map<String, Set<Id>>{
			Schema.QuoteItem__c.QuoteId__c + '' => oldQuoteToNewQuotes.keySet()
		};

		if (quoteSectionIds != null && !quoteSectionIds.isEmpty()) {
			filterSetByFieldName.put(Schema.QuoteItem__c.QuoteSectionId__c + '', quoteSectionIds);
		}

		QueryRequest queryRequest = new QueryRequest(QuoteItem__c.SObjectType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(QuoteItem__c.SObjectType);
		queryRequest.setFilterBy(filterSetByFieldName);

		// STEP II - Clone the quote line items
		Map<Id, Map<Id, SObject>> newQuoteItems = SystemUtility.cloneChildEntities(
			SOQLUtility.querySObject(queryRequest),
			Schema.QuoteItem__c.QuoteId__c + '',
			oldQuoteToNewQuotes
		);

		for (Map<Id, SObject> clonedItemBySourceId : newQuoteItems.values()) {
			for (Id sourceId : clonedItemBySourceId.keySet()) {
				QuoteItem__c clonedItem = (QuoteItem__c) clonedItemBySourceId.get(sourceId);
				clonedItem.DerivedFromId__c = sourceId;
			}
		}

		List<QuoteItem__c> quoteItemsToInsert = getQuoteItemsToInsert(newQuoteItems, mapQuoteSectionSO);
		CRUDUtility.insertRecords(quoteItemsToInsert);

		return newQuoteItems;
	}

	private static List<QuoteItem__c> getQuoteItemsToInsert(
		Map<Id, Map<Id, SObject>> newQuoteItems,
		Map<Id, Map<Id, SObject>> newQuoteSections
	) {
		// STEP III - Update the quote section id
		Map<Id, Id> newSectionIdBySourceId = new Map<Id, Id>();
		for (Map<Id, SObject> quoteSectionsById : newQuoteSections.values()) {
			for (SObject sectionSO : quoteSectionsById.values()) {
				newSectionIdBySourceId.put(((QuoteSection__c) sectionSO).DerivedFromId__c, sectionSO.Id);
			}
		}
		List<QuoteItem__c> quoteItemsToInsert = new List<QuoteItem__c>();
		for (Map<Id, SObject> quoteItemsByOldId : newQuoteItems.values()) {
			for (Id oldItemId : quoteItemsByOldId.keySet()) {
				QuoteItem__c quoteItem = (QuoteItem__c) quoteItemsByOldId.get(oldItemId);
				quoteItem.QuoteSectionId__c = newSectionIdBySourceId.get(quoteItem.QuoteSectionId__c);
				quoteItemsToInsert.add(quoteItem);
			}
		}
		return quoteItemsToInsert;
	}
}
