/**
 *  Provus Services Quoting
 *  NamedRangeFactory
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class NamedRangeFactory {
	public static List<NamedRange__c> getNamedRangesForQuote(Id quoteId) {
		return [
			SELECT
				Id,
				Name,
				ProjectPhaseId__c,
				QuoteId__c,
				QuoteItemId__c,
				QuotePeriodId__c,
				QuotePeriodGroupId__c,
				QuoteSectionId__c,
				RangeSpecJSON__c,
				Type__c,
				NamedRangeTotalId__c,
				NamedRangeTotalId__r.MarginPercent__c,
				NamedRangeTotalId__r.NetExtendedAmount__c,
				NamedRangeTotalId__r.NetExtendedCost__c,
				NamedRangeTotalId__r.Quantity__c,
				NamedRangeTotalId__r.QuantityUOM__c,
				(
					SELECT Id, Amount__c, AppliedBy__c, AppliedTo__c, Method__c, Sequence__c, Type__c
					FROM Adjustments__r
				)
			FROM NamedRange__c
			WHERE QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
		];
	}
}
