/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private with sharing class QuoteItemCellServiceTest extends TestBase {
	@TestSetup
	static void setup() {
		Quote__c quoteSO = newQuote();
		quoteSO.Name = 'Quote Item Cell Service Test';
		CRUDUtility.updateRecords(quoteSO);

		Id productTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Product');
		Product2 productSO = newProduct('Main Product', productTypeId);
		CRUDUtility.insertRecords(productSO);

		QuoteSection__c quoteSectionSO = newQuoteSection(quoteSO.Id);
		QuoteItem__c quoteItemSO = new QuoteItem__c();
		quoteItemSO.QuoteId__c = quoteSO.Id;
		quoteItemSO.QuoteSectionId__c = quoteSectionSO.Id;
		quoteItemSO.ProductId__c = productSO.Id;
		quoteItemSO.Sequence__c = 1;
		CRUDUtility.insertRecords(quoteItemSO);

		QuoteItemCell__c itemCellSO = new QuoteItemCell__c();
		itemCellSO.QuoteItemId__c = quoteItemSO.Id;
		CRUDUtility.insertRecords(itemCellSO);
	}

	@IsTest
	static void itShouldGetQuoteItemCells() {
		Test.startTest();
		List<QuoteItem__c> quoteItems = [
			SELECT Id, QuoteId__c, QuoteId__r.Name
			FROM QuoteItem__c
			WHERE QuoteId__r.Name = 'Quote Item Cell Service Test'
		];
		Set<Id> quoteItemIds = new Set<Id>();
		for (QuoteItem__c quoteItemSO : quoteItems) {
			quoteItemIds.add(quoteItemSO.Id);
		}
		List<QuoteItemCell__c> itemCells = QuoteItemCellService.getCellsForMergeFor(quoteItemIds);
		System.assert(!itemCells.isEmpty(), 'should have quote items');
		Test.stopTest();
	}

	@IsTest
	static void itShouldCreateQuoteCellItem() {
		Test.startTest();
		QuoteItem__c quoteItemSO = [
			SELECT Id, QuoteId__c, ProductId__c, QuoteSectionId__c, Sequence__c, QuoteId__r.Name
			FROM QuoteItem__c
			WHERE QuoteId__r.Name = 'Quote Item Cell Service Test'
			LIMIT 1
		];
		Product2 productSO = [SELECT Id FROM Product2 WHERE Name = 'Main Product' LIMIT 1];
		Map<String, Decimal> durationByRole = new Map<String, Decimal>{ productSO.Id + '-1' => 12 };
		Decimal itemDuration = durationByRole.get(productSO.Id + '-1');

		Decimal itemPeriodSpan = DurationCalcs.itemPeriodSpan('Months', itemDuration);

		QuoteItemCell__c itemCellSO = QuoteItemCellService.createQuoteItemCell(
				itemPeriodSpan,
				quoteItemSO,
				1
			)
			.quoteItemCell;
		System.assert(itemCellSO != null, 'it should have created quote item cell succesfully');

		Test.stopTest();
	}
}
