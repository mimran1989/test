/**
 *  Provus Services Quoting
 *  CreateQuoteFromEstimateController
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateQuoteFromEstimateController {
	@AuraEnabled(cacheable=true)
	public static QuoteDO getEstimateDetails(String estimateId) {
		//Required Fields from estimate
		Set<String> requiredFields = new Set<String>();
		requiredFields.add(Schema.Estimate__c.AccountId__c + '');
		requiredFields.add(Schema.Estimate__c.OpportunityId__c + '');
		requiredFields.add(Schema.Estimate__c.Description__c + '');
		requiredFields.add(Schema.Estimate__c.RateCardId__c + '');
		requiredFields.add(Schema.Estimate__c.ServiceId__c + '');
		requiredFields.add(
			SystemUtility.getRName(Schema.Estimate__c.ServiceId__c) +
			'.' +
			Schema.Product2.Practice__c
		);
		requiredFields.add(
			SystemUtility.getRName(Schema.Estimate__c.ServiceId__c) +
			'.' +
			Schema.Product2.Group__c
		);

		QueryRequest queryRequest = new QueryRequest(Schema.Estimate__c.SObjectType);
		queryRequest.requestedFields = requiredFields;
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => estimateId });
		List<Estimate__c> estimates = SOQLUtility.querySObject(queryRequest);

		QuoteDO quoteData;
		if (!estimates.isEmpty()) {
			Estimate__c estimateSO = estimates[0];
			quoteData = CreateQuoteFromEstimateService.getEstimateQuoteDetails(estimateSO);
		}
		return quoteData;
	}

	@AuraEnabled
	public static Date getServiceEndDate(Id estimateId, EndDateArgs endDateArgs) {
		Decimal totalDuration = 0;

		AggregateResult[] groupedRolledUpDurations = [
			SELECT ActivityGroupId__c, MAX(RolledUpEstimatedDuration__c) rolledUp
			FROM TaskRoleSummary__c
			WHERE ActivityGroupId__r.EstimateId__c IN (:estimateId) AND RolledUpEstimatedDuration__c > 0
			WITH SECURITY_ENFORCED
			GROUP BY ActivityGroupId__c
		];

		for (AggregateResult ar : groupedRolledUpDurations) {
			totalDuration += (Decimal) ar.get('rolledUp');
		}

		return DurationCalcs.endDate(totalDuration, endDateArgs);
	}

	@AuraEnabled
	public static Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> getResourceRoleData(
		String estimateId,
		String rateCardId
	) {
		return CreateQuoteFromEstimateService.getResourceRoles(estimateId, rateCardId);
	}

	@AuraEnabled
	public static Id createQuote(String quoteDetails, String rolePreferences) {
		QuoteDO quoteDate = (QuoteDO) JSON.deserialize(quoteDetails, QuoteDO.class);
		Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences> rolePrefs = (Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>) JSON.deserialize(
			rolePreferences,
			Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>.class
		);

		Quote__c quoteSO = QuoteDO.getQuoteFromData(quoteDate);
		quoteSO.QuoteDate__c = System.today();
		quoteSO.Version__c = 1;
		quoteSO.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
		CRUDUtility.insertRecords(quoteSO);

		CreateQuoteFromEstimateService.convertEntitiesFromEstimate(quoteSO, rolePrefs);

		return quoteSO.Id;
	}
}
