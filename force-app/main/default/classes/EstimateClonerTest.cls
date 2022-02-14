/**
 *  Provus Services Quoting
 *  EstimateClonerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class EstimateClonerTest {
	@testSetup
	static void setup() {
		Id recordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
			.get('Resource Role')
			.getRecordTypeId();
		Product2 resource = TestDataFactory.createResource('Software Engineer', recordTypeId);

		Estimate__c estimate = TestDataFactory.createEstimate('Estimate1', true);
		insert estimate;

		ActivityGroup__c activityGroup = TestDataFactory.createActivityGroup('ActivityGroup');
		activityGroup.EstimateId__c = estimate.Id;
		insert activityGroup;

		Activity__c activity = TestDataFactory.createActivity('Activity', activityGroup.Id);
		insert activity;

		TaskSummary__c taskSummary = TestDataFactory.createTaskSummary();
		insert taskSummary;

		TaskRoleSummary__c taskRoleSummary = TestDataFactory.createTaskRoleSummaryForActivity(
			activity.Id,
			'Activity',
			taskSummary.Id
		);
		insert taskRoleSummary;

		Task__c task = TestDataFactory.createTask(activity.Id, resource.Id, taskRoleSummary.Id);
		insert task;
	}

	@IsTest
	static void testMethod1() {
		String clonedEstimateId = EstimateCloner.createEstimateClone(
			[SELECT Id FROM Estimate__c LIMIT 1]
			.Id,
			'ClonedEstimate'
		);
		system.assertEquals(
			'ClonedEstimate',
			[SELECT Id, Name FROM Estimate__c WHERE ID = :clonedEstimateId]
			.Name,
			'Estimate Cloned Successfully'
		);
	}
}
