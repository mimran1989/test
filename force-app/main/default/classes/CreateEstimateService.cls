/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateEstimateService {
	public class TaskRequest {
		Map<Id, Activity__c> activitiesByTemplateId;
		Map<Id, TaskTemplate__c> taskTemplatesById;
		Map<Id, List<Id>> rolesByLevelIds;
		Id estimateId;
	}

	public static Estimate__c createEstimate(Id estimateTemplateId) {
		Map<Id, TaskTemplate__c> taskTemplatesById = new Map<Id, TaskTemplate__c>();
		Map<Id, List<Id>> rolesByLevelIds = new Map<Id, List<Id>>();
		Map<Id, SObject> needSummarySObjects = new Map<Id, SObject>();

		EstimateTemplate__c estimateTemplate = [
			SELECT
				Id,
				Name,
				Description__c,
				Guidance__c,
				IsActive__c,
				RateCardId__c,
				ProductId__c,
				ServiceId__c,
				ServiceId__r.Name,
				(
					SELECT Id, Name, Description__c, Guidance__c, Sequence__c
					FROM ActivityGroups__r
					WHERE IsActive__c = TRUE
				)
			FROM EstimateTemplate__c
			WHERE Id = :estimateTemplateId
			WITH SECURITY_ENFORCED
		];

		Estimate__c estimateSO = Estimate.newSO(estimateTemplate);
		CRUDUtility.insertRecords(estimateSO);
		createResourceDefaultsForEstimate(estimateTemplateId, estimateSO.Id);
		needSummarySObjects.put(estimateSO.Id, estimateSO);

		Map<Id, ActivityGroup__c> activityGroupsByTemplateId = createActivityGroups(
			estimateTemplate.ActivityGroups__r,
			estimateSO.Id
		);

		needSummarySObjects.putAll(activityGroupsByTemplateId.values());

		List<ActivityTemplate__c> activityTemplates = ActivityGroupTemplateService.getActivityTemplates(
			activityGroupsByTemplateId.keySet()
		);

		Map<Id, Activity__c> activitiesByTemplateId = createActivities(
			estimateSO.Id,
			activityTemplates,
			activityGroupsByTemplateId
		);

		for (ActivityTemplate__c activityTemplateSO : activityTemplates) {
			//consolidating all the Task Templates
			if (!activityTemplateSO.Tasks__r.isEmpty()) {
				taskTemplatesById.putAll(activityTemplateSO.Tasks__r);
			}
		}

		needSummarySObjects.putAll(activitiesByTemplateId.values());

		Map<Id, TaskSummary__c> summariesByParentId = TaskSummarySupport.createTaskSummaries(
			needSummarySObjects
		);

		if (!taskTemplatesById.values().isEmpty()) {
			TaskRequest taskRequest = new TaskRequest();
			taskRequest.activitiesByTemplateId = activitiesByTemplateId;
			taskRequest.taskTemplatesById = taskTemplatesById;
			taskRequest.rolesByLevelIds = rolesByLevelIds;
			taskRequest.estimateId = estimateSO.Id;
			List<Task__c> tasks = createTasksFromTemplate(taskRequest);

			Map<String, TaskRoleSummary__c> taskRoleSummaries = createTaskRoleSummaries(
				rolesByLevelIds,
				summariesByParentId
			);

			assignSummaryLineage(taskRoleSummaries, needSummarySObjects);

			for (Task__c task : tasks) {
				String taskRoleSummaryToken = getTaskRoleSummaryKey(
					task.ActivityId__c,
					task.ResourceRoleId__c
				);
				TaskRoleSummary__c taskRoleSummary = taskRoleSummaries.get(taskRoleSummaryToken);
				task.RoleSummaryId__c = taskRoleSummary?.Id;
			}
			CRUDUtility.insertRecords(tasks);

			List<TaskParameterValue__c> taskParameters = createTaskParameters(
				tasks,
				taskTemplatesById.keySet()
			);
			CRUDUtility.insertRecords(taskParameters);
		}
		return estimateSO;
	}

	private static void assignSummaryLineage(
		Map<String, TaskRoleSummary__c> taskRoleSummaries,
		Map<Id, SObject> needSummarySObjects
	) {
		for (TaskRoleSummary__c summary : taskRoleSummaries.values()) {
			Id roleId = summary.ResourceRoleId__c;
			Id parentId;
			if (summary.SummaryLevel__c == EstimatorConstants.ACTIVITY) {
				parentId = (Id) needSummarySObjects.get(summary.ActivityId__c)
					?.get(Schema.Activity__c.ActivityGroupId__c + '');
			} else if (summary.SummaryLevel__c == EstimatorConstants.ACTIVITY_GROUP) {
				parentId = (Id) needSummarySObjects.get(summary.ActivityGroupId__c)
					?.get(Schema.Activity__c.EstimateId__c + '');
			}
			if (parentId != null) {
				summary.TaskRoleSummaryId__c = taskRoleSummaries.get(
						getTaskRoleSummaryKey(parentId, roleId)
					)
					?.Id;
			}
		}

		RuntimeContext.isCreateEstimateMode = true;
		CRUDUtility.updateRecords(taskRoleSummaries.values());
	}

	public static Map<Id, ActivityGroup__c> createActivityGroups(
		List<ActivityGroupTemplate__c> activityGroupTemplates,
		Id estimateId
	) {
		Map<Id, ActivityGroup__c> activityGroupsByTemplateId = new Map<Id, ActivityGroup__c>();

		for (ActivityGroupTemplate__c activityGroupTemplate : activityGroupTemplates) {
			if (!activityGroupsByTemplateId.containsKey(activityGroupTemplate.Id)) {
				ActivityGroup__c activityGroup = ActivityGroup.newSO(activityGroupTemplate);
				activityGroup.EstimateId__c = estimateId;
				activityGroupsByTemplateId.put(activityGroupTemplate.Id, activityGroup);
			}
		}

		CRUDUtility.insertRecords(activityGroupsByTemplateId.values());

		return activityGroupsByTemplateId;
	}

	private static Map<Id, Activity__c> createActivities(
		Id estimateId,
		List<ActivityTemplate__c> activityTemplates,
		Map<Id, ActivityGroup__c> activityGroupsByTemplateId
	) {
		Map<Id, Activity__c> activitiesByTemplateId = new Map<Id, Activity__c>();

		for (ActivityTemplate__c activityTemplate : activityTemplates) {
			Activity__c activity = Activity.newSO(activityTemplate);
			activity.ActivityGroupId__c = activityGroupsByTemplateId.get(
					activityTemplate.ActivityGroupTemplateId__c
				)
				?.Id;
			activitiesByTemplateId.put(activityTemplate.Id, activity);
		}

		for (Activity__c activitySO : activitiesByTemplateId.values()) {
			activitySO.EstimateId__c = estimateId;
		}

		CRUDUtility.insertRecords(activitiesByTemplateId.values());
		return activitiesByTemplateId;
	}

	private static List<Task__c> createTasksFromTemplate(TaskRequest request) {
		List<Task__c> tasks = new List<Task__c>();

		for (TaskTemplate__c taskTemplate : request.taskTemplatesById.values()) {
			Task__c task = Task.newSO(taskTemplate);
			task.ActivityId__c = request.activitiesByTemplateId.get(taskTemplate.ActivityTemplateId__c)
				?.Id;
			task.ActivityGroupId__c = request.activitiesByTemplateId.get(
					taskTemplate.ActivityTemplateId__c
				)
				?.ActivityGroupId__c;
			task.EstimateId__c = request.estimateId;
			tasks.add(task);

			populateSummaryDetails(
				task,
				request.activitiesByTemplateId.get(taskTemplate.ActivityTemplateId__c),
				request.rolesByLevelIds
			);
		}

		return tasks;
	}

	private static Map<String, TaskRoleSummary__c> createTaskRoleSummaries(
		Map<Id, List<Id>> roleSummariesByLevel,
		Map<Id, TaskSummary__c> summariesByParentId
	) {
		Map<String, TaskRoleSummary__c> summariesByProductAndParentId = new Map<String, TaskRoleSummary__c>();

		for (Id parentId : roleSummariesByLevel.keySet()) {
			for (Id roleId : roleSummariesByLevel.get(parentId)) {
				TaskRoleSummary__c roleSummary = new TaskRoleSummary__c();
				roleSummary.ResourceRoleId__c = roleId;
				roleSummary.SummaryId__c = summariesByParentId.get(parentId)?.Id;

				Schema.sObjectType parentType = parentId.getSObjectType();
				if (parentType == Activity__c.sObjectType) {
					roleSummary.ActivityId__c = parentId;
					roleSummary.SummaryLevel__c = EstimatorConstants.ACTIVITY;
				} else if (parentType == ActivityGroup__c.sObjectType) {
					roleSummary.ActivityGroupId__c = parentId;
					roleSummary.SummaryLevel__c = EstimatorConstants.ACTIVITY_GROUP;
				} else if (parentType == Estimate__c.sObjectType) {
					roleSummary.EstimateId__c = parentId;
					roleSummary.SummaryLevel__c = EstimatorConstants.ESTIMATE;
				}

				summariesByProductAndParentId.put(getTaskRoleSummaryKey(parentId, roleId), roleSummary);
			}
		}

		CRUDUtility.insertRecords(summariesByProductAndParentId.values());

		return summariesByProductAndParentId;
	}

	private static List<TaskParameterValue__c> createTaskParameters(
		List<Task__c> tasks,
		Set<Id> taskTemplateIds
	) {
		List<TaskParameterValue__c> taskParameterValues = new List<TaskParameterValue__c>();
		Map<Id, TaskTemplate__c> taskParameterMap = new Map<Id, TaskTemplate__c>(
			[
				SELECT Id, (SELECT Id FROM Parameters__r)
				FROM TaskTemplate__c
				WHERE Id IN :taskTemplateIds
				WITH SECURITY_ENFORCED
			]
		);

		for (Task__c task : tasks) {
			if (
				taskParameterMap.containsKey(task.TemplateId__c) &&
				taskParameterMap.get(task.TemplateId__c).Parameters__r != null
			) {
				for (
					TaskParameterTemplate__c taskParameter : taskParameterMap.get(task.TemplateId__c)
						.Parameters__r
				) {
					TaskParameterValue__c taskParameterValue = new TaskParameterValue__c();
					taskParameterValue.TaskId__c = task.Id;
					taskParameterValue.TemplateId__c = taskParameter.Id;
					taskParameterValues.add(taskParameterValue);
				}
			}
		}

		return taskParameterValues;
	}

	private static void populateSummaryDetails(
		Task__c task,
		Activity__c activity,
		Map<Id, List<Id>> rolesByLevelIds
	) {
		if (!rolesByLevelIds.containsKey(task.ActivityId__c)) {
			rolesByLevelIds.put(task.ActivityId__c, new List<Id>());
		}
		rolesByLevelIds.get(task.ActivityId__c).add(task.ResourceRoleId__c);

		if (!rolesByLevelIds.containsKey(task.ActivityGroupId__c)) {
			rolesByLevelIds.put(task.ActivityGroupId__c, new List<Id>());
		}
		rolesByLevelIds.get(task.ActivityGroupId__c).add(task.ResourceRoleId__c);

		if (!rolesByLevelIds.containsKey(task.EstimateId__c)) {
			rolesByLevelIds.put(task.EstimateId__c, new List<Id>());
		}
		rolesByLevelIds.get(task.EstimateId__c).add(task.ResourceRoleId__c);
	}

	private static String getTaskRoleSummaryKey(Id sObjectId, Id resourceRoleId) {
		return (String) sObjectId + '-' + resourceRoleId;
	}

	private static void createResourceDefaultsForEstimate(Id estimateTemplateId, Id estimateId) {
		List<ResourceDefault__c> estimateResourceDefaults = new List<ResourceDefault__c>();
		for (ResourceDefault__c resourceDefault : [
			SELECT ID, FieldAPIName__c, ProductId__c, TextValue__c
			FROM ResourceDefault__c
			WHERE EstimateTemplateId__c = :estimateTemplateId
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		]) {
			ResourceDefault__c estimateResourceDefault = resourceDefault.clone();
			estimateResourceDefault.EstimateId__c = estimateId;
			estimateResourceDefaults.add(estimateResourceDefault);
		}

		CRUDUtility.insertRecords(estimateResourceDefaults);
	}
}
