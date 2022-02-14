/**
 *  Provus Services Quoting
 *  QuoteCollaborationSupportTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private class QuoteCollaborationSupportTest extends TestBase {
	@IsTest
	static void itShouldSendAnEmailToCollaborator() {
		Test.startTest();
		Id userId = UserInfo.getUserId();
		Quote__c quote = newQuote();
		QuoteCollaborationSupport.sendEmailToCollaborator(userId, quote.Id);
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();
		system.assertEquals(1, invocations, 'An email should be sent');
	}

	@IsTest
	static void itShouldSendAnEmailToQuoteOwner() {
		Quote__c mainQuote = newQuote();
		Quote__c quoteSO = newQuote();
		quoteSO.DerivedFromId__c = mainQuote.Id;
		CRUDUtility.updateRecords(quoteSO);

		Test.startTest();
		QuoteCollaborationSupport.sendEmailToQuoteOwner(quoteSO.Id);
		Integer invocations = Limits.getEmailInvocations();
		Test.stopTest();
		System.assertEquals(1, invocations, 'should equal 1');
	}

	@IsTest
	static void itShouldGetQuoteSections() {
		Quote__c quote = newQuote();
		QuoteSection__c section = newQuoteSection(quote.Id);
		CollaborationRequest__c request = newCollaborationRequest();
		request.QuoteId__c = quote.Id;
		request.SectionId__c = section.Id;
		request.Status__c = CollaborationRequest.STATUS_MERGED;

		update request;

		Test.startTest();
		List<QuoteSection__c> quoteSections = QuoteCollaborationSupport.getAvailableQuoteSections(
			quote.Id
		);
		System.assertEquals(1, quoteSections.size(), 'should equal 1');
		Test.stopTest();
	}

	@IsTest
	static void itShouldNotGetAssignedSections() {
		Quote__c quote = newQuote();
		QuoteSection__c section = newQuoteSection(quote.Id);
		CollaborationRequest__c request = newCollaborationRequest();
		request.QuoteId__c = quote.Id;
		request.SectionId__c = section.Id;
		request.Status__c = CollaborationRequest.STATUS_ASSIGNED;

		update request;

		Test.startTest();
		List<QuoteSection__c> quoteSections = QuoteCollaborationSupport.getAvailableQuoteSections(
			quote.Id
		);
		System.assertEquals(0, quoteSections.size(), 'should not return any quote sections');
		Test.stopTest();
	}

	@IsTest
	static void itShouldNotGetAcceptedSections() {
		Quote__c quote = newQuote();
		QuoteSection__c section = newQuoteSection(quote.Id);
		CollaborationRequest__c request = newCollaborationRequest();
		request.QuoteId__c = quote.Id;
		request.SectionId__c = section.Id;
		request.Status__c = CollaborationRequest.STATUS_ACCEPTED;

		update request;

		Test.startTest();
		List<QuoteSection__c> quoteSections = QuoteCollaborationSupport.getAvailableQuoteSections(
			quote.Id
		);
		System.assertEquals(0, quoteSections.size(), 'should not return any quote sections');
		Test.stopTest();
	}

	@IsTest
	static void itShouldRevokeSections() {
		Quote__c quote = newQuote();
		QuoteSection__c section = newQuoteSection(quote.Id);
		CollaborationRequest__c request = newCollaborationRequest();
		request.QuoteId__c = quote.Id;
		request.SectionId__c = section.Id;
		request.Status__c = CollaborationRequest.STATUS_ACCEPTED;

		update request;

		Test.startTest();
		QuoteCollaborationSupport.revokeSections(quote.Id, new List<Id>{ section.Id });
		CollaborationRequest__c result = [
			SELECT Status__c
			FROM CollaborationRequest__c
			WHERE SectionId__c = :section.Id
		];
		System.assertEquals(
			CollaborationRequest.STATUS_REVOKED,
			result.Status__c,
			'should update the status to Revoked'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetExistingCollaborationQuote() {
		Quote__c quote = newQuote();
		Quote__c sourceQuote = newQuote();
		CollaborationRequest__c request = newCollaborationRequest();
		request.QuoteId__c = quote.Id;
		request.Status__c = CollaborationRequest.STATUS_ACCEPTED;
		quote.DerivedFromId__c = sourceQuote.Id;
		update request;
		update quote;

		Test.startTest();
		Quote__c existingQuote = QuoteCollaborationSupport.getExistingCollaborationQuoteFor(
			UserInfo.getUserId(),
			sourceQuote.Id
		);
		System.assertNotEquals(null, existingQuote, 'should have found an existing quote');
		Test.stopTest();
	}
}
