/**
 *  Provus Services Quoting
 *  ManagedObjectTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
public with sharing class ManagedObjectTest extends TestBase {
	@IsTest
	static void itShouldReturnFalseForAllOperations() {
		BaseDTO newManagedDO = new BaseDTO();

		Test.startTest();
		ManagedObject testManagedObject = new ManagedObject(newManagedDO);

		System.assertEquals(
			false,
			testManagedObject.isDelete(),
			'should return false for delete operation'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnManagedDO() {
		BaseDTO newManagedDO = new BaseDTO();

		Test.startTest();
		ManagedObject testManagedObject = new ManagedObject(newManagedDO);
		System.assertEquals(newManagedDO, testManagedObject.baseDTO, 'should return the managed DO');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnManagedSO() {
		Quote__c quoteSO = newQuote();

		Test.startTest();
		ManagedObject testManagedObject = new ManagedObject(quoteSO);
		System.assertEquals(
			quoteSO,
			(Quote__c) testManagedObject.getSObject(),
			'should return the sObject DO'
		);
		Test.stopTest();
	}
}
