/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */

@IsTest
private class CollaborationMergeServiceTest extends TestBase {
	@IsTest
	static void itShouldMergeQuoteSections() {
		Quote__c targetQuote = newQuote();
		Quote__c sourceQuote = newQuote();
		QuoteSection__c targetSection = new QuoteSection__c(QuoteId__c = targetQuote.Id);
		QuoteSection__c sourceSection = new QuoteSection__c(QuoteId__c = sourceQuote.Id);
		Adjustment__c targetAdj = new Adjustment__c(Amount__c = 1);
		Adjustment__c sourceAdj = new Adjustment__c(Amount__c = 2);
		CRUDUtility.insertRecords(
			new List<SObject>{ targetSection, sourceSection, targetAdj, sourceAdj }
		);
		QuoteItem__c targetItem = new QuoteItem__c(
			QuoteId__c = targetQuote.Id,
			QuoteSectionId__c = targetSection.Id,
			AdjustmentId__c = targetAdj.Id
		);
		QuoteItem__c sourceItem = new QuoteItem__c(
			QuoteId__c = sourceQuote.Id,
			QuoteSectionId__c = sourceSection.Id,
			AdjustmentId__c = sourceAdj.Id,
			SkillLevel__c = 'L2'
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ targetItem, sourceItem });
		QuoteItemCell__c targetCell = new QuoteItemCell__c(QuoteItemId__c = targetItem.Id);
		QuoteItemCell__c sourceCell = new QuoteItemCell__c(QuoteItemId__c = sourceItem.Id, C001__c = 1);
		CRUDUtility.insertRecords(new List<QuoteItemCell__c>{ targetCell, sourceCell });
		sourceSection.DerivedFromId__c = targetSection.Id;
		sourceItem.DerivedFromId__c = targetItem.Id;
		CRUDUtility.updateRecords(new List<SObject>{ sourceSection, sourceItem });
		newCollaborationRequest(targetSection.Id, CollaborationRequest.STATUS_READY_TO_MERGE);
		newCollaborationRequest(sourceSection.Id, CollaborationRequest.STATUS_READY_TO_MERGE);

		Test.startTest();
		CollaborationMergeService.mergeSections(targetQuote.Id, new List<Id>{ targetSection.Id });
		QuoteItem__c resultItem = [SELECT SkillLevel__c FROM QuoteItem__c WHERE Id = :targetItem.Id];
		QuoteItemCell__c resultCell = [SELECT C001__c FROM QuoteItemCell__c WHERE Id = :targetCell.Id];
		Adjustment__c resultAdj = [SELECT Amount__c FROM Adjustment__c WHERE Id = :targetAdj.Id];
		System.assertEquals(
			sourceItem.SkillLevel__c,
			resultItem.SkillLevel__c,
			'should have the value of item 2 skill level'
		);
		System.assertEquals(
			sourceCell.C001__c,
			resultCell.C001__c,
			'should have the value of cell 2 field 1'
		);
		System.assertEquals(
			sourceAdj.Amount__c,
			resultAdj.Amount__c,
			'should have the value of adjustment amount'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldRemoveQuoteItems() {
		Quote__c targetQuote = newQuote();
		QuoteSection__c targetSection = new QuoteSection__c(QuoteId__c = targetQuote.Id);
		Adjustment__c targetAdj = new Adjustment__c();
		CRUDUtility.insertRecords(new List<SObject>{ targetSection, targetAdj });
		QuoteItem__c targetItem = new QuoteItem__c(
			QuoteId__c = targetQuote.Id,
			QuoteSectionId__c = targetSection.Id,
			AdjustmentId__c = targetAdj.Id
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ targetItem });
		QuoteItemCell__c targetCell = new QuoteItemCell__c(QuoteItemId__c = targetItem.Id);
		CRUDUtility.insertRecords(new List<QuoteItemCell__c>{ targetCell });
		newCollaborationRequest(targetSection.Id, CollaborationRequest.STATUS_READY_TO_MERGE);

		Test.startTest();
		Integer itemsSize = [SELECT COUNT() FROM QuoteItem__c WHERE QuoteId__c = :targetQuote.Id];
		System.assert(itemsSize == 1, 'should start with 1 item');
		CollaborationMergeService.mergeSections(targetQuote.Id, new List<Id>{ targetSection.Id });
		itemsSize = [SELECT COUNT() FROM QuoteItem__c WHERE QuoteId__c = :targetQuote.Id];
		System.assert(
			itemsSize == 0,
			'should equal 0 after removing the unreferenced source quote item'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldAddQuoteItems() {
		Quote__c targetQuote = newQuote();
		Quote__c sourceQuote = newQuote();
		QuoteSection__c targetSection = new QuoteSection__c(QuoteId__c = targetQuote.Id);
		QuoteSection__c sourceSection = new QuoteSection__c(QuoteId__c = sourceQuote.Id);
		Adjustment__c sourceAdj = new Adjustment__c(Amount__c = 2);
		CRUDUtility.insertRecords(new List<SObject>{ targetSection, sourceSection, sourceAdj });
		QuoteItem__c sourceItem = new QuoteItem__c(
			QuoteId__c = sourceQuote.Id,
			QuoteSectionId__c = sourceSection.Id,
			AdjustmentId__c = sourceAdj.Id,
			SkillLevel__c = 'L2'
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ sourceItem });
		QuoteItemCell__c sourceCell = new QuoteItemCell__c(QuoteItemId__c = sourceItem.Id, C001__c = 1);
		CRUDUtility.insertRecords(new List<QuoteItemCell__c>{ sourceCell });
		sourceSection.DerivedFromId__c = targetSection.Id;
		CRUDUtility.updateRecords(new List<SObject>{ sourceSection, sourceItem });
		newCollaborationRequest(targetSection.Id, CollaborationRequest.STATUS_READY_TO_MERGE);
		newCollaborationRequest(sourceSection.Id, CollaborationRequest.STATUS_READY_TO_MERGE);

		Test.startTest();
		Integer itemsSize = [SELECT COUNT() FROM QuoteItem__c WHERE QuoteId__c = :targetQuote.Id];
		System.assert(itemsSize == 0, 'should start with 0 items');
		CollaborationMergeService.mergeSections(targetQuote.Id, new List<Id>{ targetSection.Id });
		itemsSize = [SELECT COUNT() FROM QuoteItem__c WHERE QuoteId__c = :targetQuote.Id];
		System.assert(itemsSize == 1, 'should equal 1 after adding the unreferenced target quote item');
		Test.stopTest();
	}

	@IsTest
	static void itShouldCopyQuoteItemValues() {
		Quote__c quote = newQuote();
		QuoteItem__c item1 = new QuoteItem__c(Quantity__c = 2, QuoteId__c = quote.Id);
		QuoteItem__c item2 = new QuoteItem__c(Quantity__c = 1);

		Test.startTest();
		CollaborationMergeService.mergeQuoteItem(item1, item2);
		System.assertEquals(item1.Quantity__c, item2.Quantity__c, 'should equal quantity of item 1');
		System.assertNotEquals(
			item1.QuoteId__c,
			item2.QuoteId__c,
			'should not equal quote ID of item 1'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldCopyAdjustmentValues() {
		Adjustment__c adj1 = new Adjustment__c(Amount__c = 1);
		Adjustment__c adj2 = new Adjustment__c(Amount__c = 2);

		Test.startTest();
		CollaborationMergeService.mergeAdjustments(adj1, adj2);
		System.assertEquals(adj2.Amount__c, adj1.Amount__c, 'should equal quantity of item 1');
		Test.stopTest();
	}

	@IsTest
	static void itShouldCopyCellValues() {
		QuoteItemCell__c cell1 = new QuoteItemCell__c(C001__c = 1, C002__c = 2, C003__c = 3);
		QuoteItemCell__c cell2 = new QuoteItemCell__c();

		Test.startTest();
		CollaborationMergeService.mergeQuoteItemCell(cell1, cell2);
		System.assertEquals(cell1.C001__c, cell2.C001__c, 'should equal cell 1 field 1');
		System.assertEquals(cell1.C002__c, cell2.C002__c, 'should equal cell 1 field 2');
		System.assertEquals(cell1.C003__c, cell2.C003__c, 'should equal cell 1 field 3');
		Test.stopTest();
	}

	@IsTest
	static void itShouldRemoveCellValuesNotInSource() {
		QuoteItemCell__c cell1 = new QuoteItemCell__c(C001__c = 1, C002__c = 2, C003__c = 3);
		QuoteItemCell__c cell2 = new QuoteItemCell__c(C004__c = 4);

		Test.startTest();
		CollaborationMergeService.mergeQuoteItemCell(cell1, cell2);
		System.assertEquals(null, cell2.C004__c, 'should clear field 4');
		Test.stopTest();
	}
}
