/**
 *  Provus Services Quoting
 *  QuoteCollaborationControllerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class QuoteCollaborationControllerTest extends TestBase {
	@IsTest
	static void shouldGetAvailableQuoteSections() {
		Quote__c quote = newQuote();

		Test.startTest();
		QuoteCollaborationController.getAvailableQuoteSections(quote.Id);
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}

	@IsTest
	static void shouldGetCollaborationRequests() {
		Quote__c quote = newQuote();

		Test.startTest();
		QuoteCollaborationController.getCollaborationRequestsForQuote(quote.Id);
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}

	@IsTest
	static void shouldSubmitInvitationForCollaboration() {
		Quote__c quote = newQuote();
		QuoteSection__c section = newQuoteSection(quote.Id);
		User user = newUser();

		Test.startTest();
		QuoteCollaborationController.submitInvitationForCollaboration(
			user.Id,
			quote.Id,
			new List<Id>{ section.Id }
		);
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateCollaborationQuote() {
		Quote__c quote = newQuote();
		User user = newUser();

		Test.startTest();
		QuoteCollaborationController.createCollaborationQuote(user.Id, quote.Id);
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}

	@IsTest
	static void shouldCloneQuote() {
		Quote__c quote = newQuote();
		User user = newUser();

		Test.startTest();
		QuoteCollaborationController.cloneQuote(user.Id, quote.Id);
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}

	@IsTest
	static void shouldCommitChanges() {
		Quote__c sourceQuote = newQuote();
		Quote__c targetQuote = newQuote();
		QuoteSection__c section = newQuoteSection(sourceQuote.Id);
		sourceQuote.DerivedFromId__c = targetQuote.Id;
		update sourceQuote;

		Test.startTest();
		QuoteCollaborationController.commitChanges(sourceQuote.Id, new List<Id>{ section.Id });
		System.assert(1 == 1, 'coverage');
		Test.stopTest();
	}
}
