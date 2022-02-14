/**
 *  Provus Services Quoting
 *  CRUDUtilityTest
 *  @2021 Provus Inc. All rights reserved.
 */

@isTest
private class CRUDUtilityTest extends TestBase {
	@isTest
	static void itShouldInsertSingleRecord() {
		Test.startTest();
		Quote__c quote = new Quote__c();
		SObject responseSO = CRUDUtility.insertRecords(quote);
		System.assertNotEquals(null, responseSO.Id, 'should have id if it was inserted');

		Test.stopTest();
	}

	@isTest
	static void itShouldNotInsertSingleRecord() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSO = CRUDUtility.insertRecords(nullSObject);
		System.assertEquals(null, responseSO, 'should return null for null input');
		Test.stopTest();
	}

	@isTest
	static void itShouldInsertMultipleRecords() {
		Test.startTest();
		List<Quote__c> quotes = new List<Quote__c>{ new Quote__c(), new Quote__c() };
		List<SObject> responseSOs = CRUDUtility.insertRecords(quotes);
		System.assertNotEquals(null, responseSOs[0].Id, 'should have id if it was inserted');
		System.assertNotEquals(null, responseSOs[1].Id, 'should have id if it was inserted');
		Test.stopTest();
	}

	@isTest
	static void itShouldNotInsertMultipleRecords() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSOs = CRUDUtility.insertRecords(nullSObject);
		List<SObject> responseSOsEmptyList = CRUDUtility.insertRecords(new List<SObject>());
		System.assertEquals(null, responseSOs, 'should return a null response for null input');
		System.assertEquals(
			true,
			responseSOsEmptyList.isEmpty(),
			'should return an empty list for empty list input'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldUpdateSingleRecord() {
		Test.startTest();
		Quote__c quote = newQuote();
		System.assertNotEquals(null, quote.Id, 'Id should not be null if we are updating');
		System.assertEquals(null, quote.Name, 'should have default name as null');
		quote.Name = 'Updated Quote Name';
		Quote__c responseSO = (Quote__c) CRUDUtility.updateRecords(quote);
		System.assertEquals(
			'Updated Quote Name',
			responseSO.Name,
			'should have updated name to Updated Quote Name'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldNotUpdateSingleRecord() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSO = CRUDUtility.updateRecords(nullSObject);
		System.assertEquals(null, responseSO, 'should return null for null input');
		Test.stopTest();
	}

	@isTest
	static void itShouldUpdateMultipleRecords() {
		Test.startTest();
		List<Quote__c> quotes = new List<Quote__c>{ newQuote(), newQuote() };
		quotes[0].Name = 'Updated Quote Name #0';
		quotes[1].Name = 'Updated Quote Name #1';
		System.assertNotEquals(null, quotes[0].Id, 'Id should not be null if we are updating');
		System.assertNotEquals(null, quotes[1].Id, 'Id should not be null if we are updating');
		List<Quote__c> responseSOs = (List<Quote__c>) CRUDUtility.updateRecords(quotes);
		System.assertEquals(
			'Updated Quote Name #0',
			responseSOs[0].Name,
			'should have updated name to Updated Quote Name #0'
		);
		System.assertEquals(
			'Updated Quote Name #1',
			responseSOs[1].Name,
			'should have updated name to Updated Quote Name #1'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldNotUpdateMultipleRecords() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSOs = CRUDUtility.updateRecords(nullSObject);
		List<SObject> responseSOsEmptyList = CRUDUtility.updateRecords(new List<SObject>());
		System.assertEquals(null, responseSOs, 'should return a null response for null input');
		System.assertEquals(
			true,
			responseSOsEmptyList.isEmpty(),
			'should return an empty list for empty list input'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldUpsertSingleNewRecord() {
		Test.startTest();
		Quote__c quote = new Quote__c();
		System.assertEquals(null, quote.Id, 'Id should be null because it hasn not been inserted');
		System.assertEquals(null, quote.Name, 'should have default name as null');
		Quote__c responseSO = (Quote__c) CRUDUtility.upsertRecords(quote);
		System.assertNotEquals(null, responseSO.Id, 'should have id');
		Test.stopTest();
	}

	@isTest
	static void itShouldNotUpsertSingleRecord() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSO = CRUDUtility.upsertRecords(nullSObject);
		System.assertEquals(null, responseSO, 'should return null for null input');
		Test.stopTest();
	}

	@isTest
	static void itShouldUpsertSingleExistingRecord() {
		Test.startTest();
		Quote__c quote = newQuote();
		System.assertEquals(null, quote.Name, 'should have default name as null');
		quote.Name = 'Updated Quote Name';
		Quote__c responseSO = (Quote__c) CRUDUtility.upsertRecords(quote);
		System.assertEquals(
			'Updated Quote Name',
			responseSO.Name,
			'should have updated name to Updated Quote Name'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldNotUpsertMultipleRecords() {
		Test.startTest();
		SObject nullSObject = null;
		SObject responseSOs = CRUDUtility.upsertRecords(nullSObject);
		List<SObject> responseSOsEmptyList = CRUDUtility.upsertRecords(new List<SObject>());
		System.assertEquals(null, responseSOs, 'should return a null response for null input');
		System.assertEquals(
			true,
			responseSOsEmptyList.isEmpty(),
			'should return an empty list for empty list input'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldUpsertMultipleRecords() {
		Test.startTest();
		List<Quote__c> quotes = new List<Quote__c>{ new Quote__c(), newQuote() };
		quotes[0].Name = 'Updated Quote Name #0';
		quotes[1].Name = 'Updated Quote Name #1';
		System.assertEquals(null, quotes[0].Id, 'Id should be null if we are updating');
		System.assertNotEquals(null, quotes[1].Id, 'Id should not be null if we are updating');
		List<Quote__c> responseSOs = (List<Quote__c>) CRUDUtility.upsertRecords(quotes);
		System.assertEquals(
			'Updated Quote Name #0',
			responseSOs[0].Name,
			'should have updated name to Updated Quote Name #0'
		);
		System.assertEquals(
			'Updated Quote Name #1',
			responseSOs[1].Name,
			'should have updated name to Updated Quote Name #1'
		);
		Test.stopTest();
	}
}
