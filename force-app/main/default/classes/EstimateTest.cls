/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
@IsTest
private class EstimateTest extends TestBase {
	@IsTest
	static void shouldCopyFieldsFromTemplate() {
		RateCard__c rateCardSO = newRateCard();
		Id resourceRoleTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Resource Role');
		Product2 productSO = newProduct('Test', resourceRoleTypeId);
		EstimateTemplate__c template = new EstimateTemplate__c(
			Name = 'Test',
			Description__c = 'Test',
			Guidance__c = 'Test',
			RateCardId__c = rateCardSO.Id,
			ProductId__c = productSO.Id,
			ServiceId__c = productSO.Id
		);

		Test.startTest();
		Estimate__c estimateSO = Estimate.newSO(template);
		System.assertEquals(template.Name, estimateSO.Name, 'should have the same name');
		System.assertEquals(
			template.Description__c,
			estimateSO.Description__c,
			'should have the same description'
		);
		System.assertEquals(
			template.Guidance__c,
			estimateSO.Guidance__c,
			'should have the same guidance'
		);
		System.assertEquals(
			template.RateCardId__c,
			estimateSO.RateCardId__c,
			'should have the same sequence'
		);
		System.assertEquals(
			template.ProductId__c,
			estimateSO.ProductId__c,
			'should have the same product'
		);
		System.assertEquals(
			template.ServiceId__c,
			estimateSO.ServiceId__c,
			'should have the same service'
		);
		Test.stopTest();
	}
}
