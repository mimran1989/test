trigger TaskRoleSummaryTrigger on TaskRoleSummary__c(before update) {
	TaskRoleSummarySupport.rollupSummaries(Trigger.newMap, Trigger.oldMap);
}
