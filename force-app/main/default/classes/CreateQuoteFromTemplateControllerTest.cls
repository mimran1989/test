/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private class CreateQuoteFromTemplateControllerTest extends TestBase {
	@TestSetup
	static void setup() {
		Quote__c quote = TestBase.newQuote();
		quote.ServiceStartDate__c = Date.valueOf('2021-01-01');
		quote.ServiceEndDate__c = Date.valueOf('2021-12-31');
		CRUDUtility.updateRecords(quote);

		newOpportunity();
	}

	@IsTest
	static void testRetrieveQuoteTemplateDetails() {
		Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];

		Test.startTest();
		System.assertNotEquals(
			CreateQuoteFromTemplateController.retrieveQuoteTemplateDetails(quote.Id),
			null,
			'should return a quote'
		);
		Test.stopTest();
	}

	@IsTest
	static void testComputeNewEndDate() {
		Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];

		Test.startTest();
		System.assertEquals(
			CreateQuoteFromTemplateController.computeNewEndDate(quote.Id, '2022-01-01'),
			'"2022-12-31"',
			'should return the new JSON formatted end date'
		);
		Test.stopTest();
	}

	@IsTest
	static void testGetOpportunityDetails() {
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

		Test.startTest();
		System.assertEquals(
			CreateQuoteFromTemplateController.getOpportunityDetails(opp.Id).Id,
			opp.Id,
			'should return the opportunity with the given ID'
		);
		Test.stopTest();
	}
}
