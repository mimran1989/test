/**
 *  Provus Services Quoting
 *  ProjectPhaseFactory
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class ProjectPhaseFactory {
	public static List<ProjectPhase__c> getProjectPhasesForQuote(Id quoteId) {
		return [
			SELECT
				Id,
				Description__c,
				EndDate__c,
				Name,
				QuoteId__c,
				Sequence__c,
				StartDate__c,
				(SELECT Id, Sequence__c, QuoteId__c FROM QuotePeriods__r ORDER BY Sequence__c ASC)
			FROM ProjectPhase__c
			WHERE QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}
}
