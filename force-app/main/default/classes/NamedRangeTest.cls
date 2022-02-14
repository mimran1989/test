/**
 *  Provus Services Quoting
 *  NamedRangeTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class NamedRangeTest extends NamedRangeTestsBase {
	@IsTest
	static void itShouldConstructNamedRangeFromDO() {
		NamedRange.NamedRangeDO namedRangeDO = new NamedRange.NamedRangeDO();
		namedRangeDO.relatedTotal = new NamedRangeTotal.NamedRangeTotalDO();

		Test.startTest();
		NamedRange namedRange = new NamedRange(namedRangeDO);
		System.assertNotEquals(namedRange, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldNotConstructNamedRangeFromDO() {
		NamedRange.NamedRangeDO namedRangeDO = new NamedRange.NamedRangeDO();

		Test.startTest();
		try {
			NamedRange namedRange = new NamedRange(namedRangeDO);
			System.assertNotEquals(namedRange, namedRange, 'should throw exception');
		} catch (ApplicationException e) {
			System.assertEquals(
				'Named Range DO requires a related total.',
				e.getMessage(),
				'should throw exception'
			);
		}
		Test.stopTest();
	}

	@IsTest
	static void itShouldConstructNamedRangeFromSO() {
		Quote__c testQuote = newQuote();
		NamedRangeTotal__c namedRangeTotalSO = newNamedRangeTotal(testQuote.Id);
		NamedRange__c namedRangeSO = newNamedRange(testQuote.Id, namedRangeTotalSO.Id);
		newAdjustment(namedRangeSO.Id);

		NamedRange__c testNamedRangeSO = NamedRangeFactory.getNamedRangesForQuote(testQuote.Id)[0];
		Test.startTest();
		NamedRange namedRange = new NamedRange(testNamedRangeSO);
		System.assertNotEquals(namedRange, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnTrueForQuoteType() {
		NamedRange__c testNamedRangeSO = newNamedRange();
		testNamedRangeSO.Type__c = NamedRange.TYPE_QUOTE;
		CRUDUtility.updateRecords(testNamedRangeSO);

		Test.startTest();
		NamedRange namedRangeMO = new NamedRange(testNamedRangeSO);
		System.assertEquals(true, namedRangeMO.isQuoteTotal(), 'should return true for quote type');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnFalseForNonQuoteType() {
		NamedRange__c testNamedRangeSO = newNamedRange();

		Test.startTest();
		NamedRange namedRangeMO = new NamedRange(testNamedRangeSO);
		System.assertEquals(
			false,
			namedRangeMO.isQuoteTotal(),
			'should return false for non quote type'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldInsertNewNamedRange() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		Test.startTest();

		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRange__c testNamedRangeSO = (NamedRange__c) testNamedRange.getSObject();

		System.assertNotEquals(null, testNamedRangeSO.Id, 'should create new named range');

		Test.stopTest();
	}

	@IsTest
	static void itShouldInsertNewNamedRangeTotal() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.relatedTotal.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		AdjustmentDTO testAdjustmentDO = new AdjustmentDTO();
		testAdjustmentDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.adjustmentList = new List<AdjustmentDTO>{ testAdjustmentDO };

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		Test.startTest();

		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRangeTotal__c testNamedRangeTotalSO = (NamedRangeTotal__c) testNamedRange.getNamedRangeTotal()
			.getSObject();

		System.assertNotEquals(null, testNamedRangeTotalSO.Id, 'should create new named range total');
		Test.stopTest();
	}

	@IsTest
	static void itShouldInsertNewAdjustment() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.relatedTotal.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		AdjustmentDTO testAdjustmentDO = new AdjustmentDTO();
		testAdjustmentDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.adjustmentList = new List<AdjustmentDTO>{ testAdjustmentDO };

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		Test.startTest();

		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		Adjustment__c testAdjustmentSO = (Adjustment__c) testNamedRange.getAdjustments()[0]
			.getSObject();

		System.assertNotEquals(null, testAdjustmentSO.Id, 'should create new adjustment');
		Test.stopTest();
	}

	@IsTest
	static void itShouldDeleteNamedRange() {
		NamedRange__c newNamedRangeSO = newNamedRange();
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.namedRangeId = newNamedRangeSO.Id;
		testNamedRangeDO.operationType = ManagedObject.OPERATION_TYPE_DELETE;
		testNamedRangeDO.relatedTotal.namedRangeTotalId = newNamedRangeSO.NamedRangeTotalId__c;
		testNamedRangeDO.relatedTotal.operationType = ManagedObject.OPERATION_TYPE_DELETE;

		Test.startTest();
		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRange__c testNamedRangeSO = [
			SELECT IsDeleted
			FROM NamedRange__c
			WHERE Id = :newNamedRangeSO.Id
			ALL ROWS
		];

		System.assertEquals(true, testNamedRangeSO.IsDeleted, 'should delete named range');
		Test.stopTest();
	}

	@IsTest
	static void itShouldDeleteNamedRangeTotal() {
		NamedRange__c newNamedRangeSO = newNamedRange();
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.namedRangeId = newNamedRangeSO.Id;
		testNamedRangeDO.relatedTotal.namedRangeTotalId = newNamedRangeSO.NamedRangeTotalId__c;
		testNamedRangeDO.relatedTotal.operationType = ManagedObject.OPERATION_TYPE_DELETE;

		Test.startTest();
		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRangeTotal__c testNamedRangeTotalSO = [
			SELECT IsDeleted
			FROM NamedRangeTotal__c
			WHERE Id = :newNamedRangeSO.NamedRangeTotalId__c
			ALL ROWS
		];

		System.assertEquals(true, testNamedRangeTotalSO.IsDeleted, 'should delete named range total');
		Test.stopTest();
	}

	@IsTest
	static void itShouldDeleteAdjustment() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		AdjustmentDTO newAdjustmentDO = new AdjustmentDTO();
		newAdjustmentDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.adjustmentList = new List<AdjustmentDTO>{ newAdjustmentDO };

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });

		Adjustment testAdjustmentMO = (Adjustment) testNamedRange.getAdjustments()[0];
		AdjustmentDTO testAdjustmentDO = (AdjustmentDTO) testAdjustmentMO.baseDTO;
		testAdjustmentDO.operationType = ManagedObject.OPERATION_TYPE_DELETE;

		Test.startTest();
		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });

		Adjustment__c adjustmentSO = (Adjustment__c) testAdjustmentMO.getSObject();
		Adjustment__c testAdjustmentSO = [
			SELECT IsDeleted
			FROM Adjustment__c
			WHERE Id = :adjustmentSO.Id
			ALL ROWS
		];

		System.assertEquals(true, testAdjustmentSO.IsDeleted, 'should delete adjustment');
		Test.stopTest();
	}

	@IsTest
	static void itShouldAssociateNamedRangeTotal() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.relatedTotal.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		Test.startTest();

		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRange__c testNamedRangeSO = (NamedRange__c) testNamedRange.getSObject();
		NamedRangeTotal__c testNamedRangeTotalSO = (NamedRangeTotal__c) testNamedRange.getNamedRangeTotal()
			.getSObject();

		System.assertEquals(
			testNamedRangeSO.NamedRangeTotalId__c,
			testNamedRangeTotalSO.Id,
			'should associate named range total to named range'
		);
	}

	@IsTest
	static void itShouldAssociateNamedRangeIdToAdjustments() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		AdjustmentDTO testAdjustmentDO = new AdjustmentDTO();
		testAdjustmentDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.adjustmentList = new List<AdjustmentDTO>{ testAdjustmentDO };

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);
		Test.startTest();

		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRange__c testNamedRangeSO = (NamedRange__c) testNamedRange.getSObject();
		Adjustment__c testAdjustmentSO = (Adjustment__c) testNamedRange.getAdjustments()[0]
			.getSObject();

		System.assertEquals(
			testNamedRangeSO.Id,
			testAdjustmentSO.NamedRangeId__c,
			'should associate adjustment to named range'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldUpdateTheQuoteForQuoteNamedRange() {
		NamedRange.NamedRangeDO testNamedRangeDO = newNamedRangeDO();
		testNamedRangeDO.type = NamedRange.TYPE_QUOTE;
		testNamedRangeDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.relatedTotal.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		testNamedRangeDO.relatedTotal.totalAmount = 100;
		testNamedRangeDO.relatedTotal.totalCost = 200;
		testNamedRangeDO.relatedTotal.marginPercent = 100;

		NamedRange testNamedRange = new NamedRange(testNamedRangeDO);

		Test.startTest();
		NamedRange.commitNamedRanges(new List<NamedRange>{ testNamedRange });
		NamedRange__c testNamedRangeSO = (NamedRange__c) testNamedRange.getSObject();
		List<Quote__c> quotes = [
			SELECT Id, TotalAmount__c, TotalCost__c, MarginPercent__c
			FROM Quote__c
			WHERE Id = :testNamedRangeSO.QuoteId__c
		];

		System.assertEquals(
			100,
			quotes[0].TotalAmount__c,
			'Total Amount should be copied to the Quote'
		);
		System.assertEquals(200, quotes[0].TotalCost__c, 'Total Cost should be copied to the Quote');
		System.assertEquals(
			100,
			quotes[0].MarginPercent__c,
			'Margin Percent should be copied to the Quote'
		);
	}
}
