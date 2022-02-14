public with sharing class RelatedQuoteScenariosController {
	@AuraEnabled
	public static List<Quote__c> getScenarios(string quoteId) {
		List<Quote__c> quoteRecords = new List<Quote__c>();

		Quote__c recordDetails = [
			SELECT
				Id,
				Name,
				Type__c,
				AccountId__r.Name,
				AccountId__c,
				IsPrimary__c,
				MarginPercent__c,
				TotalAmount__c,
				DerivedFromId__c,
				TotalCost__c,
				CreatedDate
			FROM Quote__c
			WHERE Id = :quoteId
			WITH SECURITY_ENFORCED
		];

		Id queryValue;

		if (
			recordDetails.Type__c == QuoteService.RECORDTYPE_NAME_QUOTE ||
			recordDetails.Type__c == QuoteService.RECORDTYPE_NAME_COLLABORATION
		) {
			queryValue = quoteId;
		} else if (recordDetails.Type__c == QuoteService.RECORDTYPE_NAME_SCENARIO) {
			queryValue = recordDetails.DerivedFromId__c;
			Quote__c originalQuote = [
				SELECT
					Id,
					Name,
					Type__c,
					AccountId__r.Name,
					AccountId__c,
					IsPrimary__c,
					MarginPercent__c,
					TotalAmount__c,
					DerivedFromId__c,
					TotalCost__c,
					CreatedDate
				FROM Quote__c
				WHERE Id = :recordDetails.DerivedFromId__c
				WITH SECURITY_ENFORCED
			];
			quoteRecords.add(originalQuote);
		} else {
			throw new ApplicationException(
				'Quote Type: ' +
				recordDetails.Type__c +
				', does not support scenarios.'
			);
		}
		quoteRecords.AddAll(
			[
				SELECT
					Id,
					Name,
					Type__c,
					AccountId__r.Name,
					AccountId__c,
					IsPrimary__c,
					MarginPercent__c,
					TotalAmount__c,
					DerivedFromId__c,
					TotalCost__c,
					CreatedDate
				FROM Quote__c
				WHERE
					DerivedFromId__c = :queryValue
					AND Id != :quoteId
					AND Status__c = :QuoteService.STATUS_ACTIVE
				WITH SECURITY_ENFORCED
				ORDER BY CreatedDate DESC
			]
		);

		return quoteRecords;
	}
}
