/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateProposalController {
	public class ProposalResponse {
		@AuraEnabled
		public Boolean success;
		@AuraEnabled
		public List<String> errorMsgs;
		@AuraEnabled
		public Proposal__c proposalSO;

		public ProposalResponse() {
			this.errorMsgs = new List<String>();
		}
	}

	@AuraEnabled
	public static ProposalResponse createProposal(String opportunityId) {
		ProposalResponse response = new ProposalResponse();
		try {
			Opportunity opportunitySO = [
				SELECT Id, Name, ProposalId__c
				FROM Opportunity
				WHERE ID = :opportunityId
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
			Proposal__c proposalSO = CreateProposalService.generateProposal(opportunitySO);
			CreateProposalService.associateProposalIdToOpportunity(opportunitySO, proposalSO.Id);
			CreateProposalService.associateProposalIdToOpportunityServiceQuotes(
				opportunitySO,
				proposalSO.Id
			);
			CustomClass.ActionCallbackResponse callbackResponse = CreateProposalService.createQuotesForProposal(
				proposalSO
			);
			if (
				callbackResponse.error != null &&
				!SystemUtility.nullOrEmpty(callbackResponse.error.getErrorMessages())
			) {
				List<String> errorMsgs = callbackResponse.error.getErrorMessages();
				response.errorMsgs.addAll(errorMsgs);
			} else {
				response.proposalSO = proposalSO;
			}
			response.success =
				proposalSO.Id != null &&
				callbackResponse.isSuccess != null &&
				callbackResponse.isSuccess;
		} catch (Exception e) {
			response.success = false;
			response.errorMsgs.add(e.getMessage());
		}
		return response;
	}
}
