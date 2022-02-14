/**
 *  Provus Services Quoting
 *  MultiCurrencyService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class MultiCurrencyService {
	public static final String ISO_CODE = 'IsoCode';
	public static final String CURRENCY_ISO_CODE = 'CurrencyIsoCode';
	public static final String CONVERSION_RATE = 'ConversionRate';

	public class CurrencyFields {
		public String currencyISOCode;
		public Decimal currencyConversionRatio;
	}

	public static Boolean isMultiCurrencyEnabled() {
		return UserInfo.isMultiCurrencyOrganization();
	}

	public static void preventCurrencyChange(List<Quote__c> quotes, Map<Id, Quote__c> oldQuotes) {
		for (Quote__c quote : quotes) {
			if (quote.get(CURRENCY_ISO_CODE) != oldQuotes.get(quote.Id).get(CURRENCY_ISO_CODE)) {
				quote.addError(CURRENCY_ISO_CODE, System.Label.QuoteCurrencyValidationMessage);
			}
		}
	}

	public static void assignCurrencyConversionRatio(List<Quote__c> quotes) {
		Map<String, SObject> currencyMap = new Map<String, SObject>();
		for (
			SObject currencyType : Database.query(
				'SELECT Id, IsCorporate, IsoCode, ConversionRate, DecimalPlaces FROM CurrencyType WHERE IsActive = true'
			)
		) {
			currencyMap.put((String) currencyType.get(ISO_CODE), currencyType);
		}

		Set<Id> rateCards = new Set<Id>();
		for (Quote__c quote : quotes) {
			if (quote.RateCardId__c != null) {
				rateCards.add(quote.RateCardId__c);
			}
		}

		if (!rateCards.isEmpty()) {
			QueryRequest queryRequest = new QueryRequest(Schema.RateCard__c.SObjectType);
			queryRequest.requestedFields = new Set<String>{ SObjectUtility.FIELD_ID, CURRENCY_ISO_CODE };
			queryRequest.setFilterBy(new Map<String, Set<Id>>{ SObjectUtility.FIELD_ID => rateCards });
			List<RateCard__c> rateCardRecords = SOQLUtility.querySObject(queryRequest);

			Map<Id, RateCard__c> rateCardMap = new Map<Id, RateCard__c>(rateCardRecords);

			for (Quote__c quote : quotes) {
				if (
					quote.RateCardId__c != null &&
					(String) rateCardMap.get(quote.RateCardId__c).get(CURRENCY_ISO_CODE) !=
					(String) quote.get(CURRENCY_ISO_CODE)
				) {
					quote.CurrencyConversionRatio__c =
						(Decimal) currencyMap.get((String) quote.get(CURRENCY_ISO_CODE)).get(CONVERSION_RATE) /
						(Decimal) currencyMap.get(
								(String) rateCardMap.get(quote.RateCardId__c).get(CURRENCY_ISO_CODE)
							)
							.get(CONVERSION_RATE);
				}
			}
		}
	}

	public static void syncQuoteCurrency(List<QuoteItem__c> quoteItems) {
		Set<Id> quoteIds = new Set<Id>();
		for (QuoteItem__c quoteItem : quoteItems) {
			quoteIds.add(quoteItem.QuoteId__c);
		}

		QueryRequest queryRequest = new QueryRequest(Schema.Quote__c.SObjectType);
		queryRequest.requestedFields = new Set<String>{ SObjectUtility.FIELD_ID, CURRENCY_ISO_CODE };
		queryRequest.setFilterBy(new Map<String, Set<Id>>{ SObjectUtility.FIELD_ID => quoteIds });
		List<Quote__c> quotes = SOQLUtility.querySObject(queryRequest);
		Map<Id, Quote__c> quotesMap = new Map<Id, Quote__c>(quotes);

		for (QuoteItem__c quoteItem : quoteItems) {
			quoteItem.put(
				CURRENCY_ISO_CODE,
				(String) quotesMap.get(quoteItem.QuoteId__c).get(CURRENCY_ISO_CODE)
			);
		}
	}

	public static void updateCurrencyFields(
		List<QuoteItem__c> quoteItems,
		Map<Id, QuoteItem__c> oldQuoteItems
	) {
		List<String> apiNames = new List<String>{
			Schema.QuoteItem__c.UnitCost__c + '',
			Schema.QuoteItem__c.UnitPrice__c + '',
			Schema.QuoteItem__c.AdjustedUnitCost__c + '',
			Schema.QuoteItem__c.AdjustedUnitPrice__c + ''
		};

		for (QuoteItem__c quoteItem : quoteItems) {
			for (String apiName : apiNames) {
				if (
					quoteItem.get(apiName) != oldQuoteItems.get(quoteItem.Id).get(apiName) &&
					oldQuoteItems.get(quoteItem.Id).get(apiName) == null
				) {
					quoteItem.put(
						apiName,
						(Decimal) quoteItem.get(apiName) * quoteItem.CurrencyConversionRatio__c
					);
				}
			}
		}
	}
}
