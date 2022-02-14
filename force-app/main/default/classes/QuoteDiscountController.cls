public with sharing class QuoteDiscountController {
	@AuraEnabled
	public static Object getNamedRangeTotals(Id recordId) {
		List<NamedRange__c> namedRanges = [
			SELECT
				ID,
				Name,
				NamedRangeTotalId__c,
				NamedRangeTotalId__r.NetExtendedCost__c,
				NamedRangeTotalId__r.NetExtendedAmount__c,
				NamedRangeTotalId__r.MarginPercent__c,
				(
					SELECT ID, Method__c, Type__c, Amount__c
					FROM Adjustments__r
					WHERE Method__c = :Adjustment.METHOD_INITIAL
					LIMIT 1
				)
			FROM NamedRange__c
			WHERE
				QuoteId__c = :recordId
				AND Name IN (
					:NamedRangeTotal.QUOTE_TOTAL_NAMED_RANGE,
					:NamedRangeTotal.LABOR_AMOUNT_NAMED_RANGE,
					:NamedRangeTotal.ADDON_TOTAL_NAMED_RANGE
				)
			WITH SECURITY_ENFORCED
		];

		Object result = wrapRecords(namedRanges);

		return result;
	}

	@TestVisible
	private static Object wrapRecords(List<NamedRange__c> namedRanges) {
		Map<String, Object> records = new Map<String, Object>();
		for (NamedRange__c namedRange : namedRanges) {
			Map<String, Object> record = new Map<String, Object>();
			record.put('Id', namedRange.Id);
			record.put('Name', namedRange.Name);
			record.put('Category', namedRange.Name);
			record.put('CurrentAmount', nullToZero(namedRange.NamedRangeTotalId__r.NetExtendedAmount__c));
			record.put('CurrentMargin', nullToZero(namedRange.NamedRangeTotalId__r.MarginPercent__c));
			record.put('Cost', nullToZero(namedRange.NamedRangeTotalId__r.NetExtendedCost__c));
			record.put('DiscountPercent', 0);
			record.put('DiscountAmount', 0);
			record.put('NewAmount', nullToZero(namedRange.NamedRangeTotalId__r.NetExtendedAmount__c));
			record.put('NewMargin', nullToZero(namedRange.NamedRangeTotalId__r.MarginPercent__c));
			record.put('Currency', 0);
			if (namedRange.Adjustments__r.size() > 0) {
				record.put('DiscountType', namedRange.Adjustments__r[0].Type__c);
				if (namedRange.Adjustments__r[0].Type__c == Adjustment.TYPE_DISCOUNT_AMOUNT) {
					record.put('DiscountAmount', namedRange.Adjustments__r[0].Amount__c);
				} else if (namedRange.Adjustments__r[0].Type__c == Adjustment.TYPE_DISCOUNT_PERCENT) {
					record.put('DiscountPercent', namedRange.Adjustments__r[0].Amount__c);
				}
				record.put('AdjustmentId', namedRange.Adjustments__r[0].Id);
			}
			records.put(namedRange.Name, record);
		}
		return records;
	}

	@TestVisible
	private static Decimal nullToZero(Decimal input) {
		return input == null ? 0 : input;
	}

	@AuraEnabled
	public static void updateAdjustments(String recordString, Quote__c quote) {
		List<Adjustment__c> adjustments = (List<Adjustment__c>) JSON.deserialize(
			recordString,
			List<Adjustment__c>.class
		);
		CRUDUtility.upsertRecords(adjustments);
		CRUDUtility.upsertRecords(quote);
	}
}
