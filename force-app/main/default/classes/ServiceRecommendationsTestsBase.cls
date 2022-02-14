/**
 *  Provus Services Quoting
 *  ServiceRecommendationsTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class ServiceRecommendationsTestsBase extends EstimatorTestsBase {
	public static void setupData() {
		// price book
		Pricebook2 pricebook = newPriceBook();
		// opportunity
		Opportunity opp = newOpportunity();
		// setup products
		Id productTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Product');
		Id serviceTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Service');
		Product2 product = newProduct('Main Product', productTypeId);
		CRUDUtility.insertRecords(product);
		Product2 service = newProduct('Service Product', serviceTypeId);
		service.AssociatedProductId__c = product.Id;
		CRUDUtility.insertRecords(service);
		// pricebook entries
		Id standardPricebookId = Test.getStandardPricebookId();
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{
			newPricebookEntry(standardPricebookId, product.Id),
			newPricebookEntry(standardPricebookId, service.Id),
			newPricebookEntry(pricebook.Id, product.Id),
			newPricebookEntry(pricebook.Id, service.Id)
		};
		CRUDUtility.insertRecords(pricebookEntries);
		// resource roles
		List<Product2> resourceRoles = createResourceRoles();
		// rate card
		RateCard__c rateCard = newRateCardWithItems(resourceRoles);
		// estimates
		EstimateTemplate__c estimateTemplate = newEstimateTemplate();
		estimateTemplate.RateCardId__c = rateCard.Id;
		CRUDUtility.updateRecords(estimateTemplate);
		List<ActivityGroupTemplate__c> activityGroupTemplates = createActivityGroupTemplates(
			estimateTemplate.Id
		);
		List<ActivityTemplate__c> activityTemplates = createActivityTemplates(activityGroupTemplates);
		createTaskTemplates(activityTemplates, resourceRoles);
		Estimate__c estimateSO = CreateEstimateService.createEstimate(estimateTemplate.Id);
		estimateSO.Default__c = true;
		estimateSO.ProductId__c = product.Id;
		estimateSO.ServiceId__c = service.Id;
		CRUDUtility.updateRecords(estimateSO);
		// quote
		Quote__c quote = newQuote();
		quote.Name = 'Test Quote';
		quote.EstimateId__c = estimateSO.Id;
		quote.OpportunityId__c = opp.Id;
		quote.Type__c = 'Template';
		quote.ServiceId__c = service.Id;
		CRUDUtility.updateRecords(quote);
		// quote item
		QuoteItem__c quoteItemSO = new QuoteItem__c();
		quoteItemSO.QuoteId__c = quote.Id;
		quoteItemSO.ProductId__c = service.Id;
		CRUDUtility.insertRecords(quoteItemSO);
		// named range
		NamedRangeTotal__c namedRangeTotal = new NamedRangeTotal__c();
		namedRangeTotal.NetExtendedAmount__c = 1000;
		namedRangeTotal.QuoteId__c = quote.Id;
		CRUDUtility.insertRecords(namedRangeTotal);
		NamedRange__c namedRangeSO = new NamedRange__c();
		namedRangeSO.Name = NamedRange.QUOTE_TOTALS_NAME;
		namedRangeSO.QuoteId__c = quote.Id;
		namedRangeSO.NamedRangeTotalId__c = namedRangeTotal.Id;
		namedRangeSO.Type__c = NamedRange.TYPE_QUOTE;
		CRUDUtility.insertRecords(namedRangeSO);
	}

	public static OpportunityLineItem createProductOpportunityLineItem() {
		Opportunity opp = [
			SELECT Id, Name
			FROM Opportunity
			WHERE Name = 'Test'
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		Product2 product = [
			SELECT Id, Name
			FROM Product2
			WHERE Name = 'Main Product'
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		OpportunityLineItem oppLineItem = new OpportunityLineItem();
		PricebookEntry pricebookEntry = [
			SELECT Id
			FROM PricebookEntry
			WHERE Product2Id = :product.Id
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		ServiceRecommendationsSupport.OpportunityLineItemRequest oppLineItemRequest = new ServiceRecommendationsSupport.OpportunityLineItemRequest();
		oppLineItemRequest.opportunityLineItems.add(oppLineItem);
		oppLineItemRequest.opportunityId = opp.Id;
		oppLineItemRequest.productId = product.Id;
		oppLineItemRequest.pricebookEntryId = pricebookEntry.Id;
		NamedRange.NamedRangeDO quoteTotalNamedRange = new NamedRange.NamedRangeDO();
		quoteTotalNamedRange.relatedTotal = new NamedRangeTotal.NamedRangeTotalDO();
		quoteTotalNamedRange.relatedTotal.totalAmount = 1000;
		oppLineItemRequest.quoteTotalNamedRange = quoteTotalNamedRange;
		List<OpportunityLineItem> opportunityLineItems = ServiceRecommendationsSupport.upsertOpportunityLineItem(
			oppLineItemRequest
		);
		return opportunityLineItems[0];
	}

	public static OpportunityLineItem createOpportunityLineItem() {
		Opportunity opp = [
			SELECT Id, Name
			FROM Opportunity
			WHERE Name = 'Test'
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		Product2 product = [
			SELECT Id, Name
			FROM Product2
			WHERE Name = 'Service Product'
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		PricebookEntry pricebookEntry = [
			SELECT Id
			FROM PricebookEntry
			WHERE Product2Id = :product.Id
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		OpportunityLineItem serviceOpportunityLineItem = newOpportunityLineItem(
			opp.Id,
			product.Id,
			pricebookEntry.Id
		);
		CRUDUtility.insertRecords(serviceOpportunityLineItem);
		return serviceOpportunityLineItem;
	}
}
