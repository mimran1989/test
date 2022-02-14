/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
public with sharing class EventPublisher {
	/**
	 * Publishes a Quote Update event for the given requests. Avoids sending a platform event
	 * for the quote being committed.
	 * @param requests A list of collaboration requests
	 */
	public static void publishQuoteUpdates(List<CollaborationRequest__c> requests) {
		Set<Id> affectedQuoteIds = new Set<Id>();
		for (CollaborationRequest__c request : requests) {
			if (
				request.OwnerId != UserInfo.getUserId() && // don't need to notify self
				CollaborationRequest.NOTIFICATION_STATUSES.contains(request.Status__c)
			) {
				affectedQuoteIds.add(request.QuoteId__c);
			}
		}

		if (affectedQuoteIds.size() == 0) {
			return;
		}

		String collaboratorName = [
			SELECT Name
			FROM User
			WHERE Id = :UserInfo.getUserId()
			WITH SECURITY_ENFORCED
		]
		.Name;

		List<QuoteUpdate__e> events = new List<QuoteUpdate__e>();
		QuoteUpdate__e event = new QuoteUpdate__e(
			AffectedQuotes__c = String.join(new List<Id>(affectedQuoteIds), ','),
			User__c = collaboratorName
		);
		events.add(event);

		if (events.size() > 0) {
			EventBus.publish(events);
		}
	}
}
