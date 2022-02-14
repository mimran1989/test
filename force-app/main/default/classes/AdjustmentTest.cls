/**
 *  Provus Services Quoting
 *  AdjustmentTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class AdjustmentTest extends TestBase {
	@IsTest
	static void itShouldConstructAdjustmentFromDO() {
		AdjustmentDTO adjustmentDO = new AdjustmentDTO();
		adjustmentDO.type = Adjustment.TYPE_PERCENT_DISCOUNT;
		adjustmentDO.amount = 100;
		adjustmentDO.sequence = 1;
		adjustmentDO.method = Adjustment.METHOD_INITIAL;
		adjustmentDO.type = Adjustment.TYPE_PERCENT_DISCOUNT;
		adjustmentDO.appliedTo = Adjustment.APPLIED_TO_PRICE;
		adjustmentDO.appliedTo = Adjustment.APPLIED_TO_PRICE;
		adjustmentDO.appliedBy = Adjustment.APPLIED_BY_MANUAL;

		Test.startTest();
		Adjustment adjustmentMO = new Adjustment(adjustmentDO);
		Adjustment__c adjustmentSO = (Adjustment__c) adjustmentMO.getSObject();
		System.assertNotEquals(adjustmentMO, null, 'should not be null');
		System.assertEquals(adjustmentSO.Type__c, adjustmentDO.type, 'should copy the type');
		System.assertEquals(
			adjustmentSO.Sequence__c,
			adjustmentDO.sequence,
			'should copy the sequence'
		);
		System.assertEquals(adjustmentSO.Method__c, adjustmentDO.method, 'should copy the method');
		System.assertEquals(
			adjustmentSO.AppliedTo__c,
			adjustmentDO.appliedTo,
			'should copy the applied to'
		);
		System.assertEquals(
			adjustmentSO.AppliedBy__c,
			adjustmentDO.appliedBy,
			'should copy the applied by'
		);
		System.assertEquals(adjustmentSO.Id, adjustmentDO.adjustmentId, 'should copy the Id');
		Test.stopTest();
	}

	@IsTest
	static void itShouldConstructAdjustmentFromSO() {
		Adjustment__c adjustmentSO = new Adjustment__c(
			Type__c = Adjustment.TYPE_PERCENT_DISCOUNT,
			Amount__c = 100,
			Sequence__c = 1,
			Method__c = Adjustment.METHOD_INITIAL,
			AppliedTo__c = Adjustment.APPLIED_TO_PRICE,
			AppliedBy__c = Adjustment.APPLIED_BY_MANUAL
		);
		CRUDUtility.insertRecords(adjustmentSO);

		Test.startTest();
		Adjustment adjustmentMO = new Adjustment(adjustmentSO);
		System.assertNotEquals(adjustmentMO, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldCreateADOFromSO() {
		Adjustment__c adjustmentSO = new Adjustment__c(
			Type__c = Adjustment.TYPE_PERCENT_DISCOUNT,
			Amount__c = 100,
			Sequence__c = 1,
			Method__c = Adjustment.METHOD_INITIAL,
			AppliedTo__c = Adjustment.APPLIED_TO_PRICE,
			AppliedBy__c = Adjustment.APPLIED_BY_MANUAL
		);
		CRUDUtility.insertRecords(adjustmentSO);

		Test.startTest();
		AdjustmentDTO newDO = Adjustment.newAdjustmentDO(adjustmentSO);
		System.assertEquals(newDO.type, adjustmentSO.Type__c, 'should copy the type');
		System.assertEquals(newDO.sequence, adjustmentSO.Sequence__c, 'should copy the sequence');
		System.assertEquals(newDO.method, adjustmentSO.Method__c, 'should copy the method');
		System.assertEquals(newDO.appliedTo, adjustmentSO.AppliedTo__c, 'should copy the applied to');
		System.assertEquals(newDO.appliedBy, adjustmentSO.AppliedBy__c, 'should copy the applied by');
		System.assertEquals(newDO.adjustmentId, adjustmentSO.Id, 'should copy the Id');
		Test.stopTest();
	}
}
