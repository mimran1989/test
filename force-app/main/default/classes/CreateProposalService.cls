/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateProposalService {
	public static Proposal__c generateProposal(Opportunity opportunitySO) {
		Proposal__c proposalSO = null;
		Id proposalId = opportunitySO.ProposalId__c;
		if (proposalId == null) {
			proposalSO = new Proposal__c(
				Name = 'Proposal for ' + opportunitySO.Name,
				ExpectedStartDate__c = Date.today()
			);
			CRUDUtility.insertRecords(proposalSO);
		} else {
			proposalSO = [
				SELECT Id, Name
				FROM Proposal__c
				WHERE ID = :proposalId
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
		}
		return proposalSO;
	}

	public static Opportunity associateProposalIdToOpportunity(
		Opportunity opportunitySO,
		ID proposalId
	) {
		if (opportunitySO.ProposalId__c == null) {
			opportunitySO.ProposalId__c = proposalId;
			CRUDUtility.updateRecords(opportunitySO);
		}
		return opportunitySO;
	}

	public static List<Quote__c> associateProposalIdToOpportunityServiceQuotes(
		Opportunity opportunitySO,
		ID proposalId
	) {
		List<Quote__c> serviceQuotes = [
			SELECT Id, ProposalId__c
			FROM Quote__c
			WHERE
				Id IN (
					SELECT ServiceQuoteId__c
					FROM OpportunityProductServiceQuote__c
					WHERE OpportunityId__c = :opportunitySO.Id
				)
			WITH SECURITY_ENFORCED
		];
		for (Quote__c serviceQuote : serviceQuotes) {
			if (serviceQuote.ProposalId__c == null) {
				serviceQuote.ProposalId__c = proposalId;
			}
		}
		CRUDUtility.updateRecords(serviceQuotes);
		return serviceQuotes;
	}

	public static CustomClass.ActionCallbackResponse createQuotesForProposal(Proposal__c proposalSO) {
		CustomClass.ActionCallbackResponse response = new CustomClass.ActionCallbackResponse();
		DefaultProposalCallback.Errors error = new DefaultProposalCallback.Errors();
		response.error = error;
		response.isSuccess = proposalSO != null;
		return response;
	}
}
