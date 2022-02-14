/**
 *  Provus Services Quoting
 *  NamedRangeServiceTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class NamedRangeServiceTest extends NamedRangeTestsBase {
	@IsTest
	static void itShouldReturnSuccess() {
		Quote__c testQuote = newQuote();
		NamedRange.NamedRangeDO namedRangeDO = new NamedRange.NamedRangeDO();
		namedRangeDO.quoteId = testQuote.Id;
		namedRangeDO.relatedTotal = new NamedRangeTotal.NamedRangeTotalDO();
		namedRangeDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		Test.startTest();
		Boolean result = NamedRangeService.commitNamedRanges(
			JSON.serialize(new List<NamedRange.NamedRangeDO>{ namedRangeDO })
		);
		System.assertEquals(result, true, 'should return success');
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetNamedRangesForQuote() {
		NamedRange__c newNamedRange = newNamedRange();

		Test.startTest();
		List<NamedRange.NamedRangeDO> quoteNamedRanges = NamedRangeService.getNamedRangesForQuote(
			newNamedRange.QuoteId__c
		);
		System.assertEquals(1, quoteNamedRanges.size(), 'should return 1 named range');
		System.assertEquals(
			newNamedRange.Id,
			quoteNamedRanges[0].namedRangeId,
			'should return named range for quote'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetQuoteTotalNamedRange() {
		NamedRange__c newNamedRange = newNamedRange();
		newNamedRange.Type__c = NamedRange.TYPE_QUOTE;
		CRUDUtility.updateRecords(newNamedRange);

		Test.startTest();
		NamedRange.NamedRangeDO quoteNamedRange = NamedRangeService.getQuoteTotalForQuote(
			newNamedRange.QuoteId__c
		);

		System.assertEquals(
			newNamedRange.Id,
			quoteNamedRange?.namedRangeId,
			'should return quote total named range'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldNotGetQuoteTotalNamedRange() {
		NamedRange__c newNamedRange = newNamedRange();

		Test.startTest();
		NamedRange.NamedRangeDO quoteNamedRange = NamedRangeService.getQuoteTotalForQuote(
			newNamedRange.QuoteId__c
		);
		System.assertEquals(null, quoteNamedRange, 'should not return quote total named range');
		Test.stopTest();
	}
}
