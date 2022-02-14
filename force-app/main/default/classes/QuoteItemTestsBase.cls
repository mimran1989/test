/**
 *  Provus Services Quoting
 *  QuoteItemTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class QuoteItemTestsBase extends TestBase {
	public static QuoteItem__c newQuoteItemSO() {
		Quote__c testQuote = newQuote();
		QuoteItem__c newQuoteItem = new QuoteItem__c(QuoteId__c = testQuote.Id);
		CRUDUtility.insertRecords(newQuoteItem);
		return newQuoteItem;
	}

	public static QuoteItemDTO newQuoteItemDO(QuoteItem__c quoteItem) {
		QuoteItemDTO newDO = newQuoteItemDO(quoteItem.QuoteId__c);
		newDO.id = quoteItem.Id;
		newDO.quoteItemSO = quoteItem;
		return newDO;
	}

	public static QuoteItemDTO newQuoteItemDO() {
		Quote__c testQuote = newQuote();
		return newQuoteItemDO(testQuote.Id);
	}

	public static QuoteItemDTO newQuoteItemDO(Id quoteId) {
		QuoteItemDTO newQuoteItemDO = new QuoteItemDTO();
		newQuoteItemDO.quoteId = quoteId;
		newQuoteItemDO.lineSequence = 1;
		newQuoteItemDO.displaySequence = 1;
		newQuoteItemDO.quoteItemSO = new QuoteItem__c();
		newQuoteItemDO.periodValueMap = new Map<String, Decimal>();

		return newQuoteItemDO;
	}
}
