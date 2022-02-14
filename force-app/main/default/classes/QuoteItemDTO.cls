/**
 *  Provus Services Quoting
 *  QuoteItemDO
 *  @2021 Provus Inc. All rights reserved.
 */
public class QuoteItemDTO extends BaseDTO {
	public static final String LINE_TYPE_MISCELLANEOUS = 'Miscellaneous';

	public Boolean isMiscellaneous = false;
	public Decimal displaySequence;
	public Decimal lineSequence;
	public Decimal sectionSequence;
	public Id adjustmentId;
	public Id id;
	public Id productId;
	public Id quoteId;
	public Id quoteItemCellId;
	public Id rateCardItemId;
	public Id sectionId;
	public Boolean nonBillable;

	public AdjustmentDTO adjustment = new AdjustmentDTO();

	public QuoteItem__c quoteItemSO;
	public Map<String, Decimal> periodValueMap;

	public static QuoteItemDTO newDO(QuoteItem__c quoteItemSO) {
		QuoteItemDTO newDTO = new QuoteItemDTO();
		newDTO.quoteItemSO = quoteItemSO;
		newDTO.id = quoteItemSO.Id;
		newDTO.quoteId = quoteItemSO.QuoteId__c;
		newDTO.productId = quoteItemSO.ProductId__c;
		newDTO.rateCardItemId = quoteItemSO.RateCardItemId__c;
		newDTO.lineSequence = quoteItemSO.Sequence__c;
		newDTO.sectionSequence = quoteItemSO.SectionSequence__c;
		newDTO.displaySequence = quoteItemSO.DisplaySequence__c;
		newDTO.adjustmentId = quoteItemSO.AdjustmentId__c;
		newDTO.adjustment.type = quoteItemSO.AdjustmentId__r.Type__c;
		newDTO.adjustment.amount = quoteItemSO.AdjustmentId__r.Amount__c;
		newDTO.periodValueMap = new Map<String, Decimal>();
		newDTO.sectionId = quoteItemSO.QuoteSectionId__c;
		newDTO.nonBillable = quoteItemSO.NonBillable__c;

		if (!quoteItemSO.QuoteItemCells__r.isEmpty()) {
			newDTO.quoteItemCellId = quoteItemSO.QuoteItemCells__r[0].Id;
			for (QuoteItemCell__c itemCell : quoteItemSO.QuoteItemCells__r) {
				for (String period : QuoteItemCell.getPeriodColumns()) {
					Decimal periodValue = (Decimal) itemCell.get(period);
					if (periodValue != null) {
						String periodToken = period.removeStartIgnoreCase(QuoteItemCell.PERIOD_FIELD_PREFIX)
							.removeEndIgnoreCase(SObjectUtility.CUSTOM_FIELD_INDICATOR);

						newDTO.periodValueMap.put(periodToken, periodValue);
					}
				}
			}
		}

		return newDTO;
	}

	public void refreshDO() {
		this.id = this.quoteItemSO.Id;
		this.quoteId = this.quoteItemSO.QuoteId__c;
		this.productId = this.quoteItemSO.ProductId__c;
		this.rateCardItemId = this.quoteItemSO.RateCardItemId__c;
		this.lineSequence = this.quoteItemSO.Sequence__c;
		this.nonBillable = this.quoteItemSO.NonBillable__c;
		this.displaySequence = this.quoteItemSO.DisplaySequence__c;
		this.adjustmentId = this.quoteItemSO.AdjustmentId__c;
	}

	public void updateSO() {
		if (this.quoteItemSO == null) {
			this.quoteItemSO = new QuoteItem__c();
		}

		quoteItemSO.Id = this.id;
		if (quoteItemSO.QuoteId__c == null) {
			quoteItemSO.QuoteId__c = this.quoteId;
		}

		quoteItemSO.DisplaySequence__c = this.displaySequence;
		quoteItemSO.ProductId__c = this.productId;
		quoteItemSO.QuoteSectionId__c = this.sectionId;
		quoteItemSO.RateCardItemId__c = this.rateCardItemId;
		quoteItemSO.SectionSequence__c = this.sectionSequence;
		quoteItemSO.Sequence__c = this.lineSequence;

		this.isMiscellaneous = quoteItemSO.LineType__c == LINE_TYPE_MISCELLANEOUS;
	}
}
