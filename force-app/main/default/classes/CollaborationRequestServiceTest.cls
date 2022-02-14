/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */

@IsTest
private class CollaborationRequestServiceTest extends TestBase {
	@IsTest
	static void itShouldReturnOutstandingRequests() {
		Quote__c quoteSO = newQuote();
		CollaborationRequest__c requestSO1 = newCollaborationRequest();
		requestSO1.Status__c = CollaborationRequest.STATUS_READY_TO_MERGE;
		requestSO1.QuoteId__c = quoteSO.Id;
		CollaborationRequest__c requestSO2 = newCollaborationRequest();
		requestSO2.Status__c = CollaborationRequest.STATUS_MERGED;
		requestSO2.QuoteId__c = quoteSO.Id;
		CRUDUtility.updateRecords(new List<CollaborationRequest__c>{ requestSO1, requestSO2 });

		Test.startTest();
		List<CollaborationRequest__c> requests = CollaborationRequestService.getOutstandingRequestsFor(
			quoteSO.Id
		);
		System.assertEquals(1, requests.size(), 'should be have 1 outstanding request');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnRevocableRequests() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c section = newQuoteSection(quoteSO.Id);
		CollaborationRequest__c request1 = newCollaborationRequest();
		request1.Status__c = CollaborationRequest.STATUS_ASSIGNED;
		request1.QuoteId__c = quoteSO.Id;
		request1.SectionId__c = section.Id;
		CollaborationRequest__c request2 = newCollaborationRequest();
		request2.Status__c = CollaborationRequest.STATUS_ACCEPTED;
		request2.QuoteId__c = quoteSO.Id;
		request2.SectionId__c = section.Id;
		CRUDUtility.updateRecords(new List<CollaborationRequest__c>{ request1, request2 });

		Test.startTest();
		List<CollaborationRequest__c> requests = CollaborationRequestService.getRevocableRequestsFor(
			quoteSO.Id,
			new List<Id>{ section.Id }
		);
		System.assertEquals(2, requests.size(), 'should have 2 revocable requests');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnAssignedRequests() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c section = newQuoteSection(quoteSO.Id);
		CollaborationRequest__c request1 = newCollaborationRequest();
		request1.Status__c = CollaborationRequest.STATUS_ASSIGNED;
		request1.QuoteId__c = quoteSO.Id;
		request1.SectionId__c = section.Id;
		CollaborationRequest__c request2 = newCollaborationRequest();
		request2.Status__c = CollaborationRequest.STATUS_ACCEPTED;
		request2.QuoteId__c = quoteSO.Id;
		request2.SectionId__c = section.Id;
		CRUDUtility.updateRecords(new List<CollaborationRequest__c>{ request1, request2 });

		Test.startTest();
		List<CollaborationRequest__c> requests = CollaborationRequestService.getAssignedRequestsFor(
			quoteSO.Id
		);
		System.assertEquals(1, requests.size(), 'should have 1 assigned request');
		Test.stopTest();
	}

	@IsTest
	static void itShouldMarkRequestAsReadyToMerge() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO = newQuoteSection(quoteSO.Id);
		Id userId = UserInfo.getUserId();
		CollaborationRequest__c requestSO = newCollaborationRequest();
		requestSO.CollaboratorUserId__c = userId;
		requestSO.SectionId__c = sectionSO.Id;
		CRUDUtility.updateRecords(sectionSO);
		CRUDUtility.updateRecords(requestSO);

		Test.startTest();
		CollaborationRequestService.markForMerge(new List<Id>{ sectionSO.Id });
		CollaborationRequest__c updatedRequestSO = [
			SELECT Status__c
			FROM CollaborationRequest__c
			WHERE Id = :requestSO.Id
		];
		System.assertEquals(
			updatedRequestSO.Status__c,
			CollaborationRequest.STATUS_READY_TO_MERGE,
			'should be Ready to Merge'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldMarkRequestAsMerged() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO = newQuoteSection(quoteSO.Id);
		Id userId = UserInfo.getUserId();
		CollaborationRequest__c requestSO = newCollaborationRequest();
		requestSO.CollaboratorUserId__c = userId;
		requestSO.SectionId__c = sectionSO.Id;
		CRUDUtility.updateRecords(sectionSO);
		CRUDUtility.updateRecords(requestSO);

		Test.startTest();
		CollaborationRequestService.markAsMerged(new List<Id>{ sectionSO.Id });
		CollaborationRequest__c updatedRequestSO = [
			SELECT Status__c
			FROM CollaborationRequest__c
			WHERE Id = :requestSO.Id
		];
		System.assertEquals(
			updatedRequestSO.Status__c,
			CollaborationRequest.STATUS_MERGED,
			'should be Merged'
		);
		Test.stopTest();
	}
}
