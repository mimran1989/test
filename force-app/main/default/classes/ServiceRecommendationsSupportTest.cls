/**
 *  Provus Services Quoting
 *  ServiceRecommendationsSupportTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
public with sharing class ServiceRecommendationsSupportTest extends ServiceRecommendationsTestsBase {
	@testSetup
	static void setup() {
		setupData();
	}

	@isTest
	static void itShouldCreateNewOpportunityLineItem() {
		Test.startTest();
		OpportunityLineItem actualOppLineItem = createProductOpportunityLineItem();
		System.assertNotEquals(
			null,
			actualOppLineItem.Id,
			'Opportunity line item should have been inserted properly'
		);
		System.assertEquals(1000, actualOppLineItem.UnitPrice, 'Opportunity line item should be 1000');
		Test.stopTest();
	}

	@isTest
	static void itShouldUpdateOpportunityLineItem() {
		Test.startTest();
		OpportunityLineItem oppLineItem = createOpportunityLineItem();
		ServiceRecommendationsSupport.OpportunityLineItemRequest oppLineItemRequest = new ServiceRecommendationsSupport.OpportunityLineItemRequest();
		oppLineItemRequest.opportunityLineItems.add(oppLineItem);
		NamedRange.NamedRangeDO quoteTotalNamedRange = new NamedRange.NamedRangeDO();
		quoteTotalNamedRange.relatedTotal = new NamedRangeTotal.NamedRangeTotalDO();
		quoteTotalNamedRange.relatedTotal.totalAmount = 2000;
		oppLineItemRequest.quoteTotalNamedRange = quoteTotalNamedRange;
		List<OpportunityLineItem> oppoLineItems = ServiceRecommendationsSupport.upsertOpportunityLineItem(
			oppLineItemRequest
		);
		OpportunityLineItem actualOppLineItem = oppoLineItems[0];
		System.assertEquals(2000, actualOppLineItem.UnitPrice, 'Opportunity line item should be 2000');
		Test.stopTest();
	}

	@isTest
	static void itShouldRetrieveOpportunityLineItems() {
		Test.startTest();
		createOpportunityLineItem();
		Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		Set<Id> opportunityProductIds = ServiceRecommendationsSupport.getOpportunityProductIds(opp.Id);
		System.assertEquals(
			1,
			opportunityProductIds.size(),
			'One opportunity line item should be associated to the opportunity'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldRetrieveEstimates() {
		Test.startTest();
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = 'Service Product' LIMIT 1];
		Set<Id> serviceProducts = new Set<Id>{ service.Id };
		List<Estimate__c> estimates = ServiceRecommendationsSupport.getEstimatesForServiceProducts(
			serviceProducts
		);
		System.assertEquals(1, estimates.size(), 'There is 1 estimate for service product');
		Test.stopTest();
	}

	@isTest
	static void itShouldRetrieveQuotes() {
		Test.startTest();
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = 'Service Product' LIMIT 1];
		Estimate__c estimate = [
			SELECT Id, ServiceId__c
			FROM Estimate__c
			WHERE ServiceId__c = :service.Id
			LIMIT 1
		];
		Set<Id> estimates = new Set<Id>{ estimate.Id };
		List<Quote__c> quotes = ServiceRecommendationsSupport.getQuotesForEstimates(estimates);
		System.assertEquals(1, quotes.size(), 'There is only 1 quote for this estimate');
		Test.stopTest();
	}

	private static ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest createOpportunityProductServiceQuoteRequest() {
		ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest request = new ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest();
		request.name = 'Main Product';
		request.productLineItem = createProductOpportunityLineItem();
		request.serviceLineItem = createOpportunityLineItem();
		Product2 service = [SELECT Id, Name FROM Product2 WHERE Name = 'Service Product' LIMIT 1];
		Estimate__c estimate = [
			SELECT Id, ServiceId__c
			FROM Estimate__c
			WHERE ServiceId__c = :service.Id
			LIMIT 1
		];
		Quote__c quote = [
			SELECT Id, OpportunityId__c
			FROM Quote__c
			WHERE EstimateId__c = :estimate.Id
			LIMIT 1
		];
		request.serviceEstimate = estimate;
		request.serviceQuote = quote;
		return request;
	}

	@isTest
	static void itShouldGetRecords() {
		Test.startTest();
		// data setup
		ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest request = createOpportunityProductServiceQuoteRequest();
		ServiceRecommendationsSupport.insertOpportunityProductServiceQuote(request);
		// assertions
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = ServiceRecommendationsSupport.getOpportunityProductServiceQuotes(
			new Map<String, String>{
				Schema.OpportunityProductServiceQuote__c.ServiceQuoteId__c + '' => request.serviceQuote.Id
			}
		);
		OpportunityProductServiceQuote__c opportunityProductServiceQuote = opportunityProductServiceQuotes[0];
		System.assertNotEquals(
			null,
			opportunityProductServiceQuote,
			'OpportunityProductServiceQuote__c should exist'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldCreateOpportunityProductServiceQuote() {
		Test.startTest();
		ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest request = createOpportunityProductServiceQuoteRequest();
		OpportunityProductServiceQuote__c opportunityProductServiceQuote = ServiceRecommendationsSupport.insertOpportunityProductServiceQuote(
			request
		);
		System.assertNotEquals(
			null,
			opportunityProductServiceQuote.Id,
			'Id should exist for new OpportunityProductServiceQuote__c'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldDeleteOpportunityProductServiceQuoteFromProductOpportunityLineItem() {
		Test.startTest();
		// data setup
		ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest request = createOpportunityProductServiceQuoteRequest();
		ServiceRecommendationsSupport.insertOpportunityProductServiceQuote(request);
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = [
			SELECT Id
			FROM OpportunityProductServiceQuote__c
		];
		System.assertEquals(
			1,
			opportunityProductServiceQuotes.size(),
			'There should be 1 OpportunityProductServiceQuote__c'
		);
		delete request.productLineItem;
		// assertion
		opportunityProductServiceQuotes = [SELECT Id FROM OpportunityProductServiceQuote__c];
		System.assertEquals(
			0,
			opportunityProductServiceQuotes.size(),
			'There should be 0 OpportunityProductServiceQuote__c'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldDeleteOpportunityProductServiceQuoteFromServiceOpportunityLineItem() {
		Test.startTest();
		// data setup
		ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest request = createOpportunityProductServiceQuoteRequest();
		ServiceRecommendationsSupport.insertOpportunityProductServiceQuote(request);
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = [
			SELECT Id
			FROM OpportunityProductServiceQuote__c
		];
		System.assertEquals(
			1,
			opportunityProductServiceQuotes.size(),
			'There should be 1 OpportunityProductServiceQuote__c'
		);
		delete request.serviceLineItem;
		// assertion
		opportunityProductServiceQuotes = [SELECT Id FROM OpportunityProductServiceQuote__c];
		System.assertEquals(
			0,
			opportunityProductServiceQuotes.size(),
			'There should be 0 OpportunityProductServiceQuote__c'
		);
		Test.stopTest();
	}
}
