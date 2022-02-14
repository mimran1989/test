/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private with sharing class CreateProposalServiceTest extends TestBase {
	@testSetup
	static void setup() {
		// create an opportunity with a proposal associated
		Proposal__c proposalSO = newProposal();
		Opportunity opportunitySO = newOpportunity();
		opportunitySO.Name = 'Test with proposal';
		opportunitySO.ProposalId__c = proposalSO.Id;
		update opportunitySO;

		// create an opportunity without a proposal associated
		newOpportunity();
	}

	@isTest
	static void itShouldCreateProposal() {
		Test.startTest();
		Opportunity opportunitySO = [
			SELECT Id, Name, ProposalId__c
			FROM Opportunity
			WHERE Name = 'Test'
		];
		Proposal__c proposalSO = CreateProposalService.generateProposal(opportunitySO);
		System.assertEquals(
			'Proposal for Test',
			proposalSO.Name,
			'Created new proposal for opportunity'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldGetExistingProposal() {
		Test.startTest();
		Opportunity opportunitySO = [
			SELECT Id, Name, ProposalId__c
			FROM Opportunity
			WHERE Name = 'Test with proposal'
		];
		Proposal__c proposalSO = CreateProposalService.generateProposal(opportunitySO);
		System.assertEquals(
			'Test Proposal',
			proposalSO.Name,
			'Retrieved existing proposal for opportunity'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldUpdateProposalId() {
		Test.startTest();
		Opportunity opportunitySO = [
			SELECT Id, Name, ProposalId__c
			FROM Opportunity
			WHERE Name = 'Test'
		];
		Proposal__c proposalSO = CreateProposalService.generateProposal(opportunitySO);
		opportunitySO = CreateProposalService.associateProposalIdToOpportunity(
			opportunitySO,
			proposalSO.Id
		);
		System.assertEquals(
			proposalSO.Id,
			opportunitySO.ProposalId__c,
			'Opportunity should have proposal id set'
		);
		Test.stopTest();
	}

	@isTest
	static void itShouldReturnResponseForCreateQuotes() {
		Test.startTest();
		Opportunity opportunitySO = [
			SELECT Id, Name, ProposalId__c
			FROM Opportunity
			WHERE Name = 'Test with proposal'
		];
		Proposal__c proposalSO = CreateProposalService.generateProposal(opportunitySO);
		CustomClass.ActionCallbackResponse response = CreateProposalService.createQuotesForProposal(
			proposalSO
		);
		System.assert(response.isSuccess, 'Response should have returned successfully');
		Test.stopTest();
	}
}
