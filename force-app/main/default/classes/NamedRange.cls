/**
 *  Provus Services Quoting
 *  NamedRange
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class NamedRange extends ManagedObject {
	public static final String SOBJECT_NAME = 'NamedRange__c';

	public static final String TYPE_QUOTE = 'Quote';
	public static final String TYPE_QUOTE_ADDONS = 'Quote Ancillaries';
	public static final String TYPE_QUOTE_LABOR = 'Quote Labor';
	public static final String QUOTE_TOTALS_NAME = 'Quote Totals';
	public static final String LABOR_AMOUNT_NAME = 'Labor Amount';
	public static final String ADDON_AMOUNT_NAME = 'Add-Ons Amount';

	private NamedRangeTotal namedRangeTotalMO;
	private List<Adjustment> adjustmentMOs = new List<Adjustment>();

	public class NamedRangeDO extends BaseDTO {
		public String name;
		public Id namedRangeId;
		public Id quoteId;
		public Id quoteItemId;
		public Id quotePeriodId;
		public Id quotePeriodGroupId;
		public Id quoteSectionId;
		public Id projectPhaseId;
		public String type;
		public String rangeSpec;

		public NamedRangeTotal.NamedRangeTotalDO relatedTotal;
		public List<AdjustmentDTO> adjustmentList;
	}

	public NamedRange(NamedRangeDO namedRangeDO) {
		super(namedRangeDO);
		initialize(namedRangeDO);
	}

	public NamedRange(NamedRange__c namedRangeSO) {
		super(newNamedRangeDO(namedRangeSO));
		initialize(namedRangeSO);
	}

	@TestVisible
	private List<Adjustment> getAdjustments() {
		return this.adjustmentMOs;
	}

	@TestVisible
	private NamedRangeTotal getNamedRangeTotal() {
		return this.namedRangeTotalMO;
	}

	public static void commitNamedRanges(List<NamedRange> namedRangesToCommit) {
		List<NamedRange> namedRangesToUpsert = new List<NamedRange>();
		List<NamedRange__c> namedRangesSOsToDelete = new List<NamedRange__c>();
		List<NamedRange__c> namedRangesSOsToUpsert = new List<NamedRange__c>();

		for (NamedRange namedRange : namedRangesToCommit) {
			NamedRange__c namedRangeSO = (NamedRange__c) namedRange.getSObject();
			if (namedRange.isDelete()) {
				namedRangesSOsToDelete.add(namedRangeSO);
			} else {
				namedRangesSOsToUpsert.add(namedRangeSO);
				namedRangesToUpsert.add(namedRange);
			}
		}

		commitNamedRangeTotalsFor(namedRangesToCommit);
		resolveNamedRangeTotalIds(namedRangesToUpsert);

		CRUDUtility.deleteRecords(namedRangesSOsToDelete);
		CRUDUtility.upsertRecords(namedRangesSOsToUpsert);

		resolveNamedRangeIdsForAdjustments(namedRangesToCommit);
		commitAdjustmentsFor(namedRangesToCommit);
	}

	private static void commitNamedRangeTotalsFor(List<NamedRange> namedRanges) {
		List<NamedRangeTotal__c> namedRangeTotalsToDelete = new List<NamedRangeTotal__c>();
		List<NamedRangeTotal__c> namedRangeTotalsToUpsert = new List<NamedRangeTotal__c>();
		List<Quote__c> quotesToUpdate = new List<Quote__c>();

		for (NamedRange namedRange : namedRanges) {
			NamedRangeTotal namedRangeTotal = namedRange.getNamedRangeTotal();
			NamedRangeTotal__c namedRangeTotalSO = (NamedRangeTotal__c) namedRangeTotal.getSObject();

			if (namedRangeTotal.isDelete()) {
				namedRangeTotalsToDelete.add(namedRangeTotalSO);
			} else {
				namedRangeTotalsToUpsert.add(namedRangeTotalSO);
			}

			if (namedRange.isQuoteTotal()) {
				NamedRange__c namedRangeSO = (NamedRange__c) namedRange.getSObject();
				Quote__c quoteSO = new Quote__c(
					Id = namedRangeSO.QuoteId__c,
					TotalAmount__c = namedRangeTotalSO.NetExtendedAmount__c,
					TotalCost__c = namedRangeTotalSO.NetExtendedCost__c,
					MarginPercent__c = namedRangeTotalSO.MarginPercent__c
				);
				quotesToUpdate.add(quoteSO);
			}
		}

		CRUDUtility.deleteRecords(namedRangeTotalsToDelete);
		CRUDUtility.upsertRecords(namedRangeTotalsToUpsert);
		CRUDUtility.updateRecords(quotesToUpdate);
	}

	private static void commitAdjustmentsFor(List<NamedRange> namedRanges) {
		List<Adjustment__c> adjustmentsToDelete = new List<Adjustment__c>();
		List<Adjustment__c> adjustmentsToUpsert = new List<Adjustment__c>();

		for (NamedRange namedRange : namedRanges) {
			List<Adjustment> adjustments = namedRange.getAdjustments();
			for (Adjustment adjustment : adjustments) {
				Adjustment__c adjustmentSO = (Adjustment__c) adjustment.getSObject();
				if (adjustment.isDelete()) {
					adjustmentsToDelete.add(adjustmentSO);
				} else {
					adjustmentsToUpsert.add(adjustmentSO);
				}
			}
		}

		CRUDUtility.deleteRecords(adjustmentsToDelete);
		CRUDUtility.upsertRecords(adjustmentsToUpsert);
	}

	private void initialize(NamedRangeDO namedRangeDO) {
		validate(namedRangeDO);

		NamedRange__c namedRangeSO = newNamedRangeSO(namedRangeDO);
		initialize(namedRangeSO);
	}

	private void initialize(NamedRange__c namedRangeSO) {
		this.pSObject = namedRangeSO;
		NamedRangeDO contextDO = (NamedRangeDO) baseDTO;
		this.namedRangeTotalMO = new NamedRangeTotal(contextDO.quoteId, contextDO.relatedTotal);
		if (contextDO.adjustmentList != null) {
			for (AdjustmentDTO adjustmentDO : contextDO.adjustmentList) {
				Adjustment adjustmentMO = new Adjustment(adjustmentDO);
				this.adjustmentMOs.add(adjustmentMO);
			}
		}
	}

	private void validate(NamedRangeDO namedRangeDO) {
		if (namedRangeDO.relatedTotal == null) {
			throw new ApplicationException('Named Range DO requires a related total.');
		}
	}

	public Boolean isQuoteTotal() {
		NamedRange__c namedRangeSO = (NamedRange__c) getSObject();
		return namedRangeSO.Type__c == TYPE_QUOTE;
	}

	private static NamedRangeDO newNamedRangeDO(NamedRange__c namedRangeSO) {
		NamedRangeDO namedRangeDO = new NamedRangeDO();
		namedRangeDO.name = namedRangeSO.Name;
		namedRangeDO.namedRangeId = namedRangeSO.Id;
		namedRangeDO.quoteId = namedRangeSO.QuoteId__c;
		namedRangeDO.quoteItemId = namedRangeSO.QuoteItemId__c;
		namedRangeDO.quotePeriodId = namedRangeSO.QuotePeriodId__c;
		namedRangeDO.quotePeriodGroupId = namedRangeSO.QuotePeriodGroupId__c;
		namedRangeDO.quoteSectionId = namedRangeSO.QuoteSectionId__c;
		namedRangeDO.projectPhaseId = namedRangeSO.ProjectPhaseId__c;
		namedRangeDO.type = namedRangeSO.Type__c;
		namedRangeDO.rangeSpec = namedRangeSO.RangeSpecJSON__c;
		namedRangeDO.relatedTotal = NamedRangeTotal.newNamedRangeTotalDO(
			namedRangeSO.NamedRangeTotalId__r
		);

		namedRangeDO.adjustmentList = new List<AdjustmentDTO>();
		for (Adjustment__c adjustmentSO : namedRangeSO.Adjustments__r) {
			AdjustmentDTO adjustment = Adjustment.newAdjustmentDO(adjustmentSO);
			namedRangeDO.adjustmentList.add(adjustment);
		}

		return namedRangeDO;
	}

	private NamedRange__c newNamedRangeSO(NamedRangeDO namedRangeDO) {
		NamedRange__c namedRangeSO = new NamedRange__c(
			Name = namedRangeDO.name,
			Id = namedRangeDO.namedRangeId,
			QuoteItemId__c = namedRangeDO.quoteItemId,
			QuotePeriodId__c = namedRangeDO.quotePeriodId,
			QuotePeriodGroupId__c = namedRangeDO.quotePeriodGroupId,
			QuoteSectionId__c = namedRangeDO.quoteSectionId,
			ProjectPhaseId__c = namedRangeDO.projectPhaseId,
			Type__c = namedRangeDO.type,
			RangeSpecJSON__c = namedRangeDO.rangeSpec,
			QuoteId__c = namedRangeDO.quoteId
		);
		return namedRangeSO;
	}

	private static void resolveNamedRangeIdsForAdjustments(List<NamedRange> namedRangeMOs) {
		for (NamedRange namedRange : namedRangeMOs) {
			NamedRange__c namedRangeSO = (NamedRange__c) namedRange.getSObject();
			for (Adjustment adjustmentMO : namedRange.getAdjustments()) {
				Adjustment__c adjustmentSO = (Adjustment__c) adjustmentMO.getSObject();
				adjustmentSO.NamedRangeId__c = namedRangeSO.Id;
			}
		}
	}

	private static void resolveNamedRangeTotalIds(List<NamedRange> namedRangeMOs) {
		for (NamedRange namedRange : namedRangeMOs) {
			NamedRangeTotal namedRangeTotal = namedRange.getNamedRangeTotal();
			NamedRange__c namedRangeSO = (NamedRange__c) namedRange.getSObject();
			NamedRangeTotal__c namedRangeTotalSO = (NamedRangeTotal__c) namedRangeTotal.getSObject();

			namedRangeSO.NamedRangeTotalId__c = namedRangeTotalSO.Id;
		}
	}
}
