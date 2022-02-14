/**
 *  Provus Services Quoting
 *  AdjustmentDTO
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class AdjustmentDTO extends BaseDTO {
	public String type;
	public Decimal amount;
	public Decimal sequence;
	public String method;
	public String appliedTo;
	public String appliedBy;
	public Id adjustmentId;

	public AdjustmentDTO() {
	}

	public Adjustment__c getSObject() {
		Adjustment__c adjustmentSO = new Adjustment__c(
			Type__c = this.type,
			Amount__c = this.amount,
			Sequence__c = this.sequence,
			Method__c = this.method,
			AppliedTo__c = this.appliedTo,
			AppliedBy__c = this.appliedBy,
			Id = this.adjustmentId
		);
		return adjustmentSO;
	}
}
