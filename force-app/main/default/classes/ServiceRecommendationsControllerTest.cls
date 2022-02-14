/**
 *  Provus Services Quoting
 *  ServiceRecommendationsControllerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
public with sharing class ServiceRecommendationsControllerTest extends ServiceRecommendationsTestsBase {
	private static final String PRODUCT_MAIN_PRODUCT = 'Main Product';
	private static final String PRODUCT_SERVICE_PRODUCT = 'Service Product';
	private static final String QUOTE_TEMPLATE_NAME = 'Test Quote Template';

	@testSetup
	static void setup() {
		setupData();
		createProductOpportunityLineItem();
	}

	@isTest
	static void itShouldGetServiceRecommendations() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Map<Id, ServiceRecommendationsController.ServiceRecommendation> serviceRecommendations = ServiceRecommendationsController.getServiceRecommendations(
			opp.Id
		);
		System.assertEquals(1, serviceRecommendations.size(), 'There is 1 service recommendation');
		Test.stopTest();
	}

	@isTest
	static void itShouldGetNoServiceRecommendations() {
		Test.startTest();
		Opportunity opp = newOpportunity();
		Map<Id, ServiceRecommendationsController.ServiceRecommendation> serviceRecommendations = ServiceRecommendationsController.getServiceRecommendations(
			opp.Id
		);
		System.assertEquals(0, serviceRecommendations.size(), 'There are no service recommendation');
		Test.stopTest();
	}

	@isTest
	static void itShouldAddServiceRecommendations() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);
		System.assert(serviceOpportunity.success, 'Service recommendation was added successfully');
		Test.stopTest();
	}

	@isTest
	static void itShouldFailServiceRecommendationsForMissingEstimate() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		Estimate__c estimate = [SELECT Id FROM Estimate__c WHERE ServiceId__c = :service.Id LIMIT 1];
		delete estimate;
		// ignore initial setup data
		List<Quote__c> quotes = [SELECT Id FROM Quote__c WHERE ServiceId__c = :service.Id];
		delete quotes;
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);
		System.assert(
			!serviceOpportunity.success,
			'It should have failed to return any service recommendations'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldGenerateFromQuoteTemplateForServiceRecommendations() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		Estimate__c estimate = [SELECT Id FROM Estimate__c WHERE ServiceId__c = :service.Id LIMIT 1];
		Quote__c quoteSO = [
			SELECT Id, Name, Type__c
			FROM Quote__c
			WHERE EstimateId__c = :estimate.Id
			LIMIT 1
		];

		Quote__c quoteTemplate = QuoteService.cloneQuote(quoteSO.Id);
		quoteTemplate.Type__c = QuoteService.RECORDTYPE_NAME_TEMPLATE;
		quoteTemplate.Name = 'TEMPLATE FROM: ' + quoteSO.Name;
		quoteTemplate.AccountId__c = null;
		quoteTemplate.OpportunityId__c = null;
		quoteTemplate.TemplateId__c = null;
		update quoteTemplate;
		delete quoteSO;
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);
		System.assert(
			serviceOpportunity.success,
			'It should have created a quote and associated to opportunity for a quote template'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldGenerateFromQuoteTemplateForServiceRecommendationsWithNoEstimate() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		Estimate__c estimate = [SELECT Id FROM Estimate__c WHERE ServiceId__c = :service.Id LIMIT 1];
		Quote__c quoteSO = [
			SELECT Id, Name, Type__c
			FROM Quote__c
			WHERE EstimateId__c = :estimate.Id
			LIMIT 1
		];
		quoteSO.Type__c = 'Template';
		update quoteSO;

		Quote__c quoteTemplate = QuoteService.cloneQuote(quoteSO.Id);
		quoteTemplate.ServiceId__c = service.Id;
		quoteTemplate.Type__c = QuoteService.RECORDTYPE_NAME_TEMPLATE;
		quoteTemplate.Name = 'TEMPLATE FROM: ' + quoteSO.Name;
		quoteTemplate.AccountId__c = null;
		quoteTemplate.OpportunityId__c = null;
		quoteTemplate.TemplateId__c = null;
		update quoteTemplate;
		delete estimate;
		delete quoteSO;
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);
		System.assert(
			serviceOpportunity.success,
			'It should have created a quote and associated to opportunity for a quote template'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldGenerateFromEstimateForServiceRecommendations() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		Estimate__c estimate = [SELECT Id FROM Estimate__c WHERE ServiceId__c = :service.Id LIMIT 1];
		Quote__c quote = [SELECT Id FROM Quote__c WHERE EstimateId__c = :estimate.Id LIMIT 1];
		delete quote;
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);
		System.assert(
			serviceOpportunity.success,
			'It should have created a quote and associated to opportunity for an estimate'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldGenerateFromUniqueEstimatesForServiceRecommendations() {
		Test.startTest();
		Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_MAIN_PRODUCT];
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = :PRODUCT_SERVICE_PRODUCT];
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity = ServiceRecommendationsController.addServiceToOpportunity(
			opp.Id,
			service.Id,
			product.Id
		);

		Opportunity opp2 = newOpportunity();
		opp2.Name = 'Test2';
		update opp2;
		ServiceRecommendationsController.ServiceOpportunity serviceOpportunity2 = ServiceRecommendationsController.addServiceToOpportunity(
			opp2.Id,
			service.Id,
			product.Id
		);

		System.assertNotEquals(
			serviceOpportunity.opportunityProductServiceQuote.ServiceQuoteId__c,
			serviceOpportunity2.opportunityProductServiceQuote.ServiceQuoteId__c,
			'Quotes should be unique from each other'
		);

		Test.stopTest();
	}
}
