/**
 *  Provus Services Quoting
 *  ServiceRecommendationsSupport
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ServiceRecommendationsSupport {
	public class OpportunityLineItemRequest {
		public List<OpportunityLineItem> opportunityLineItems;
		public Id opportunityId;
		public Id productId;
		public Id pricebookEntryId;
		public NamedRange.NamedRangeDO quoteTotalNamedRange;

		public OpportunityLineItemRequest() {
			this.opportunityLineItems = new List<OpportunityLineItem>();
		}
	}

	public class OpportunityProductServiceQuoteRequest {
		public String name;
		public OpportunityLineItem serviceLineItem;
		public OpportunityLineItem productLineItem;
		public Quote__c serviceQuote;
		public Estimate__c serviceEstimate;
	}

	public static Set<Id> getOpportunityProductIds(Id opportunityId) {
		List<OpportunityLineItem> opportunityProducts = getOpportunityProducts(opportunityId);
		Map<Id, OpportunityLineItem> opportunityProductsByProductId = new Map<Id, OpportunityLineItem>();
		for (OpportunityLineItem opportunityProduct : opportunityProducts) {
			opportunityProductsByProductId.put(opportunityProduct.Product2Id, opportunityProduct);
		}
		return opportunityProductsByProductId.keySet();
	}

	private static List<OpportunityLineItem> getOpportunityProducts(Id opportunityId) {
		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.OpportunityLineItem.getName());
		queryRequest.requestedFields = new Set<String>{ Schema.OpportunityLineItem.Product2Id + '' };
		queryRequest.setFilterBy(
			new Map<String, String>{ Schema.OpportunityLineItem.OpportunityId + '' => opportunityId }
		);
		return (List<OpportunityLineItem>) SOQLUtility.querySObject(queryRequest);
	}

	public static List<Estimate__c> getEstimatesForServiceProducts(Set<Id> serviceProducts) {
		Map<String, String> orderBy = new Map<String, String>{
			Schema.Estimate__c.Default__c + '' => SOQLConstants.SORT_DESC,
			Schema.Estimate__c.CreatedDate + '' => SOQLConstants.SORT_DESC
		};
		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Estimate__c.getName());
		queryRequest.requestedFields = new Set<String>{
			SObjectUtility.FIELD_NAME,
			Schema.Estimate__c.ServiceId__c + '',
			Schema.Estimate__c.RateCardId__c + '',
			Schema.Estimate__c.AccountId__c + '',
			Schema.Estimate__c.Description__c + '',
			Schema.Estimate__c.OpportunityId__c + '',
			Schema.Estimate__c.RateCardId__c + '',
			SystemUtility.getRName(Schema.Estimate__c.ServiceId__c) +
			'.' +
			Schema.Product2.Practice__c,
			SystemUtility.getRName(Schema.Estimate__c.ServiceId__c) +
			'.' +
			Schema.Product2.Group__c
		};
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ Schema.Estimate__c.ServiceId__c + '' => serviceProducts }
		);
		queryRequest.fieldBySortOrder = orderBy;
		return (List<Estimate__c>) SOQLUtility.querySObject(queryRequest);
	}

	public static List<Quote__c> getQuotesForEstimates(Set<Id> estimates) {
		Map<String, String> orderBy = new Map<String, String>{
			Schema.Quote__c.IsPrimary__c + '' => SOQLConstants.SORT_DESC,
			Schema.Quote__c.CreatedDate + '' => SOQLConstants.SORT_DESC
		};
		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Quote__c.getName());
		queryRequest.requestedFields = new Set<String>{ Schema.Quote__c.TotalAmount__c + '' };
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ Schema.Quote__c.EstimateId__c + '' => estimates }
		);
		queryRequest.fieldBySortOrder = orderBy;
		return (List<Quote__c>) SOQLUtility.querySObject(queryRequest);
	}

	public static OpportunityProductServiceQuote__c insertOpportunityProductServiceQuote(
		OpportunityProductServiceQuoteRequest opportunityProductServiceQuoteRequest
	) {
		OpportunityProductServiceQuote__c opportunityProductServiceQuote = new OpportunityProductServiceQuote__c();
		opportunityProductServiceQuote.Name = opportunityProductServiceQuoteRequest.Name;
		opportunityProductServiceQuote.ProductId__c = opportunityProductServiceQuoteRequest.productLineItem.Id;
		opportunityProductServiceQuote.ServiceId__c = opportunityProductServiceQuoteRequest.serviceLineItem.Id;
		opportunityProductServiceQuote.Service__c = opportunityProductServiceQuoteRequest.serviceLineItem.Product2Id;
		opportunityProductServiceQuote.ServiceQuoteId__c = opportunityProductServiceQuoteRequest.serviceQuote.Id;
		opportunityProductServiceQuote.OpportunityId__c = opportunityProductServiceQuoteRequest.serviceQuote.OpportunityId__c;
		if (opportunityProductServiceQuoteRequest.serviceEstimate != null) {
			// if there is an estimate, but there does not have to be one if we have a quote template
			opportunityProductServiceQuote.EstimateId__c = opportunityProductServiceQuoteRequest.serviceEstimate.Id;
		}
		return (OpportunityProductServiceQuote__c) CRUDUtility.insertRecords(
			opportunityProductServiceQuote
		);
	}

	public static List<OpportunityLineItem> upsertOpportunityLineItem(
		OpportunityLineItemRequest opportunityLineItemRequest
	) {
		List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
		for (
			OpportunityLineItem opportunityLineItem : opportunityLineItemRequest.opportunityLineItems
		) {
			Id opportunityId = opportunityLineItemRequest.opportunityId;
			Id productId = opportunityLineItemRequest.productId;
			Id pricebookEntryId = opportunityLineItemRequest.pricebookEntryId;
			if (opportunityId != null) {
				opportunityLineItem.OpportunityId = opportunityId;
			}
			if (productId != null) {
				opportunityLineItem.Product2Id = productId;
			}
			if (pricebookEntryId != null) {
				opportunityLineItem.PricebookEntryId = pricebookEntryId;
			}
			opportunityLineItem.Quantity = 1;
			Decimal totalAmount = 0;
			if (
				opportunityLineItemRequest.quoteTotalNamedRange != null &&
				opportunityLineItemRequest.quoteTotalNamedRange.relatedTotal != null &&
				opportunityLineItemRequest.quoteTotalNamedRange.relatedTotal.totalAmount != null
			) {
				totalAmount = opportunityLineItemRequest.quoteTotalNamedRange.relatedTotal.totalAmount;
			}
			opportunityLineItem.UnitPrice = totalAmount;

			opportunityLineItems.add(opportunityLineItem);
		}
		return (List<OpportunityLineItem>) CRUDUtility.upsertRecords(opportunityLineItems);
	}

	public static List<OpportunityProductServiceQuote__c> getOpportunityProductServiceQuotes(
		Map<String, String> fieldValues
	) {
		Set<String> requestedFields = new Set<String>{
			Schema.OpportunityProductServiceQuote__c.ServiceId__c + '',
			Schema.OpportunityProductServiceQuote__c.ProductId__c + ''
		};
		QueryRequest queryRequest = new QueryRequest(
			Schema.SObjectType.OpportunityProductServiceQuote__c.getName()
		);
		queryRequest.requestedFields = requestedFields;
		queryRequest.setFilterBy(fieldValues);
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = (List<OpportunityProductServiceQuote__c>) SOQLUtility.querySObject(
			queryRequest
		);
		return opportunityProductServiceQuotes;
	}

	public static OpportunityProductServiceQuote__c getOpportunityProductServiceQuote(
		Map<String, String> fieldValues
	) {
		List<OpportunityProductServiceQuote__c> opportunityProductServiceQuotes = getOpportunityProductServiceQuotes(
			fieldValues
		);

		OpportunityProductServiceQuote__c opportunityProductServiceQuote = null;
		if (!opportunityProductServiceQuotes.isEmpty()) {
			opportunityProductServiceQuote = opportunityProductServiceQuotes[0];
		}
		return opportunityProductServiceQuote;
	}

	public static void deleteOpportunityProductServiceQuote(
		List<OpportunityLineItem> opportunityLineItems
	) {
		Map<Id, OpportunityLineItem> opportunityLineItemById = new Map<Id, OpportunityLineItem>(
			opportunityLineItems
		);
		List<OpportunityProductServiceQuote__c> recordsToDelete = new List<OpportunityProductServiceQuote__c>();

		// services
		QueryRequest serviceQueryRequest = new QueryRequest(
			Schema.SObjectType.OpportunityProductServiceQuote__c.getName()
		);
		serviceQueryRequest.setFilterBy(
			new Map<String, Set<Id>>{
				Schema.OpportunityProductServiceQuote__c.ServiceId__c +
				'' => opportunityLineItemById.keySet()
			}
		);
		recordsToDelete.addAll(
			(List<OpportunityProductServiceQuote__c>) SOQLUtility.querySObject(serviceQueryRequest)
		);

		// products
		QueryRequest productQueryRequest = new QueryRequest(
			Schema.SObjectType.OpportunityProductServiceQuote__c.getName()
		);
		productQueryRequest.setFilterBy(
			new Map<String, Set<Id>>{
				Schema.OpportunityProductServiceQuote__c.ProductId__c +
				'' => opportunityLineItemById.keySet()
			}
		);
		recordsToDelete.addAll(
			(List<OpportunityProductServiceQuote__c>) SOQLUtility.querySObject(productQueryRequest)
		);

		CRUDUtility.deleteRecords(recordsToDelete);
	}
}
