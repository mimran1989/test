/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class EstimateTreeSummarySupport {
	public static void createRoleSummaryLineageForActivity(
		Id activityId,
		Id resourceRoleId,
		Decimal levelAdjustment
	) {
		TaskRoleSummary__c estimateSummary;
		TaskRoleSummary__c groupSummary;

		Activity__c activitySO = [
			SELECT
				EstimateId__c,
				SummaryId__c,
				EstimateId__r.SummaryId__c,
				ActivityGroupId__c,
				ActivityGroupId__r.SummaryId__c
			FROM Activity__c
			WHERE Id = :activityId
			WITH SECURITY_ENFORCED
		];

		for (
			TaskRoleSummary__c summary : getRoleSummaryLineageForActivity(activityId, resourceRoleId)
		) {
			if (estimateSummary != null && groupSummary != null) {
				break;
			}

			if (summary.SummaryLevel__c == EstimatorConstants.ESTIMATE) {
				estimateSummary = summary;
			} else if (summary.SummaryLevel__c == EstimatorConstants.ACTIVITY_GROUP) {
				groupSummary = summary;
			}
		}

		if (estimateSummary == null) {
			estimateSummary = new TaskRoleSummary__c(
				ResourceRoleId__c = resourceRoleId,
				EstimateId__c = activitySO.EstimateId__c,
				SummaryId__c = activitySO.EstimateId__r.SummaryId__c,
				SummaryLevel__c = EstimatorConstants.ESTIMATE
			);

			CRUDUtility.insertRecords(estimateSummary);
		}

		if (groupSummary == null) {
			groupSummary = new TaskRoleSummary__c(
				ResourceRoleId__c = resourceRoleId,
				ActivityGroupId__c = activitySO.ActivityGroupId__c,
				SummaryId__c = activitySO.ActivityGroupId__r.SummaryId__c,
				SummaryLevel__c = EstimatorConstants.ACTIVITY_GROUP,
				TaskRoleSummaryId__c = estimateSummary.Id
			);

			CRUDUtility.insertRecords(groupSummary);
		}

		TaskRoleSummary__c activitySummary = new TaskRoleSummary__c(
			ResourceRoleId__c = resourceRoleId,
			ActivityId__c = activityId,
			SummaryId__c = activitySO.SummaryId__c,
			SummaryLevel__c = EstimatorConstants.ACTIVITY,
			TaskRoleSummaryId__c = groupSummary.Id
		);

		CRUDUtility.insertRecords(activitySummary);

		activitySummary.LevelAdjustment__c = levelAdjustment;
		CRUDUtility.upsertRecords(activitySummary);
	}

	public static void createRoleSummaryLineageForActivityGroup(
		Id groupId,
		Id resourceRoleId,
		Decimal levelAdjustment
	) {
		TaskRoleSummary__c estimateSummary;

		ActivityGroup__c groupSO = [
			SELECT EstimateId__c, SummaryId__c, EstimateId__r.SummaryId__c
			FROM ActivityGroup__c
			WHERE Id = :groupId
			WITH SECURITY_ENFORCED
		];

		for (
			TaskRoleSummary__c summary : getRoleSummaryLineageForActivityGroup(groupId, resourceRoleId)
		) {
			if (summary.SummaryLevel__c == EstimatorConstants.ESTIMATE) {
				estimateSummary = summary;
				break;
			}
		}

		if (estimateSummary == null) {
			estimateSummary = new TaskRoleSummary__c(
				ResourceRoleId__c = resourceRoleId,
				EstimateId__c = groupSO.EstimateId__c,
				SummaryId__c = groupSO.EstimateId__r.SummaryId__c,
				SummaryLevel__c = EstimatorConstants.ESTIMATE
			);
			CRUDUtility.insertRecords(estimateSummary);
		}

		TaskRoleSummary__c groupSummarySO = new TaskRoleSummary__c(
			ResourceRoleId__c = resourceRoleId,
			ActivityGroupId__c = groupId,
			SummaryId__c = groupSO.SummaryId__c,
			SummaryLevel__c = EstimatorConstants.ACTIVITY_GROUP,
			TaskRoleSummaryId__c = estimateSummary.Id
		);

		CRUDUtility.insertRecords(groupSummarySO);

		groupSummarySO.LevelAdjustment__c = levelAdjustment;
		CRUDUtility.updateRecords(groupSummarySO);
	}

	public static List<TaskRoleSummary__c> getRoleSummaryLineageForActivity(
		Id activityId,
		Id resourceRoleId
	) {
		Activity__c actSO = [
			SELECT ActivityGroupId__c, EstimateId__c
			FROM Activity__c
			WHERE Id = :activityId
			WITH SECURITY_ENFORCED
		];

		return [
			SELECT Id, SummaryLevel__c
			FROM TaskRoleSummary__c
			WHERE
				(ActivityId__c = :activityId
				OR ActivityGroupId__c = :actSO.ActivityGroupId__c
				OR EstimateId__c = :actSO.EstimateId__c)
				AND ResourceRoleId__c = :resourceRoleId
			WITH SECURITY_ENFORCED
		];
	}

	public static List<TaskRoleSummary__c> getRoleSummaryLineageForActivityGroup(
		Id activityGroupId,
		Id resourceRoleId
	) {
		ActivityGroup__c groupSO = [
			SELECT EstimateId__c
			FROM ActivityGroup__c
			WHERE Id = :activityGroupId
			WITH SECURITY_ENFORCED
		];

		return [
			SELECT Id, SummaryLevel__c
			FROM TaskRoleSummary__c
			WHERE
				(ActivityGroupId__c = :activityGroupId
				OR EstimateId__c = :groupSO.EstimateId__c)
				AND ResourceRoleId__c = :resourceRoleId
			WITH SECURITY_ENFORCED
		];
	}

	public static Object getSummaryRecords(String recordId, String type) {
		if (type == 'Activity') {
			return [
				SELECT
					Id,
					ResourceRole__c,
					ResourceRoleId__r.Name,
					TotalCalculatedDuration__c,
					TotalAdjustments__c,
					LevelAdjustment__c,
					TotalEstimatedDuration__c
				FROM TaskRoleSummary__c
				WHERE ActivityId__c = :recordId
				WITH SECURITY_ENFORCED
			];
		} else if (type == EstimateTreeSupport.ACTIVITY_GROUP) {
			return [
				SELECT
					Id,
					ResourceRole__c,
					ResourceRoleId__r.Name,
					TotalCalculatedDuration__c,
					TotalAdjustments__c,
					LevelAdjustment__c,
					TotalEstimatedDuration__c
				FROM TaskRoleSummary__c
				WHERE ActivityGroupId__c = :recordId
				WITH SECURITY_ENFORCED
			];
		} else if (type == 'Estimate') {
			return [
				SELECT
					Id,
					ResourceRole__c,
					ResourceRoleId__r.Name,
					TotalCalculatedDuration__c,
					TotalAdjustments__c,
					LevelAdjustment__c,
					TotalEstimatedDuration__c
				FROM TaskRoleSummary__c
				WHERE EstimateId__c = :recordId
				WITH SECURITY_ENFORCED
			];
		} else {
			return null;
		}
	}

	public static void createSummaryRecords(TaskRoleSummary__c taskRoleSummary, String typeof) {
		Id summaryId;
		String summaryLevel;
		if (typeof == EstimatorConstants.ESTIMATE) {
			summaryLevel = EstimatorConstants.ESTIMATE;
			summaryId = [
				SELECT Id, SummaryId__c
				FROM Estimate__c
				WHERE Id = :taskRoleSummary.EstimateId__c
			]
			.SummaryId__c;
			taskRoleSummary.SummaryId__c = summaryId;
			taskRoleSummary.SummaryLevel__c = summaryLevel;
			CRUDUtility.insertRecords(taskRoleSummary);
		} else if (typeof == EstimateTreeSupport.ACTIVITY_GROUP) {
			EstimateTreeSummarySupport.createRoleSummaryLineageForActivityGroup(
				taskRoleSummary.ActivityGroupId__c,
				taskRoleSummary.ResourceRoleId__c,
				taskRoleSummary.LevelAdjustment__c
			);
		} else if (typeof == EstimatorConstants.ACTIVITY) {
			EstimateTreeSummarySupport.createRoleSummaryLineageForActivity(
				taskRoleSummary.ActivityId__c,
				taskRoleSummary.ResourceRoleId__c,
				taskRoleSummary.LevelAdjustment__c
			);
		}
	}
}
