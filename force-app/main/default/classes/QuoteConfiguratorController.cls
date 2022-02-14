/**
 *  Provus Services Quoting
 *  QuoteConfiguratorController
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteConfiguratorController {
	/**
	 * Gets the quote template for initializing the quote configurator
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string for QuoteTemplateDO
	 */
	@AuraEnabled
	public static String getQuoteTemplate(Id quoteId) {
		try {
			return JSON.serialize(QuoteConfiguratorSupport.getQuoteTemplate(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('getQuoteTemplate threw exception: ' + e.getMessage());
		}
	}

	/**
	 * Gets all valid products for a quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string
	 */
	@AuraEnabled
	public static String getAllProductsForQuote(Id quoteId) {
		try {
			return JSON.serialize(QuoteConfiguratorSupport.getAllProductsForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('getAllProductsForQuote threw exception: ' + e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static List<ProductService.ProductStruct> getAllOriginalProductsForQuote(Id quoteId) {
		return new List<ProductService.ProductStruct>(
			QuoteConfiguratorSupport.getAllProductsForQuote(quoteId)
		);
	}

	/**
	 * Gets all rate card items for a product
	 * @param   quoteId Id of the quote
	 * @param   productId Id of the product
	 * @return  Serialized JSON string
	 */
	@AuraEnabled
	public static String getAllRateCardItemsForProduct(Id quoteId, Id productId) {
		try {
			return JSON.serialize(
				QuoteConfiguratorSupport.getAllRateCardItemsForProduct(quoteId, productId)
			);
		} catch (Exception e) {
			throw new AuraHandledException(
				'getAllRateCardItemsForProduct threw exception: ' + e.getMessage()
			);
		}
	}

	/**
	 * Gets all quote items for quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string
	 */
	@AuraEnabled
	public static String getQuoteItemsForQuote(Id quoteId) {
		try {
			return JSON.serialize(QuoteConfiguratorSupport.getQuoteItemsForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('getQuoteItemsForQuote threw exception: ' + e.getMessage());
		}
	}

	/**
	 * @param quoteId  Id of the quote
	 * @param quoteItemsColData collection of quote item data
	 *
	 * @return Serialized JSON string of new quote item details
	 */
	@AuraEnabled
	public static String commitQuoteItems(Id quoteId, String quoteItemsColData) {
		List<QuoteItemDTO> quoteItemDTOs = (List<QuoteItemDTO>) JSON.deserialize(
			quoteItemsColData,
			List<QuoteItemDTO>.class
		);

		return JSON.serialize(QuoteConfiguratorSupport.commitQuoteItems(quoteId, quoteItemDTOs));
	}

	/**
	 * Gets all namedranges for a quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string containing named range wrappers
	 */
	@AuraEnabled
	public static String getNamedRangesForQuote(Id quoteId) {
		try {
			return JSON.serialize(QuoteConfiguratorSupport.getNamedRangesForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('getNamedRangesForQuote threw exception: ' + e.getMessage());
		}
	}

	/**
	 * commit namedranges for a quote
	 *
	 * @param quoteId Id of the quote
	 * @param namedRangeColData JSON string containing named range wrappers
	 *
	 * @return Serialized JSON string containing named range wrappers
	 */
	@AuraEnabled
	public static String commitNamedRanges(Id quoteId, String namedRangeColData) {
		try {
			QuoteConfiguratorSupport.commitNamedRanges(namedRangeColData);
			ProvusConfiguratorSetting__mdt provusConfigSetting = ProvusConfiguratorSetting__mdt.getInstance(
				'ProvusDefault'
			);
			if (provusConfigSetting.DisableAutomaticOpportunitySync__c) {
				QuoteConfiguratorSupport.syncQuoteToOpportunity(quoteId);
			}
			return JSON.serialize(QuoteConfiguratorSupport.getNamedRangesForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('commitNamedRanges threw exception: ' + e.getMessage());
		}
	}

	/**
	 * get project phases for a quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string containing project phase wrappers
	 */
	@AuraEnabled
	public static String getProjectPhasesForQuote(Id quoteId) {
		try {
			return JSON.serialize(QuoteConfiguratorSupport.getProjectPhasesForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('getProjectPhasesForQuote threw exception: ' + e.getMessage());
		}
	}

	/**
	 * commit project phases for a quote
	 *
	 * @param quoteId Id of the quote
	 * @param projectPhaseColData JSON string containing project phases wrappers
	 *
	 * @return Serialized JSON string containing project phases wrappers
	 */
	@AuraEnabled
	public static String commitProjectPhases(Id quoteId, String projectPhaseColData) {
		try {
			QuoteConfiguratorSupport.commitProjectPhases(projectPhaseColData);
			return JSON.serialize(QuoteConfiguratorSupport.getProjectPhasesForQuote(quoteId));
		} catch (Exception e) {
			throw new AuraHandledException('commitProjectPhases threw exception: ' + e.getMessage());
		}
	}

	/**
	 * get quote sections for a quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string containing quote section wrappers
	 */
	@AuraEnabled
	public static String getQuoteSectionsForQuote(Id quoteId) {
		return JSON.serialize(QuoteConfiguratorSupport.getQuoteSectionsForQuote(quoteId));
	}

	/**
	 * commit quote sections for a quote
	 * @param quoteId Id of the quote
	 * @param quoteSectionColData JSON string containing quote section wrappers
	 * @return Serialized JSON string containing quote section wrappers
	 */
	@AuraEnabled
	public static String commitQuoteSections(Id quoteId, String quoteSectionColData) {
		QuoteConfiguratorSupport.commitQuoteSections(quoteId, quoteSectionColData);
		return JSON.serialize(QuoteConfiguratorSupport.getQuoteSectionsForQuote(quoteId));
	}
}
