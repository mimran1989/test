public class QuoteDO {
	@AuraEnabled
	public String quoteName;
	@AuraEnabled
	public Boolean isPrimary;
	@AuraEnabled
	public Id accountId;
	@AuraEnabled
	public String description;
	@AuraEnabled
	public Id opportunityId;
	@AuraEnabled
	public Date serviceStartDate;
	@AuraEnabled
	public Id rateCardId;
	@AuraEnabled
	public Date serviceEndDate;
	@AuraEnabled
	public String practice;
	@AuraEnabled
	public String timePeriod;
	@AuraEnabled
	public String timePeriodsGroupMethod;
	@AuraEnabled
	public String status;
	@AuraEnabled
	public String timePeriodsAlignment;
	@AuraEnabled
	public Id estimateId;
	@AuraEnabled
	public String groupValue;
	@AuraEnabled
	public Id serviceId;

	public static Quote__c getQuoteFromData(QuoteDO quoteData) {
		return new Quote__c(
			Name = quoteData.quoteName,
			IsPrimary__c = quoteData.isPrimary,
			AccountId__c = quoteData.accountId,
			Description__c = quoteData.description,
			OpportunityId__c = quoteData.opportunityId,
			ServiceStartDate__c = quoteData.serviceStartDate,
			RateCardId__c = quoteData.rateCardId,
			ServiceEndDate__c = quoteData.serviceEndDate,
			Practice__c = quoteData.practice,
			TimePeriod__c = quoteData.timePeriod,
			TimePeriodsGroupMethod__c = quoteData.timePeriodsGroupMethod,
			Status__c = quoteData.status,
			TimePeriodsAlignment__c = quoteData.timePeriodsAlignment,
			EstimateId__c = quoteData.estimateId,
			Group__c = quoteData.groupValue,
			ServiceId__c = quoteData.serviceId
		);
	}
}
