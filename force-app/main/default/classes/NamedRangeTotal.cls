/**
 *  Provus Services Quoting
 *  NamedRangeTotal
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class NamedRangeTotal extends ManagedObject {
	// constants
	public static final String SOBJECT_NAME = 'NamedRangeTotal__c';
	public static final String FIELD_NAME_QUOTE_ID = 'QuoteId__c';
	public static final String QUOTE_TOTAL_NAMED_RANGE = 'Quote Totals';
	public static final String LABOR_AMOUNT_NAMED_RANGE = 'Labor Amount';
	public static final String ADDON_TOTAL_NAMED_RANGE = 'Add-Ons Amount';

	public class NamedRangeTotalDO extends BaseDTO {
		public Decimal totalAmount;
		public Decimal totalCost;
		public Decimal marginPercent;
		public Decimal totalQuantity;
		public String quantityUOM;
		public Id namedRangeTotalId;
	}

	public NamedRangeTotal(Id quoteId, NamedRangeTotalDO namedRangeTotalDO) {
		super(namedRangeTotalDO);
		this.pSObject = newNamedRangeTotalSO(quoteId, namedRangeTotalDO);
	}

	public static NamedRangeTotalDO newNamedRangeTotalDO(NamedRangeTotal__c namedRangeTotalSO) {
		NamedRangeTotalDO namedRangeTotalDO = new NamedRangeTotalDO();
		namedRangeTotalDO.namedRangeTotalId = namedRangeTotalSO.Id;
		namedRangeTotalDO.totalAmount = namedRangeTotalSO.NetExtendedAmount__c;
		namedRangeTotalDO.totalCost = namedRangeTotalSO.NetExtendedCost__c;
		namedRangeTotalDO.totalQuantity = namedRangeTotalSO.Quantity__c;
		namedRangeTotalDO.quantityUOM = namedRangeTotalSO.QuantityUOM__c;
		namedRangeTotalDO.marginPercent = namedRangeTotalSO.MarginPercent__c;
		return namedRangeTotalDO;
	}

	private NamedRangeTotal__c newNamedRangeTotalSO(Id quoteId, NamedRangeTotalDO namedRangeTotalDO) {
		NamedRangeTotal__c namedRangeTotalSO = new NamedRangeTotal__c(
			NetExtendedAmount__c = namedRangeTotalDO.totalAmount,
			NetExtendedCost__c = namedRangeTotalDO.totalCost,
			MarginPercent__c = namedRangeTotalDO.marginPercent,
			Quantity__c = namedRangeTotalDO.totalQuantity,
			QuantityUOM__c = namedRangeTotalDO.quantityUOM,
			Id = namedRangeTotalDO.namedRangeTotalId,
			QuoteId__c = quoteId
		);
		return namedRangeTotalSO;
	}
}
