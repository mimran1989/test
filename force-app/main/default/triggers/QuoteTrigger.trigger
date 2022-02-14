trigger QuoteTrigger on Quote__c(
	before insert,
	after insert,
	before update,
	after update,
	before delete,
	after delete
) {
	QuoteTriggers.processTrigger(Trigger.oldMap, Trigger.new, Trigger.isBefore);

}
