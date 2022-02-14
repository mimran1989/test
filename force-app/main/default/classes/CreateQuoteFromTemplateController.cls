public with sharing class CreateQuoteFromTemplateController {
	@AuraEnabled
	public static Quote__c retrieveQuoteTemplateDetails(Id selectedTemplateId) {
		return [
			SELECT
				Id,
				Name,
				ServiceStartDate__c,
				ServiceEndDate__c,
				AccountId__c,
				OpportunityId__c,
				TimePeriod__c,
				TimePeriodsAlignment__c,
				TimePeriodsGroupMethod__c,
				RateCardId__c,
				Practice__c,
				Group__c,
				MarginPercent__c,
				PriceUOM__c,
				ProfitAmount__c,
				QuoteDate__c,
				ServiceId__c,
				TotalAmount__c,
				TotalCost__c
			FROM Quote__c
			WHERE Id = :selectedTemplateId
			WITH SECURITY_ENFORCED
		];
	}

	@AuraEnabled
	public static String computeNewEndDate(Id selectedTemplateId, String newStartDate) {
		Date newStart = Date.valueOf(newStartDate);

		Quote__c selectedTemplate = [
			SELECT ServiceStartDate__c, ServiceEndDate__c
			FROM Quote__c
			WHERE Id = :selectedTemplateId
			WITH SECURITY_ENFORCED
			LIMIT 1
		];

		Date newEndDate = newStart.addDays(
			selectedTemplate.ServiceStartDate__c.daysBetween(selectedTemplate.ServiceEndDate__c)
		);
		return JSON.serialize(newEndDate);
	}

	@AuraEnabled(cacheable=true)
	public static Opportunity getOpportunityDetails(String opportunityId) {
		Opportunity oppData;
		try {
			QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Opportunity.getName());
			queryRequest.requestedFields = new Set<String>{ Schema.Opportunity.AccountId + '' };
			queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => opportunityId });
			List<Opportunity> opportunities = SOQLUtility.querySObject(queryRequest);
			if (!opportunities.isEmpty()) {
				oppData = opportunities[0];
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
		return oppData;
	}
}
