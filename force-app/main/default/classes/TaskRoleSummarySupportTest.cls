/**
 *  Provus Services Quoting
 *  TaskRoleSummarySupportTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class TaskRoleSummarySupportTest extends TestBase {
	static TaskSummary__c newTaskSummary() {
		TaskSummary__c newSummary = new TaskSummary__c();
		CRUDUtility.insertRecords(newSummary);

		return newSummary;
	}

	static TaskRoleSummary__c newTaskRoleSummary(TaskRoleSummary__c parentRecord) {
		TaskRoleSummary__c roleSummary = new TaskRoleSummary__c(
			SummaryId__c = parentRecord.SummaryId__c,
			TaskRoleSummaryId__c = parentRecord.Id
		);
		CRUDUtility.insertRecords(roleSummary);
		return roleSummary;
	}

	static TaskRoleSummary__c newTaskRoleSummary() {
		TaskSummary__c taskSummary = newTaskSummary();
		TaskRoleSummary__c roleSummary = new TaskRoleSummary__c(SummaryId__c = taskSummary.Id);

		CRUDUtility.insertRecords(roleSummary);
		return roleSummary;
	}

	static Task__c newTask(Id roleSummaryId) {
		Task__c task = new Task__c(IsActive__c = true, RoleSummaryId__c = roleSummaryId);
		CRUDUtility.insertRecords(task);
		return task;
	}

	@IsTest
	static void itShouldShouldRollupTasksToParentSummary() {
		TaskRoleSummary__c parentSummary = newTaskRoleSummary();
		TaskRoleSummary__c childSummary = newTaskRoleSummary(parentSummary);

		Task__c task1 = newTask(childSummary.Id);
		task1.CalculatedDuration__c = 100;
		task1.LevelAdjustment__c = 50;
		task1.EstimatedDuration__c = 50;

		Task__c task2 = newTask(childSummary.Id);
		task2.CalculatedDuration__c = 200;
		task2.LevelAdjustment__c = 100;
		task2.EstimatedDuration__c = 100;

		Test.startTest();
		CRUDUtility.updateRecords(new List<Task__c>{ task1, task2 });

		TaskRoleSummary__c testSummary = [
			SELECT Id, RolledUpCalculatedDuration__c, RolledUpAdjustments__c
			FROM TaskRoleSummary__c
			WHERE Id = :parentSummary.Id
			WITH SECURITY_ENFORCED
		];

		System.assertEquals(
			300,
			testSummary.RolledUpCalculatedDuration__c,
			'it should rollup calculated duration to parent'
		);
		System.assertEquals(
			150,
			testSummary.RolledUpAdjustments__c,
			'it should rollup adjustments to parent'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldRollupWhenParentAndChildBothChange() {
		TaskRoleSummary__c parentSummary = newTaskRoleSummary();
		TaskRoleSummary__c childSummary = newTaskRoleSummary(parentSummary);

		Task__c task = newTask(childSummary.Id);
		task.CalculatedDuration__c = 100;
		task.LevelAdjustment__c = 50;
		task.EstimatedDuration__c = 50;

		CRUDUtility.updateRecords(task);

		parentSummary.LevelAdjustment__c = 1500;
		childSummary.LevelAdjustment__c = 500;

		Test.startTest();
		// TODO: Fix logic for same updates in the trigger
		CRUDUtility.updateRecords(new List<TaskRoleSummary__c>{ parentSummary });
		CRUDUtility.updateRecords(new List<TaskRoleSummary__c>{ childSummary });

		TaskRoleSummary__c testSummary = [
			SELECT Id, TotalAdjustments__c
			FROM TaskRoleSummary__c
			WHERE Id = :parentSummary.Id
			WITH SECURITY_ENFORCED
		];

		System.assertEquals(
			2050,
			testSummary.TotalAdjustments__c,
			'it should rollup level adjustments to parent'
		);
		Test.stopTest();
	}
	@IsTest
	static void itShouldShouldRollupLevelAdjustmentsToParentSummary() {
		TaskRoleSummary__c parentSummary = newTaskRoleSummary();
		TaskRoleSummary__c childSummary = newTaskRoleSummary(parentSummary);

		Task__c task = newTask(childSummary.Id);
		task.CalculatedDuration__c = 100;
		task.LevelAdjustment__c = 50;
		task.EstimatedDuration__c = 50;

		CRUDUtility.updateRecords(task);

		childSummary.LevelAdjustment__c = 500;

		Test.startTest();
		CRUDUtility.updateRecords(childSummary);

		TaskRoleSummary__c testSummary = [
			SELECT Id, RolledUpCalculatedDuration__c, RolledUpAdjustments__c
			FROM TaskRoleSummary__c
			WHERE Id = :parentSummary.Id
			WITH SECURITY_ENFORCED
		];

		System.assertEquals(
			550,
			testSummary.RolledUpAdjustments__c,
			'it should rollup level adjustments to parent'
		);
		Test.stopTest();
	}
}
