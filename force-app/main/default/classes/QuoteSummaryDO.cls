/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteSummaryDO implements Comparable {
	public Decimal totalAmount;
	public Decimal percentageTotalAmount;
	public Decimal totalCost;
	public Decimal percentageTotalCost;
	public Decimal marginPercent;
	public Decimal percentageMarginPercent;
	public Decimal totalQuantity;
	public Decimal percentageTotalQuantity;
	public Decimal sequence;
	public String type;
	public String rowName;

	public QuoteSummaryDO() {
		this.totalAmount = 0;
		this.percentageTotalAmount = 0;
		this.totalCost = 0;
		this.percentageTotalCost = 0;
		this.marginPercent = 0;
		this.percentageMarginPercent = 0;
		this.totalQuantity = 0;
		this.percentageTotalQuantity = 0;
	}

	public QuoteSummaryDO(String summaryType, String summaryName) {
		this();
		this.type = summaryType;
		this.rowName = summaryName;
	}

	public void setSummary(NamedRange__c namedRangeSO) {
		this.totalAmount = SystemUtility.nullToZero(
			namedRangeSO.NamedRangeTotalId__r.NetExtendedAmount__c
		);
		this.totalCost = SystemUtility.nullToZero(namedRangeSO.NamedRangeTotalId__r.NetExtendedCost__c);
		this.marginPercent = SystemUtility.nullToZero(
			namedRangeSO.NamedRangeTotalId__r.MarginPercent__c
		);
		this.totalQuantity = SystemUtility.nullToZero(namedRangeSO.NamedRangeTotalId__r.Quantity__c);

		if (this.type == QuoteSummary.SUMMARYTYPE_PROJECT_PHASE) {
			this.sequence = namedRangeSO.ProjectPhaseId__r.Sequence__c;
		} else if (this.type == QuoteSummary.SUMMARYTYPE_PERIOD_GROUP) {
			this.sequence = namedRangeSO.QuotePeriodGroupId__r.Sequence__c;
		}
	}

	public void setSummary(QuoteSummaryDO quoteSummaryDO) {
		this.marginPercent = SystemUtility.nullToZero(quoteSummaryDO.marginPercent);
		this.totalQuantity = SystemUtility.nullToZero(quoteSummaryDO.totalQuantity);
		this.totalAmount = SystemUtility.nullToZero(quoteSummaryDO.totalAmount);
		this.totalCost = SystemUtility.nullToZero(quoteSummaryDO.totalCost);

		// percentage of totals should always be 100%
		this.percentageTotalAmount = 1;
		this.percentageTotalCost = 1;
		this.percentageTotalQuantity = 1;
	}

	public void addToSummary(NamedRange__c namedRangeSO) {
		this.totalAmount += SystemUtility.nullToZero(
			namedRangeSO.NamedRangeTotalId__r.NetExtendedAmount__c
		);
		this.totalCost += SystemUtility.nullToZero(
			namedRangeSO.NamedRangeTotalId__r.NetExtendedCost__c
		);
		this.totalQuantity += SystemUtility.nullToZero(namedRangeSO.NamedRangeTotalId__r.Quantity__c);

		this.marginPercent = calculateMargin(this.totalAmount, this.totalCost);
	}

	public void addToSummary(QuoteSummaryDO quoteSummaryDO) {
		this.totalAmount += SystemUtility.nullToZero(quoteSummaryDO.totalAmount);
		this.totalCost += SystemUtility.nullToZero(quoteSummaryDO.totalCost);
		this.totalQuantity += SystemUtility.nullToZero(quoteSummaryDO.totalQuantity);
		this.marginPercent = calculateMargin(this.totalAmount, this.totalCost);
	}

	public void calculatePercentages(QuoteSummaryDO quoteSummaryDO) {
		if (NumericHelper.isNonZero(quoteSummaryDO.totalAmount) && this.totalAmount != null) {
			this.percentageTotalAmount = this.totalAmount / quoteSummaryDO.totalAmount;
		}

		if (NumericHelper.isNonZero(quoteSummaryDO.totalCost) && this.totalCost != null) {
			this.percentageTotalCost = this.totalCost / quoteSummaryDO.totalCost;
		}

		if (NumericHelper.isNonZero(quoteSummaryDO.totalQuantity) && this.totalQuantity != null) {
			this.percentageTotalQuantity = this.totalQuantity / quoteSummaryDO.totalQuantity;
		}
	}

	private Decimal calculateMargin(Decimal revenue, Decimal cost) {
		Decimal safeRevenue = 0;
		Decimal safeCost = 0;
		if (revenue != null) {
			safeRevenue = revenue;
		}

		if (cost != null) {
			safeCost = cost;
		}

		Decimal grossProfit = safeRevenue - safeCost;
		return (grossProfit == 0 || safeRevenue == 0) ? 0 : (grossProfit / safeRevenue);
	}

	public Integer compareTo(Object compareTo) {
		QuoteSummaryDO compareSummary = (QuoteSummaryDO) compareTo;
		if (this.sequence == compareSummary.sequence) {
			return 0;
		}

		if (this.sequence > compareSummary.sequence) {
			return 1;
		}

		return -1;
	}
}
