/**
 *  Provus Services Quoting
 *  QuoteItemTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
public with sharing class QuoteItemTest extends QuoteItemTestsBase {
	@IsTest
	static void itShouldConstructQuoteItemFromDO() {
		QuoteItemDTO quoteItemDO = new QuoteItemDTO();

		Test.startTest();
		QuoteItem quoteItem = new QuoteItem(quoteItemDO);
		System.assertNotEquals(quoteItem, null, 'should not be null');
		Test.stopTest();
	}
}
