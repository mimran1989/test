/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
trigger CollaborationRequestTrigger on CollaborationRequest__c(after update) {
	if (Trigger.isAfter) {
		if (Trigger.isUpdate) {
			EventPublisher.publishQuoteUpdates(Trigger.new);
		}
	}

}
