/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private class QuoteServiceTest extends TestBase {
	@IsTest
	static void shouldAssignSectionsToQuoteItems() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO1 = newQuoteSection(quoteSO.Id);
		QuoteSection__c sectionSO2 = newQuoteSection(quoteSO.Id);

		QuoteItem__c quoteItemSO1 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO1.Id
		);
		QuoteItem__c quoteItemSO2 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO2.Id
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ quoteItemSO1, quoteItemSO2 });

		Test.startTest();
		Quote__c clonedQuote = QuoteService.cloneQuote(quoteSO.Id);
		List<QuoteItem__c> items = [
			SELECT Id, QuoteSectionId__c
			FROM QuoteItem__c
			WHERE QuoteId__c = :clonedQuote.Id
		];
		List<Id> sectionIds = new List<Id>();
		for (QuoteItem__c item : items) {
			sectionIds.add(item.QuoteSectionId__c);
		}

		System.assert(sectionIds.size() == 2, 'should have each section assigned to the quote items');
		Test.stopTest();
	}

	@IsTest
	static void shouldCopyTheGivenQuoteSections() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO1 = newQuoteSection(quoteSO.Id);
		QuoteSection__c sectionSO2 = newQuoteSection(quoteSO.Id);

		QuoteItem__c quoteItemSO1 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO1.Id
		);
		QuoteItem__c quoteItemSO2 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO2.Id
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ quoteItemSO1, quoteItemSO2 });

		Test.startTest();
		Quote__c clonedQuote = QuoteService.cloneQuote(quoteSO.Id, new Set<Id>{ sectionSO1.Id });
		List<QuoteItem__c> items = [
			SELECT Id, QuoteSectionId__c
			FROM QuoteItem__c
			WHERE QuoteId__c = :clonedQuote.Id
		];

		System.assert(items.size() == 1, 'should only copy the the quote item from the given section');
		Test.stopTest();
	}

	@IsTest
	static void shouldCopyAllItemsWithEmptySectionSet() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO1 = newQuoteSection(quoteSO.Id);
		QuoteSection__c sectionSO2 = newQuoteSection(quoteSO.Id);

		QuoteItem__c quoteItemSO1 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO1.Id
		);
		QuoteItem__c quoteItemSO2 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO2.Id
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ quoteItemSO1, quoteItemSO2 });

		Test.startTest();
		Quote__c clonedQuote = QuoteService.cloneQuote(quoteSO.Id, new Set<Id>());
		List<QuoteItem__c> items = [
			SELECT Id, QuoteSectionId__c
			FROM QuoteItem__c
			WHERE QuoteId__c = :clonedQuote.Id
		];

		System.assert(items.size() == 2, 'should copy all items when quote section set is empty');
		Test.stopTest();
	}
}
