/**
 *  Provus Services Quoting
 *  TaskRoleSummarySupport
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class TaskRoleSummarySupport {
	public static void rollupSummaries(
		Map<Id, TaskRoleSummary__c> newSummaries,
		Map<Id, TaskRoleSummary__c> oldSummaries
	) {
		if (RuntimeContext.isCreateEstimateMode) {
			return;
		}

		Set<Id> parentIds = new Set<Id>();
		List<TaskRoleSummary__c> taskRollSummariesWithParent = new List<TaskRoleSummary__c>();
		// create list of new child task role summary records (has parent task role summary record) and parent ids
		for (TaskRoleSummary__c roleSummary : newSummaries.values()) {
			Id parentId = roleSummary.TaskRoleSummaryId__c;
			if (parentId != null) {
				parentIds.add(parentId);
				taskRollSummariesWithParent.add(roleSummary);
			}
		}

		// get parent task role summaries
		Map<Id, TaskRoleSummary__c> parentRecords = getTaskRoleSummariesForRollups(parentIds);

		// iterate over new task role summaries with parent task role summaries (aka child records)
		Map<Id, TaskRoleSummary__c> taskRollSummariesToUpdate = new Map<Id, TaskRoleSummary__c>();
		for (TaskRoleSummary__c roleSummary : taskRollSummariesWithParent) {
			// get previous version of child task role summary record
			TaskRoleSummary__c oldSummary = oldSummaries.get(roleSummary.Id);
			// get parent task role summary for current task role summary record
			TaskRoleSummary__c parentTaskRoleSummary = parentRecords.get(
				roleSummary.TaskRoleSummaryId__c
			);

			// determine calculated duration value using , if value different from parent task role summary then update
			Boolean isParentUpdated = false;
			Decimal newCalculatedDuration =
				NumericHelper.nullToZero(parentTaskRoleSummary.RolledUpCalculatedDuration__c) +
				NumericHelper.delta(
					roleSummary.RolledUpCalculatedDuration__c,
					oldSummary.RolledUpCalculatedDuration__c
				) +
				NumericHelper.delta(roleSummary.CalculatedDuration__c, oldSummary.CalculatedDuration__c);
			if (newCalculatedDuration != parentTaskRoleSummary.RolledUpCalculatedDuration__c) {
				parentTaskRoleSummary.RolledUpCalculatedDuration__c = newCalculatedDuration;
				isParentUpdated = true;
			}

			Decimal newAdjustedDuration =
				NumericHelper.nullToZero(parentTaskRoleSummary.RolledUpAdjustments__c) +
				NumericHelper.delta(roleSummary.RolledUpAdjustments__c, oldSummary.RolledUpAdjustments__c) + // calculate a `total adjustment` value
				NumericHelper.delta(roleSummary.LevelAdjustments__c, oldSummary.LevelAdjustments__c) +
				NumericHelper.delta(roleSummary.LevelAdjustment__c, oldSummary.LevelAdjustment__c);
			if (newAdjustedDuration != parentTaskRoleSummary.RolledUpAdjustments__c) {
				parentTaskRoleSummary.RolledUpAdjustments__c = newAdjustedDuration;
				isParentUpdated = true;
			}

			// only update parent task role summary records if durations for child task role summaries change
			Boolean isParentInContext = newSummaries.containsKey(parentTaskRoleSummary.Id);
			if (isParentUpdated && !isParentInContext) {
				taskRollSummariesToUpdate.put(parentTaskRoleSummary.Id, parentTaskRoleSummary);
			}
		}

		CRUDUtility.updateRecords(taskRollSummariesToUpdate.values());
	}

	private static Map<Id, TaskRoleSummary__c> getTaskRoleSummariesForRollups(Set<Id> recordIds) {
		return new Map<Id, TaskRoleSummary__c>(
			[
				SELECT
					Id,
					RolledUpCalculatedDuration__c,
					RolledUpEstimatedDuration__c,
					RolledUpAdjustments__c,
					LevelAdjustment__c
				FROM TaskRoleSummary__c
				WHERE Id = :recordIds
				WITH SECURITY_ENFORCED
			]
		);
	}
}
