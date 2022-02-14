/**
 *  Provus Services Quoting
 *  ServiceRecommendationsController
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ServiceRecommendationsController {
	public class ServiceRecommendation {
		@AuraEnabled
		public Product2 service;
		@AuraEnabled
		public Product2 product;
		@AuraEnabled
		public Decimal serviceUnitPrice;
		@AuraEnabled
		public Boolean hasEstimate;
		@AuraEnabled
		public String currencyCode;

		public ServiceRecommendation() {
			this.hasEstimate = false;
		}
	}

	public class ServiceOpportunity {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public String stackTrace;
		@AuraEnabled
		public String errorMsg;
		@AuraEnabled
		public OpportunityProductServiceQuote__c opportunityProductServiceQuote;
	}

	@AuraEnabled
	public static Map<Id, ServiceRecommendation> getServiceRecommendations(String opportunityId) {
		Map<Id, ServiceRecommendation> serviceRecommendationsByServiceId = new Map<Id, ServiceRecommendation>();

		// products from opportunites
		Set<Id> opportunityProductIds = ServiceRecommendationsSupport.getOpportunityProductIds(
			opportunityId
		);

		if (opportunityProductIds.isEmpty()) {
			return serviceRecommendationsByServiceId;
		}

		// retrieve related services
		List<Product2> serviceProducts = [
			SELECT Id, Name, AssociatedProductId__c, AssociatedProductId__r.Name
			FROM Product2
			WHERE
				AssociatedProductId__c IN :opportunityProductIds
				AND RecordType.Name = :ProductService.RECORDTYPE_NAME_SERVICE
			WITH SECURITY_ENFORCED
		];
		Set<Id> serviceProductIds = (new Map<Id, SObject>(serviceProducts)).keySet();
		// retrieve prices for services
		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.PricebookEntry.getName());
		queryRequest.requestedFields = new Set<String>{
			Schema.PricebookEntry.UnitPrice + '',
			Schema.PricebookEntry.Product2Id + ''
		};
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ Schema.PricebookEntry.Product2Id + '' => serviceProductIds }
		);
		List<PricebookEntry> priceEntries = (List<PricebookEntry>) SOQLUtility.querySObject(
			queryRequest
		);
		Map<Id, PricebookEntry> unitPriceByProductId = new Map<Id, PricebookEntry>();
		for (PricebookEntry priceEntry : priceEntries) {
			unitPriceByProductId.put(priceEntry.Product2Id, priceEntry);
		}
		// retrieve estimates for related services
		List<Estimate__c> estimates = ServiceRecommendationsSupport.getEstimatesForServiceProducts(
			serviceProductIds
		);
		Map<Id, List<Estimate__c>> estimatesByServiceId = new Map<Id, List<Estimate__c>>();
		for (Estimate__c estimate : estimates) {
			List<Estimate__c> currentEstimates = estimatesByServiceId.get(estimate.ServiceId__c);
			if (currentEstimates == null) {
				currentEstimates = new List<Estimate__c>();
			}
			currentEstimates.add(estimate);
			estimatesByServiceId.put(estimate.ServiceId__c, currentEstimates);
		}

		for (Product2 serviceProduct : serviceProducts) {
			if (!opportunityProductIds.contains(serviceProduct.Id)) {
				// exclude services that are already added to the opportunity
				ServiceRecommendation serviceRecommendation = new ServiceRecommendation();
				serviceRecommendation.service = serviceProduct;
				serviceRecommendation.product = serviceProduct.AssociatedProductId__r;
				serviceRecommendation.hasEstimate = estimatesByServiceId.get(serviceProduct.Id) != null;
				serviceRecommendation.currencyCode = UserInfo.getDefaultCurrency();
				serviceRecommendationsByServiceId.put(serviceProduct.Id, serviceRecommendation);
			}
		}

		return serviceRecommendationsByServiceId;
	}

	@AuraEnabled
	public static ServiceOpportunity addServiceToOpportunity(
		Id opportunityId,
		Id serviceId,
		Id productId
	) {
		ServiceOpportunity serviceOpportunityResponse = new ServiceOpportunity();
		Boolean success = false;
		String errorMsg = '';
		String stackTrace = '';
		Estimate__c serviceEstimate = null;
		Product2 serviceProduct = getServiceProduct(serviceId);

		// look for quote templates if any exist, otherwise look for estimates
		List<Quote__c> quotes = new List<Quote__c>();
		Id quoteTemplateId = getQuoteId(QuoteService.RECORDTYPE_NAME_TEMPLATE, serviceId);
		Savepoint sp = Database.setSavepoint();

		// there will either be an existing quote template, or an estimate to create a quote from
		if (quoteTemplateId == null) {
			List<Estimate__c> estimates = ServiceRecommendationsSupport.getEstimatesForServiceProducts(
				new Set<Id>{ serviceId }
			);

			if (!estimates.isEmpty()) {
				serviceEstimate = estimates[0];
				// check if we have any quotes already configured
				quotes.addAll(getQuotesForEstimate(serviceEstimate, serviceProduct));
			} else {
				errorMsg = System.Label.NoEstimateForServiceProduct + serviceId;
			}
		} else {
			Quote__c newQuote = QuoteService.cloneQuote(quoteTemplateId);
			newQuote.Name = newQuote.Name.replace('TEMPLATE FROM: ', '');
			newQuote.TemplateId__c = quoteTemplateId;
			newQuote.QuoteDate__c = System.today();
			newQuote.Version__c = 1;
			newQuote.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
			CRUDUtility.updateRecords(newQuote);
			quotes.add(newQuote);
		}

		if (!quotes.isEmpty()) {
			Quote__c serviceQuote = quotes[0];
			try {
				Opportunity opp = getOpportunity(opportunityId);
				serviceQuote.ProposalId__c = opp.ProposalId__c;
				serviceQuote.OpportunityId__c = opportunityId;
				serviceQuote.AccountId__c = opp.AccountId;
				CRUDUtility.updateRecords(serviceQuote);

				// create opportunity line item for service line
				PricebookEntry pricebookEntry = getPricebookEntry(serviceId, opp);
				NamedRange.NamedRangeDO quoteTotalNamedRange = NamedRangeService.getQuoteTotalForQuote(
					serviceQuote.Id
				);
				ServiceRecommendationsSupport.OpportunityLineItemRequest opportunityLineItemRequest = new ServiceRecommendationsSupport.OpportunityLineItemRequest();
				opportunityLineItemRequest.opportunityLineItems.add(new OpportunityLineItem());
				opportunityLineItemRequest.opportunityId = opportunityId;
				opportunityLineItemRequest.productId = serviceProduct.Id;
				opportunityLineItemRequest.pricebookEntryId = pricebookEntry.Id;
				opportunityLineItemRequest.quoteTotalNamedRange = quoteTotalNamedRange;
				List<OpportunityLineItem> serviceLineItems = ServiceRecommendationsSupport.upsertOpportunityLineItem(
					opportunityLineItemRequest
				);
				OpportunityLineItem serviceLineItem = serviceLineItems[0];

				// store into junction object
				OpportunityLineItem productLineItem = getProductLineItem(productId);
				ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest opportunityProductServiceQuoteRequest = new ServiceRecommendationsSupport.OpportunityProductServiceQuoteRequest();
				Product2 associatedProduct = [
					SELECT Name
					FROM Product2
					WHERE Id = :productId
					WITH SECURITY_ENFORCED
					LIMIT 1
				];
				opportunityProductServiceQuoteRequest.Name = associatedProduct.Name;
				opportunityProductServiceQuoteRequest.serviceLineItem = serviceLineItem;
				opportunityProductServiceQuoteRequest.productLineItem = productLineItem;
				opportunityProductServiceQuoteRequest.serviceQuote = new Quote__c(
					Id = serviceQuote.Id,
					OpportunityId__c = opportunityId
				);
				opportunityProductServiceQuoteRequest.serviceEstimate = serviceEstimate;
				OpportunityProductServiceQuote__c opportunityProductServiceQuote = ServiceRecommendationsSupport.insertOpportunityProductServiceQuote(
					opportunityProductServiceQuoteRequest
				);
				serviceOpportunityResponse.opportunityProductServiceQuote = opportunityProductServiceQuote;
				success = opportunityProductServiceQuote.Id != null;
			} catch (Exception e) {
				success = false;
				errorMsg = e.getMessage();
				stackTrace = e.getStackTraceString();
				// undo any record creation we did up to this point if we have some exception
				// so that we don't have lingering bad data in the org
				Database.rollback(sp);
			}
		} else {
			errorMsg = System.Label.NoQuotesGeneratedForServiceRecommendations;
			Database.rollback(sp);
			// undo any record creation we did up to this point if we have some exception
			// so that we don't have lingering bad data in the org
		}

		serviceOpportunityResponse.errorMsg = errorMsg; // internal error. no translation needed
		serviceOpportunityResponse.stackTrace = stackTrace;
		serviceOpportunityResponse.success = success;
		return serviceOpportunityResponse;
	}

	private static Id getQuoteId(String quoteType, Id serviceProductId) {
		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Quote__c.getName());
		queryRequest.requestedFields = new Set<String>{
			SObjectUtility.FIELD_ID,
			Schema.Quote__c.Type__c + '',
			Schema.Quote__c.ServiceId__c + '',
			Schema.Quote__c.CreatedDate + ''
		};
		queryRequest.setFilterBy(
			new Map<String, String>{
				Schema.Quote__c.Type__c + '' => quoteType,
				Schema.Quote__c.ServiceId__c + '' => serviceProductId
			}
		);
		queryRequest.fieldBySortOrder = new Map<String, String>{
			Schema.Quote__c.CreatedDate + '' => SOQLConstants.SORT_DESC
		};
		queryRequest.querySize = 1;

		Id quoteTemplateId = null;
		List<Quote__c> quotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);
		if (!quotes.isEmpty()) {
			quoteTemplateId = quotes[0].Id;
		}
		return quoteTemplateId;
	}

	private static Opportunity getOpportunity(Id opportunityId) {
		QueryRequest opportunityQueryRequest = new QueryRequest(
			Schema.SObjectType.Opportunity.getName()
		);
		opportunityQueryRequest.requestedFields = new Set<String>{
			Schema.Opportunity.Amount + '',
			Schema.Opportunity.Pricebook2Id + '',
			Schema.Opportunity.ProposalId__c + '',
			Schema.Opportunity.AccountId + ''
		};
		opportunityQueryRequest.setFilterBy(
			new Map<String, String>{ SObjectUtility.FIELD_ID => opportunityId }
		);
		List<Opportunity> opps = (List<Opportunity>) SOQLUtility.querySObject(opportunityQueryRequest);
		Opportunity opp = opps[0];
		return opp;
	}

	private static Product2 getServiceProduct(Id serviceId) {
		QueryRequest productQueryRequest = new QueryRequest(Schema.SObjectType.Product2.getName());
		productQueryRequest.requestedFields = new Set<String>{
			SObjectUtility.FIELD_ID,
			Schema.Product2.ProductCode + '',
			Schema.Product2.Practice__c + '',
			Schema.Product2.Group__c + ''
		};
		productQueryRequest.setFilterBy(
			new Map<String, String>{ SObjectUtility.FIELD_ID => serviceId }
		);
		List<Product2> products = (List<Product2>) SOQLUtility.querySObject(productQueryRequest);
		Product2 serviceProduct = products[0];
		return serviceProduct;
	}

	private static PricebookEntry getPricebookEntry(Id serviceId, Opportunity opp) {
		QueryRequest pricebookEntryQueryRequest = new QueryRequest(
			Schema.SObjectType.PricebookEntry.getName()
		);
		pricebookEntryQueryRequest.requestedFields = new Set<String>{
			SObjectUtility.FIELD_ID,
			Schema.PricebookEntry.UnitPrice + ''
		};
		pricebookEntryQueryRequest.setFilterBy(
			new Map<String, String>{
				Schema.PricebookEntry.Product2Id + '' => serviceId,
				Schema.Opportunity.Pricebook2Id + '' => opp.Pricebook2Id
			}
		);
		List<PricebookEntry> pricebookEntries = (List<PricebookEntry>) SOQLUtility.querySObject(
			pricebookEntryQueryRequest
		);
		PricebookEntry pricebookEntry = pricebookEntries[0];
		return pricebookEntry;
	}

	private static OpportunityLineItem getProductLineItem(Id productId) {
		QueryRequest oppLineItemQueryRequest = new QueryRequest(
			Schema.SObjectType.OpportunityLineItem.getName()
		);
		oppLineItemQueryRequest.setFilterBy(
			new Map<String, String>{ Schema.OpportunityLineItem.Product2Id + '' => productId }
		);
		List<OpportunityLineItem> opportunityLineItems = (List<OpportunityLineItem>) SOQLUtility.querySObject(
			oppLineItemQueryRequest
		);
		OpportunityLineItem productLineItem = opportunityLineItems[0];
		return productLineItem;
	}

	private static List<Quote__c> getQuotesForEstimate(
		Estimate__c serviceEstimate,
		Product2 serviceProduct
	) {
		List<Quote__c> quotes = new List<Quote__c>();
		Quote__c quote = createQuote(serviceEstimate, serviceProduct);
		quotes.add(quote);

		return quotes;
	}

	private static Quote__c createQuote(Estimate__c serviceEstimate, Product2 serviceProduct) {
		Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> resourceRoleDetails = CreateQuoteFromEstimateService.getResourceRoles(
			serviceEstimate.Id,
			serviceEstimate.RateCardId__c
		);

		// default role preferences
		Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences> rolePrefs = new Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>();
		for (String resourceDetail : resourceRoleDetails.keySet()) {
			CreateQuoteFromEstimateService.ResourceRoleDetail roleDetail = resourceRoleDetails.get(
				resourceDetail
			);
			CreateQuoteFromEstimateService.ResourceRolePreferences rolePref = new CreateQuoteFromEstimateService.ResourceRolePreferences();
			rolePref.role = roleDetail.resourceRoleName;
			List<String> skillLevels = new List<String>(roleDetail.skillMap.keySet());
			rolePref.skillLevel = skillLevels.isEmpty() ? null : skillLevels.get(0);
			List<String> locations = rolePref.skillLevel == null
				? new List<String>()
				: roleDetail.skillMap.get(rolePref.skillLevel);
			rolePref.location = locations.isEmpty() == null ? null : locations[0];
			rolePrefs.put(resourceDetail, rolePref);
		}

		// general quote from estimate
		QuoteDO quoteDate = CreateQuoteFromEstimateService.getEstimateQuoteDetails(serviceEstimate);
		Quote__c quote = QuoteDO.getQuoteFromData(quoteDate);
		quote.Name = 'Quote for ' + serviceEstimate.Name;
		quote.ServiceStartDate__c = System.today();
		quote.ServiceEndDate__c = System.today().addYears(1);
		quote.TimePeriod__c = QuoteService.TIMEPERIOD_MONTHS;
		quote.TimePeriodsGroupMethod__c = QuoteService.TIMEPERIODSGROUPMETHOD_YEAR;
		quote.TimePeriodsAlignment__c = QuoteService.TIMEPERIODSALIGNMENT_CALENDAR;
		quote.Practice__c = serviceProduct.Practice__c;
		quote.Group__c = serviceProduct.Group__c;
		quote.QuoteDate__c = System.today();
		quote.Version__c = 1;
		quote.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
		CRUDUtility.insertRecords(quote);

		CreateQuoteFromEstimateService.convertEntitiesFromEstimate(quote, rolePrefs);
		return quote;
	}
}
