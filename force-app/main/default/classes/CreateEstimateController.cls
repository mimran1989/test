public with sharing class CreateEstimateController {
	@AuraEnabled
	public static Id createEstimateFromTemplate(String estimateTemplateId) {
		Estimate__c estimateSO = CreateEstimateService.createEstimate(estimateTemplateId);
		return estimateSO.Id;
	}
}
