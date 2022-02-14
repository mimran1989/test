/**
 *  Provus Services Quoting
 *  Adjustment
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class Adjustment extends ManagedObject {
	// constants
	public static final String FIELD_APPLIED_TO = 'AppliedTo__c';
	public static final String FIELD_METHOD = 'Method__c';
	public static final String FIELD_TYPE = 'Type__c';

	public static final String SOBJECT_NAME = 'Adjustment__c';

	public static final String TYPE_PERCENT_DISCOUNT = '% Discount';

	public static final String TYPE_DISCOUNT_PERCENT = 'Discount Percent';
	public static final String TYPE_DISCOUNT_AMOUNT = 'Discount Amount';

	public static final String METHOD_INITIAL = 'Initial';

	public static final String APPLIED_TO_PRICE = 'Price';

	public static final String APPLIED_BY_MANUAL = 'Manual';

	public Adjustment(AdjustmentDTO adjustment) {
		super(adjustment);
		this.pSObject = newAdjustmentSO(adjustment);
	}

	public Adjustment(Adjustment__c adjustmentSO) {
		super(adjustmentSO);
		this.baseDTO = newAdjustmentDO(adjustmentSO);
	}

	public static AdjustmentDTO newAdjustmentDO(Adjustment__c adjustmentSO) {
		AdjustmentDTO adjustmentDO = new AdjustmentDTO();
		adjustmentDO.type = adjustmentSO.Type__c;
		adjustmentDO.amount = adjustmentSO.Amount__c;
		adjustmentDO.sequence = adjustmentSO.Sequence__c;
		adjustmentDO.method = adjustmentSO.Method__c;
		adjustmentDO.appliedTo = adjustmentSO.AppliedTo__c;
		adjustmentDO.appliedBy = adjustmentSO.AppliedBy__c;
		adjustmentDO.adjustmentId = adjustmentSO.Id;
		return adjustmentDO;
	}

	private Adjustment__c newAdjustmentSO(AdjustmentDTO adjustmentDO) {
		Adjustment__c adjustmentSO = new Adjustment__c(
			Type__c = adjustmentDO.type,
			Amount__c = adjustmentDO.amount,
			Sequence__c = adjustmentDO.sequence,
			Method__c = adjustmentDO.method,
			AppliedTo__c = adjustmentDO.appliedTo,
			AppliedBy__c = adjustmentDO.appliedBy,
			Id = adjustmentDO.adjustmentId
		);
		return adjustmentSO;
	}
}
