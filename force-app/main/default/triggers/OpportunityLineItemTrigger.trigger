trigger OpportunityLineItemTrigger on OpportunityLineItem(before delete) {
	if (Trigger.isBefore) {
		if (Trigger.isDelete) {
			ServiceRecommendationsSupport.deleteOpportunityProductServiceQuote(Trigger.old);
		}
	}
}
