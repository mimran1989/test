/**
 *  Provus Services Quoting
 *  CreateNewScenarioControllerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private class CreateNewScenarioControllerTest extends TestBase {
	@testSetup
	static void setup() {
		Quote__c quote = newQuote();
		quote.Name = 'CreateNewScenario';
		quote.TotalAmount__c = 400000;
		quote.MarginPercent__c = 15;
		CRUDUtility.updateRecords(quote);
	}

	@isTest
	static void itShouldGetQuoteDetails() {
		Test.startTest();
		Quote__c quote = [SELECT Id FROM Quote__c WHERE Name = 'CreateNewScenario' LIMIT 1];
		List<Quote__c> quotes = CreateNewScenarioController.getQuoteDetails(quote.Id);
		Quote__c quoteSO = quotes[0];
		System.assertEquals(400000, quoteSO.TotalAmount__c, 'base quote should have 400k amount');
		System.assertEquals(15, quoteSO.MarginPercent__c, 'base quote should have 15% margin');
		Test.stopTest();
	}

	@isTest
	static void itShouldCloneQuoteToRevenueAdjustmentScenario() {
		Test.startTest();
		Quote__c quote = [SELECT Id FROM Quote__c WHERE Name = 'CreateNewScenario' LIMIT 1];
		CreateNewScenarioController.QuoteAdjustment quoteAdjustment = new CreateNewScenarioController.QuoteAdjustment();
		quoteAdjustment.type = 'Revenue Adjustment';
		quoteAdjustment.name = 'Moderate Revenue Adjustment';
		quoteAdjustment.value = 500000;
		String adjustment = JSON.serialize(quoteAdjustment);
		Id scenarioId = (Id) CreateNewScenarioController.cloneQuoteToScenario(quote.Id, adjustment);
		Quote__c scenario = [SELECT Id, TotalAmount__c FROM Quote__c WHERE Id = :scenarioId LIMIT 1];
		System.assertNotEquals(null, scenario, 'scenario exists if it is not null');
		System.assertEquals(500000, scenario.TotalAmount__c, 'scenario total amount should be 500k');
		Test.stopTest();
	}

	@isTest
	static void itShouldCloneQuoteToMarginAdjustmentScenario() {
		Test.startTest();
		Quote__c quote = [SELECT Id FROM Quote__c WHERE Name = 'CreateNewScenario' LIMIT 1];
		CreateNewScenarioController.QuoteAdjustment quoteAdjustment = new CreateNewScenarioController.QuoteAdjustment();
		quoteAdjustment.type = 'Margin Adjustment';
		quoteAdjustment.name = 'Moderate Margin Adjustment';
		quoteAdjustment.value = 20;
		String adjustment = JSON.serialize(quoteAdjustment);
		Id scenarioId = (Id) CreateNewScenarioController.cloneQuoteToScenario(quote.Id, adjustment);
		Quote__c scenario = [SELECT Id, MarginPercent__c FROM Quote__c WHERE Id = :scenarioId LIMIT 1];
		System.assertNotEquals(null, scenario, 'scenario exists if it is not null');
		System.assertEquals(20, scenario.MarginPercent__c, 'scenario margin adjustment should be 20');
		Test.stopTest();
	}
}
