@IsTest
public with sharing class QuoteItemServiceTest extends QuoteItemTestsBase {
	@IsTest
	static void itShouldInsertNewQuoteItem() {
		QuoteItemDTO testQuoteItemDO = newQuoteItemDO();
		testQuoteItemDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testQuoteItemDO.lineSequence = 50;

		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>{ testQuoteItemDO };
		Test.startTest();
		QuoteItemService.commitQuoteItems(testQuoteItemDO.quoteId, quoteItemDOs);

		System.assertNotEquals(null, testQuoteItemDO.quoteItemSO.Id, 'should create new quote item');
		Test.stopTest();
	}

	@IsTest
	static void itShouldDeleteQuoteItem() {
		QuoteItem__c quoteItemSO = newQuoteItemSO();
		QuoteItemDTO quoteItemDO = newQuoteItemDO(quoteItemSO);

		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_DELETE;

		NamedRangeTotal__c namedRangeTotalSO = new NamedRangeTotal__c(QuoteId__c = quoteItemDO.quoteId);
		CRUDUtility.insertRecords(namedRangeTotalSO);

		NamedRange__c namedRangeSO = new NamedRange__c(
			NamedRangeTotalId__c = namedRangeTotalSO.id,
			QuoteId__c = quoteItemDO.quoteId,
			quoteitemid__c = quoteItemDO.id
		);
		CRUDUtility.insertRecords(namedRangeSO);

		Test.startTest();
		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>{ quoteItemDO };
		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, quoteItemDOs);
		QuoteItem__c testQuoteItemSO = [
			SELECT IsDeleted
			FROM QuoteItem__c
			WHERE Id = :quoteItemSO.Id
			ALL ROWS
		];

		System.assertEquals(true, testQuoteItemSO.IsDeleted, 'should delete quote item');
		Test.stopTest();
	}

	@IsTest
	static void itShouldAssociateNewQuoteItemCellToQuoteItem() {
		QuoteItemDTO quoteItemDO = newQuoteItemDO();
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		Test.startTest();
		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>{ quoteItemDO };
		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, quoteItemDOs);

		QuoteItemCell__c testQuoteItemCell = [
			SELECT Id, QuoteItemId__c
			FROM QuoteItemCell__c
			WHERE Id = :quoteItemDO.quoteItemCellId
		];

		System.assertNotEquals(
			null,
			quoteItemDO.quoteItemCellId,
			'should associate quote item cell id to quote item'
		);
		System.assertNotEquals(null, testQuoteItemCell.Id, 'should insert quote item cell');

		Test.stopTest();
	}

	@IsTest
	static void itShouldAssociateNewAdjustmentToQuoteItem() {
		QuoteItemDTO quoteItemDO = newQuoteItemDO();
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		quoteItemDO.adjustment.type = '% Discount';
		quoteItemDO.adjustment.amount = 100;

		Test.startTest();
		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>{ quoteItemDO };
		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, quoteItemDOs);

		Adjustment__c testAdjustment = [
			SELECT Id
			FROM Adjustment__c
			WHERE Id = :quoteItemDO.adjustmentId
		];

		System.assertNotEquals(
			null,
			quoteItemDO.adjustmentId,
			'should associate adjustment id to quote item'
		);
		System.assertNotEquals(null, testAdjustment.Id, 'should insert adjustment');

		Test.stopTest();
	}

	@IsTest
	static void itShouldUpdateTheQuoteItemCell() {
		QuoteItemDTO quoteItemDO = newQuoteItemDO();
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		update new Quote__c(Id = quoteItemDO.quoteId, RateCardId__c = newRateCard().Id);

		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>{ quoteItemDO };
		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, quoteItemDOs);
		QuoteItemCell__c quoteItemCellSO = new QuoteItemCell__c(
			QuoteItemId__c = quoteItemDO.id,
			C001__c = 1
		);
		insert quoteItemCellSO;

		quoteItemDO.quoteItemSO = QuoteItemServiceSupport.getQuoteItemSOsForQuote(
			quoteItemDO.quoteId
		)[0];
		quoteItemDO.periodValueMap.put('001', 100);
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_UPDATE;

		Test.startTest();
		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, quoteItemDOs);
		QuoteItemCell__c testQuoteItemCell = [
			SELECT Id, QuoteItemId__c, C001__c
			FROM QuoteItemCell__c
			WHERE Id = :quoteItemDO.quoteItemCellId
		];

		System.assertEquals(100, testQuoteItemCell.C001__c, 'should update the quote item cell to 100');
		Test.stopTest();
	}

	@IsTest
	static void itShouldUpdateTheAdjustment() {
		QuoteItemDTO quoteItemDO = newQuoteItemDO();
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		quoteItemDO.adjustment.type = '% Discount';
		quoteItemDO.adjustment.amount = 100;

		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, new List<QuoteItemDTO>{ quoteItemDO });

		Test.startTest();
		quoteItemDO.adjustment.amount = 200;
		quoteItemDO.operationType = BaseDTO.OPERATION_TYPE_UPDATE;

		QuoteItemService.commitQuoteItems(quoteItemDO.quoteId, new List<QuoteItemDTO>{ quoteItemDO });
		Adjustment__c testAdjustment = [
			SELECT Id, Amount__c
			FROM Adjustment__c
			WHERE Id = :quoteItemDO.adjustmentId
		];

		System.assertEquals(
			200,
			testAdjustment.Amount__c,
			'should update the quote adjustment value to 200'
		);
	}
}
