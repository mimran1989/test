/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class DefaultProposalCallback implements CustomClass.ProposalCallback {
	public class Errors implements CustomClass.Errors {
		private List<String> errorMessages;

		public Errors() {
			this.errorMessages = new List<String>();
		}

		public void addError(String error) {
			this.errorMessages.add(error);
		}

		public List<String> getErrorMessages() {
			return this.errorMessages;
		}
	}

	global CustomClass.ActionCallbackResponse onCreate(CustomClass.ActionCallbackRequest request) {
		CustomClass.ActionCallbackResponse response = new CustomClass.ActionCallbackResponse();
		return response;
	}

	global CustomClass.ActionCallbackResponse onUpdate(CustomClass.ActionCallbackRequest request) {
		CustomClass.ActionCallbackResponse response = new CustomClass.ActionCallbackResponse();
		return response;
	}

	global CustomClass.ActionCallbackResponse onDelete(CustomClass.ActionCallbackRequest request) {
		CustomClass.ActionCallbackResponse response = new CustomClass.ActionCallbackResponse();
		return response;
	}

	global CustomClass.ActionCallbackResponse createQuotes(
		CustomClass.ActionCallbackRequest request
	) {
		CustomClass.ActionCallbackResponse response = new CustomClass.ActionCallbackResponse();
		Errors error = new Errors();
		try {
			Proposal__c proposalSO = (Proposal__c) request.contextObject;
			// if proposal was created successfully, then would consider this a success for now
			response.isSuccess = proposalSO.Id != null;
			Opportunity opportunitySO = [
				SELECT Id
				FROM Opportunity
				WHERE ProposalId__c = :proposalSO.Id
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			Set<Id> serviceProducts = getServiceProductsIds(opportunitySO.Id);
			if (!serviceProducts.isEmpty()) {
				createEstimateFromEstimateTemplates(serviceProducts);
				createQuotesFromEstimates(serviceProducts);
			}
		} catch (Exception e) {
			// a callback should do their own error handling as needed
			error.addError(e.getMessage());
			response.isSuccess = false;
		}
		response.error = error;
		return response;
	}

	private Set<Id> getServiceProductsIds(Id opportunityId) {
		List<OpportunityLineItem> serviceOpportunityProducts = [
			SELECT Product2Id
			FROM OpportunityLineItem
			WHERE
				Product2Id IN (SELECT Id FROM Product2 WHERE Product2.RecordType.Name = 'Service')
				AND OpportunityId = :opportunityId
			WITH SECURITY_ENFORCED
		];
		Set<Id> serviceProducts = new Set<Id>();
		for (OpportunityLineItem serviceOpportunityProduct : serviceOpportunityProducts) {
			serviceProducts.add(serviceOpportunityProduct.Product2Id);
		}
		return serviceProducts;
	}

	private static List<EstimateTemplate__c> getEstimateTemplatesForServiceProducts(
		Set<Id> serviceProducts
	) {
		Map<String, String> orderBy = new Map<String, String>{
			Schema.EstimateTemplate__c.CreatedDate + '' => SOQLConstants.SORT_DESC
		};
		QueryRequest queryRequest = new QueryRequest(Schema.EstimateTemplate__c.SObjectType);
		queryRequest.requestedFields = new Set<String>{
			SObjectUtility.FIELD_NAME,
			Schema.EstimateTemplate__c.ServiceId__c + '',
			Schema.EstimateTemplate__c.RateCardId__c + ''
		};
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ Schema.EstimateTemplate__c.ServiceId__c + '' => serviceProducts }
		);
		queryRequest.fieldBySortOrder = orderBy;
		return (List<EstimateTemplate__c>) SOQLUtility.querySObject(queryRequest);
	}

	private void createEstimateFromEstimateTemplates(Set<Id> serviceProducts) {
		List<EstimateTemplate__c> estimateTemplates = getEstimateTemplatesForServiceProducts(
			serviceProducts
		);
		for (EstimateTemplate__c estimateTemplateSO : estimateTemplates) {
			CreateEstimateService.createEstimate(estimateTemplateSO.Id);
		}
	}

	private void createQuotesFromEstimates(Set<Id> serviceProducts) {
		List<Estimate__c> estimates = ServiceRecommendationsSupport.getEstimatesForServiceProducts(
			serviceProducts
		);
		List<Quote__c> quotesToInsert = new List<Quote__c>();
		Map<Id, Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>> rolePreferencesByEstimateId = new Map<Id, Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>>();
		for (Estimate__c estimateSO : estimates) {
			Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences> rolePrefs = new Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>();
			Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> resourceRoleDetails = CreateQuoteFromEstimateService.getResourceRoles(
				estimateSO.Id,
				estimateSO.RateCardId__c
			);

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

			QuoteDO quoteData = CreateQuoteFromEstimateService.getEstimateQuoteDetails(estimateSO);
			Quote__c quote = QuoteDO.getQuoteFromData(quoteData);
			quote.QuoteDate__c = System.today();
			quote.Version__c = 1;
			quote.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
			quotesToInsert.add(quote);

			rolePreferencesByEstimateId.put(quote.EstimateId__c, rolePrefs);
		}

		CRUDUtility.insertRecords(quotesToInsert);

		for (Quote__c quoteSO : quotesToInsert) {
			Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences> rolePrefs = rolePreferencesByEstimateId.get(
				quoteSO.EstimateId__c
			);
			CreateQuoteFromEstimateService.convertEntitiesFromEstimate(quoteSO, rolePrefs);
		}
	}
}
