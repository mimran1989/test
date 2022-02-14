/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private class EventPublisherTest extends TestBase {
	@TestSetup
	static void setup() {
		TestBase.newQuote();
	}

	@IsTest
	static void testPublish() {
		User userSO = newUser();
		Quote__c quote = [SELECT Id FROM Quote__c LIMIT 1];
		CollaborationRequest__c request = new CollaborationRequest__c(
			QuoteId__c = quote.Id,
			OwnerId = userSO.Id,
			Status__c = CollaborationRequest.STATUS_READY_TO_MERGE
		);

		Test.startTest();
		try {
			EventPublisher.publishQuoteUpdates(new List<CollaborationRequest__c>{ request });
			Test.getEventBus().deliver(); // validates that events have been published
			System.assert(true, 'should deliver event without exception');
		} catch (Exception e) {
			System.assert(false, 'should deliver event without exceptions');
		}
		Test.stopTest();
	}
}
