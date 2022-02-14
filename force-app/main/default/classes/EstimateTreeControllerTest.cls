/**
 *  Provus Services Quoting
 *  EstimateTreeGridClassTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class EstimateTreeControllerTest {
	@testSetup
	static void setup() {
		EstimateTemplate__c estimateTemplate = TestDataFactory.createEstimateTemplate(
			'EstimateTemplate',
			true,
			null
		);
		insert estimateTemplate;

		ActivityGroupTemplate__c activityGroupTemplate = TestDataFactory.createActivityGroupTemplate(
			'activityGroup1',
			true,
			estimateTemplate.Id
		);
		insert activityGroupTemplate;

		ActivityTemplate__c activityTemplate = TestDataFactory.createActivityTemplate(
			'activityTemplate1',
			true,
			activityGroupTemplate.Id
		);
		insert activityTemplate;

		TaskTemplate__c taskTemplate = TestDataFactory.createTaskTemplate(
			'task1',
			true,
			activityTemplate.Id
		);
		insert taskTemplate;

		TaskParameterTemplate__c taskParamTemplate = TestDataFactory.createTaskParamTemplate(
			'Taskparamtemp',
			true,
			taskTemplate.Id
		);
		taskParamTemplate.DataType__c = 'Picklist';
		insert taskParamTemplate;

		TaskParameterValueTemplate__c taskParamValueTemplate = TestDataFactory.createTaskParamValueTemplate(
			taskParamTemplate.Id
		);
		taskParamValueTemplate.Label__c = 'Yes';
		taskParamValueTemplate.PerUnitDuration__c = 10;
		insert taskParamValueTemplate;

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
		activity.EstimateId__c = estimate.Id;
		insert activity;

		TaskSummary__c taskSummaryforActivity = TestDataFactory.createTaskSummary();
		insert taskSummaryforActivity;

		TaskSummary__c taskSummaryforEstimate = TestDataFactory.createTaskSummary();
		insert taskSummaryforEstimate;

		TaskSummary__c taskSummaryforActivityGroup = TestDataFactory.createTaskSummary();
		insert taskSummaryforActivityGroup;

		activity.SummaryId__c = taskSummaryforActivity.Id;
		update activity;

		estimate.SummaryId__c = taskSummaryforEstimate.Id;
		update estimate;

		activityGroup.SummaryId__c = taskSummaryforActivityGroup.Id;
		update activityGroup;

		TaskRoleSummary__c taskRoleSummary = TestDataFactory.createTaskRoleSummaryForActivity(
			activity.Id,
			'Activity',
			taskSummaryforActivity.Id
		);
		insert taskRoleSummary;

		TaskRoleSummary__c taskRoleSummaryEstimate = TestDataFactory.createTaskRoleSummaryForEstimate(
			estimate.Id,
			'Estimate',
			taskSummaryforEstimate.Id
		);
		insert taskRoleSummaryEstimate;

		Task__c task = TestDataFactory.createTask(activity.Id, resource.Id, taskRoleSummary.Id);
		insert task;

		TaskParameterValue__c taskParamValue = new TaskParameterValue__c();
		taskParamValue.TaskId__c = task.Id;
		taskParamValue.IntegerValue__c = 10;
		taskParamValue.TemplateId__c = taskParamTemplate.Id;
		insert taskParamValue;
	}

	@IsTest
	static void testMethod1() {
		Id estimateId = [SELECT Id FROM Estimate__c LIMIT 1].Id;
		List<Object> objlst = (List<Object>) EstimateTreeController.getRecords(estimateId);
		Map<String, object> firstRecord = (Map<String, object>) objlst[0];
		system.assertEquals(
			'ActivityGroup',
			String.valueof(firstRecord.get('ActivityGroupName')),
			'Activity Group Name Matching'
		);
	}

	@IsTest
	static void testMethod2() {
		EstimateTreeController.updateTask([SELECT Id FROM Task__c LIMIT 1], null);
		system.assertEquals(
			[SELECT Id FROM Activity__c LIMIT 1]
			.Id,
			[SELECT Id, ActivityId__c FROM Task__c LIMIT 1]
			.ActivityId__c,
			'Task Activity is Matching'
		);
	}

	@IsTest
	static void testMethod3() {
		List<TaskRoleSummary__c> resourceRecords = (List<TaskRoleSummary__c>) EstimateTreeController.getSummaryRecords(
			[SELECT ID FROM Activity__c LIMIT 1]
			.Id,
			'Activity'
		);
		system.assertEquals(resourceRecords[0].TotalCalculatedDuration__c, 0, 'Duration Matching');
	}

	@IsTest
	static void testMethod4() {
		map<string, object> taskDetails = EstimateTreeTaskSupport.taskDetails(
			[SELECT ID FROM Task__c LIMIT 1]
			.Id
		);
		system.assertEquals(Boolean.valueof(taskDetails.get('beforeExists')), false, 'Task Exists');
	}

	@IsTest
	static void testMethod5() {
		List<TaskParameterValue__c> resourceRecords = (List<TaskParameterValue__c>) EstimateTreeController.getSourceSummary(
			[SELECT ID FROM Estimate__c LIMIT 1]
			.Id
		);
		system.assertEquals(resourceRecords.size(), 0, 'No Params Exists');
	}

	@IsTest
	static void testMethod6() {
		map<string, Object> taskDetails = (map<string, Object>) EstimateTreeController.getTaskDetails(
			[SELECT ID FROM Task__c LIMIT 1]
			.Id
		);
		system.assertEquals(taskDetails.containsKey('TaskDetails'), true, 'Task Details  Exists');
	}

	@IsTest
	static void testMethod7() {
		EstimateTreeController.updateNotApplicableField(
			[SELECT ID FROM Activity__c LIMIT 1]
			.Id,
			true,
			'Activity'
		);
		EstimateTreeController.updateNotApplicableField(
			[SELECT ID FROM ActivityGroup__c LIMIT 1]
			.Id,
			true,
			'ActivityGroup'
		);
		system.assertEquals(
			[SELECT ID, IsNotApplicable__c FROM Activity__c LIMIT 1]
			.IsNotApplicable__c,
			true,
			'Not Applicable value Updated'
		);
	}

	@IsTest
	static void testMethod8() {
		List<TaskRoleSummary__c> taskRoleSummaryList = [
			SELECT
				Id,
				SummaryLevel__c,
				ActivityId__c,
				EstimateId__c,
				ActivityGroupId__c,
				ResourceRoleId__c,
				LevelAdjustment__c
			FROM TaskRoleSummary__c
		];
		for (TaskRoleSummary__c taskRoleSummary : taskRoleSummaryList) {
			TaskRoleSummary__c taskRoleSummaryClone = taskRoleSummary.clone(false, false, false, false);
			EstimateTreeController.createSummaryRecords(
				taskRoleSummaryClone,
				taskRoleSummary.SummaryLevel__c
			);
		}
		system.assertEquals(
			5,
			[SELECT ID FROM TaskRoleSummary__c].size(),
			'No of Task Role Summary Matches'
		);
	}
}
