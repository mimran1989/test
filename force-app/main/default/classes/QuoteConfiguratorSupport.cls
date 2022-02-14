/**
 *  Provus Services Quoting
 *  QuoteConfiguratorSupport
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteConfiguratorSupport {
	/** Gets the quote template for initializing the quote configurator
	 * @param   quoteId Id of the quote
	 * @return  QuoteTemplateDO
	 */
	public static QuoteTemplateDO getQuoteTemplate(Id quoteId) {
		QuoteService qtService = new QuoteService(quoteId);
		return new QuoteTemplateDO(qtService.quoteSO, qtService.rateCardId);
	}

	public static List<QuoteSummaryDO> getQuoteSummaries(Id quoteId) {
		return QuoteSummaryService.getQuoteSummaries(quoteId);
	}

	/**
	 * Gets all valid products for a quote
	 * @param   quoteId Id of the quote
	 * @return  Set<ProductService.ProductStruct>
	 */
	public static Set<ProductService.ProductStruct> getAllProductsForQuote(Id quoteId) {
		return ProductService.getAllProductsForQuote(quoteId);
	}

	/**
	 * Gets all rate card items for a product
	 * @param   quoteId Id of the quote
	 * @param   productId Id of the product
	 * @return  List<RateCardItemService.RateCardItemStruct>
	 */
	public static List<RateCardItemService.RateCardItemStruct> getAllRateCardItemsForProduct(
		Id quoteId,
		Id productId
	) {
		return RateCardItemService.getAllRateCardItemsForProduct(quoteId, productId);
	}

	/**
	 * Gets all quote items for quote
	 * @param   quoteId Id of the quote
	 * @return  List<QuoteItemDO>
	 */
	public static List<QuoteItemDTO> getQuoteItemsForQuote(Id quoteId) {
		return QuoteItemService.getQuoteItemsForQuote(quoteId);
	}

	/**
	 * Commit quote items for quote
	 * @param   quoteId Id of the quote
	 * @param   quoteItemsColData JSON String of the quote item struct collection
	 * @return  Boolean the result of commit
	 */
	public static List<QuoteItemDTO> commitQuoteItems(
		Id quoteId,
		List<QuoteItemDTO> quoteItemsColData
	) {
		return QuoteItemService.commitQuoteItems(quoteId, quoteItemsColData);
	}

	/**
	 * Gets all namedranges for a quote
	 * @param   quoteId Id of the quote
	 * @return  List<NamedRange.NamedRangeDO>
	 */
	public static List<NamedRange.NamedRangeDO> getNamedRangesForQuote(Id quoteId) {
		return NamedRangeService.getNamedRangesForQuote(quoteId);
	}

	/**
	 * @param namedRangeColData named range col data
	 *
	 * @return boolean indicating whether method executed successfully
	 */
	public static Boolean commitNamedRanges(String namedRangeColData) {
		return NamedRangeService.commitNamedRanges(namedRangeColData);
	}

	/**
	 * get project phases for a quote
	 * @param   quoteId Id of the quote
	 * @return  List<ProjectPhaseDO>
	 */
	public static List<ProjectPhaseDO> getProjectPhasesForQuote(Id quoteId) {
		return ProjectPhaseService.getProjectPhasesForQuote(quoteId);
	}

	/**
	 * commit project phases for a quote
	 *
	 * @param projectPhaseColData JSON string of project phase col data
	 *
	 * @return boolean indicating whether method executed sucessfully
	 */
	public static Boolean commitProjectPhases(String projectPhaseColData) {
		return ProjectPhaseService.commitProjectPhases(projectPhaseColData);
	}

	/**
	 * get quote sections for a quote
	 * @param   quoteId Id of the quote
	 * @return  List<QuoteSectionDO>
	 */
	public static List<QuoteSectionDO> getQuoteSectionsForQuote(Id quoteId) {
		return QuoteSectionService.getQuoteSectionsForQuote(quoteId);
	}

	/**
	 * commit quote sections for a quote
	 *
	 * @param quoteId Id of the quote
	 * @param quoteSectionColData JSON string containing quote sections wrappers
	 *
	 * @return Boolean the result of commit
	 */
	public static Boolean commitQuoteSections(Id quoteId, String quoteSectionColData) {
		return QuoteSectionService.commitQuoteSections(quoteId, quoteSectionColData);
	}

	/**
	 * retrieve related opportunity line item and sync it with the quote items
	 * @param   quoteId Id of the quote
	 */
	public static void syncQuoteToOpportunity(Id quoteId) {
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = ServiceRecommendationsSupport.getOpportunityProductServiceQuotes(
			new Map<String, String>{
				Schema.OpportunityProductServiceQuote__c.ServiceQuoteId__c + '' => quoteId
			}
		);
		Set<Id> serviceIds = new Set<Id>();
		for (
			OpportunityProductServiceQuote__c opportunityProductServiceQuote : opportunityProductServiceQuotes
		) {
			serviceIds.add(opportunityProductServiceQuote.ServiceId__c);
		}
		if (!serviceIds.isEmpty()) {
			List<OpportunityLineItem> opportunityLineItems = [
				SELECT Id, Quantity, UnitPrice
				FROM OpportunityLineItem
				WHERE Id IN :serviceIds
				WITH SECURITY_ENFORCED
				LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
			];
			NamedRange.NamedRangeDO quoteTotalNamedRange = NamedRangeService.getQuoteTotalForQuote(
				quoteId
			);
			ServiceRecommendationsSupport.OpportunityLineItemRequest opportunityLineItemRequest = new ServiceRecommendationsSupport.OpportunityLineItemRequest();
			opportunityLineItemRequest.opportunityLineItems = opportunityLineItems;
			opportunityLineItemRequest.quoteTotalNamedRange = quoteTotalNamedRange;
			ServiceRecommendationsSupport.upsertOpportunityLineItem(opportunityLineItemRequest);
		}
	}
}
