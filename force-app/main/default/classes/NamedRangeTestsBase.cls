/**
 *  Provus Services Quoting
 *  NamedRangeTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class NamedRangeTestsBase extends TestBase {
	public static Adjustment__c newAdjustment(Id namedRangeId) {
		Adjustment__c adjustmentSO = new Adjustment__c(NamedRangeId__c = namedRangeId);
		CRUDUtility.insertRecords(adjustmentSO);
		return adjustmentSO;
	}

	public static NamedRange__c newNamedRange() {
		Quote__c testQuote = newQuote();
		NamedRangeTotal__c namedRangeTotalSO = newNamedRangeTotal(testQuote.Id);
		newNamedRange(testQuote.Id, namedRangeTotalSO.Id);
		return NamedRangeFactory.getNamedRangesForQuote(testQuote.Id)[0];
	}

	public static NamedRange__c newNamedRange(Id quoteId, Id namedRangeTotalId) {
		NamedRange__c namedRangeSO = new NamedRange__c(
			NamedRangeTotalId__c = namedRangeTotalId,
			QuoteId__c = quoteId
		);
		CRUDUtility.insertRecords(namedRangeSO);
		return namedRangeSO;
	}

	public static NamedRange.NamedRangeDO newNamedRangeDO() {
		Quote__c testQuote = newQuote();
		NamedRange.NamedRangeDO testNamedRangeDO = new NamedRange.NamedRangeDO();
		testNamedRangeDO.quoteId = testQuote.Id;

		NamedRangeTotal.NamedRangeTotalDO testNamedRangeTotalDO = new NamedRangeTotal.NamedRangeTotalDO();
		testNamedRangeDO.relatedTotal = testNamedRangeTotalDO;
		return testNamedRangeDO;
	}

	public static NamedRangeTotal__c newNamedRangeTotal(Id quoteId) {
		NamedRangeTotal__c namedRangeTotalSO = new NamedRangeTotal__c(QuoteId__c = quoteId);
		CRUDUtility.insertRecords(namedRangeTotalSO);
		return namedRangeTotalSO;
	}
}
