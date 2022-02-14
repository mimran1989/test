/**
 *  Provus Services Quoting
 *  QuoteItem
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteItem extends ManagedObject {
	public static final String SOBJECT_NAME = 'QuoteItem__c';
	public static final String LINE_TYPE_MISCELLANEOUS = 'Miscellaneous';

	public QuoteItem(QuoteItemDTO quoteItemDO) {
		super(quoteItemDO);
		initialize(quoteItemDO);
	}

	private void initialize(QuoteItemDTO ctxDO) {
		// initialized by QuoteItem to avoid cyclical dependencies between QuoteItemDO and QuoteItemCell
		this.pSObject = ctxDO.quoteItemSO;

		if (this.pSObject != null) {
			QuoteItem__c ctxSO = (QuoteItem__c) this.pSObject;
			ctxSO.Id = ctxDO.id;
			if (ctxSO.Id == null) {
				ctxSO.QuoteId__c = ctxDO.quoteId;
			}

			ctxSO.ProductId__c = ctxDO.productId;
			ctxSO.RateCardItemId__c = ctxDO.rateCardItemId;
			ctxSO.Sequence__c = ctxDO.lineSequence;
			ctxSO.DisplaySequence__c = ctxDO.displaySequence;
			ctxSO.AdjustmentId__c = ctxDO.adjustmentId;

			ctxDO.isMiscellaneous = ctxSO.LineType__c == LINE_TYPE_MISCELLANEOUS;
		}
	}
}
