/**
 *  Provus Services Quoting
 *  NamedRangeTotalTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
public with sharing class NamedRangeTotalTest extends TestBase {
	@IsTest
	static void itShouldConstructAdjustmentFromDO() {
		Quote__c testQuote = newQuote();
		NamedRangeTotal.NamedRangeTotalDO namedRangeTotalDO = new NAmedRangeTotal.NamedRangeTotalDO();
		namedRangeTotalDO.totalAmount = 200;
		namedRangeTotalDO.totalCost = 100;
		namedRangeTotalDO.marginPercent = 100;
		namedRangeTotalDO.totalQuantity = 1;

		Test.startTest();
		NamedRangeTotal namedRangeTotalMO = new NamedRangeTotal(testQuote.Id, namedRangeTotalDO);
		NamedRangeTotal__c namedRangeTotalSO = (NamedRangeTotal__c) namedRangeTotalMO.getSObject();
		System.assertNotEquals(namedRangeTotalMO, null, 'should not be null');
		System.assertEquals(
			namedRangeTotalSO.NetExtendedAmount__c,
			namedRangeTotalDO.totalAmount,
			'should copy the total revenue'
		);
		System.assertEquals(
			namedRangeTotalSO.NetExtendedCost__c,
			namedRangeTotalDO.totalCost,
			'should copy the total cost'
		);
		System.assertEquals(
			namedRangeTotalSO.Quantity__c,
			namedRangeTotalDO.totalQuantity,
			'should copy the total quantity'
		);
		System.assertEquals(
			namedRangeTotalSO.MarginPercent__c,
			namedRangeTotalDO.marginPercent,
			'should copy the margin percent'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldCreateADOFromSO() {
		Quote__c testQuote = newQuote();
		NamedRangeTotal__c namedRangeTotalSO = new NamedRangeTotal__c(
			NetExtendedAmount__c = 200,
			NetExtendedCost__c = 100,
			MarginPercent__c = 100,
			Quantity__c = 1,
			QuantityUOM__c = 'Hour',
			QuoteId__c = testQuote.Id
		);
		CRUDUtility.insertRecords(namedRangeTotalSO);

		Test.startTest();
		NamedRangeTotal.NamedRangeTotalDO namedRangeTotalDO = NamedRangeTotal.newNamedRangeTotalDO(
			namedRangeTotalSO
		);
		System.assertEquals(
			namedRangeTotalDO.totalAmount,
			namedRangeTotalSO.NetExtendedAmount__c,
			'should copy the total revenue'
		);
		System.assertEquals(
			namedRangeTotalDO.totalCost,
			namedRangeTotalSO.NetExtendedCost__c,
			'should copy the total cost'
		);
		System.assertEquals(
			namedRangeTotalDO.totalQuantity,
			namedRangeTotalSO.Quantity__c,
			'should copy the total quantity'
		);
		System.assertEquals(
			namedRangeTotalDO.marginPercent,
			namedRangeTotalSO.MarginPercent__c,
			'should copy the margin percent'
		);
		System.assertEquals(
			namedRangeTotalDO.quantityUOM,
			namedRangeTotalSO.QuantityUOM__c,
			'should copy the quantity uom'
		);
		Test.stopTest();
	}
}
