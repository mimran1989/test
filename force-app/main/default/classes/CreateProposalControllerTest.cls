/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private with sharing class CreateProposalControllerTest extends TestBase {
	@testSetup
	static void setup() {
		newOpportunity();
	}

	@isTest
	static void itShouldGetCreateProposal() {
		Test.startTest();
		Opportunity opportunitySO = [SELECT Id FROM Opportunity WHERE Name = 'Test' LIMIT 1];
		CreateProposalController.ProposalResponse response = CreateProposalController.createProposal(
			opportunitySO.Id
		);
		System.assert(response.success, 'proposal should be generated successfully');
		Test.stopTest();
	}
}
