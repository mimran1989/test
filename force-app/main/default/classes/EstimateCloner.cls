/**
 *  Provus Services Quoting
 *  EstimateCloner : This is controller for EstimateCloner lwc component.
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class EstimateCloner {
	private static final string NAME_SPACE = SystemUtility.getNamespacePrefix();

	@Auraenabled
	public static String createEstimateClone(String estimateId, String estimateName) {
		Map<Id, SObject> needSummarySObjects = new Map<Id, SObject>();

		//Create Cloned Estimate
		Estimate__c newEstimate = new Estimate__c();
		newEstimate.Name = estimateName;
		newEstimate = processEstimate(needSummarySObjects, estimateId, newEstimate);

		//Create Cloned ActivityGroup
		Map<Id, ActivityGroup__c> activityGroupMap = new Map<Id, ActivityGroup__c>();
		processActivityGroups(needSummarySObjects, activityGroupMap, newEstimate);

		//Create Cloned Activity
		Map<Id, Activity__c> activityMap = new Map<Id, Activity__c>();
		processActivities(needSummarySObjects, activityMap, activityGroupMap);

		//Create and update TaskSummary records
		updateSummaryObjects(needSummarySObjects);
		RuntimeContext.isCreateEstimateMode = true;

		// Inserting Task Role Summary
		@SuppressWarnings('PMD.UnusedLocalVariable')
		Set<Id> activityIds = activityMap.keySet();
		@SuppressWarnings('PMD.UnusedLocalVariable')
		Set<Id> activityGroupIds = activityGroupMap.keySet();
		String taskRoleSummaryQuery =
			'SELECT ' +
			String.join(getObjectFields(NAME_SPACE + 'TaskRoleSummary__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'TaskRoleSummary__c WHERE ActivityId__c IN :activityIds OR ActivityGroupId__c IN :activityGroupIds OR EstimateId__c = :estimateId WITH SECURITY_ENFORCED';
		Map<String, TaskRoleSummary__c> taskroleSummaryMapping = new Map<String, TaskRoleSummary__c>();
		for (
			TaskRoleSummary__c taskRoleSummary : Database.query(
				String.escapeSingleQuotes(taskRoleSummaryQuery)
			)
		) {
			TaskRoleSummary__c taskRoleSummaryNew = taskRoleSummary.clone(false, false, false, false);
			taskRoleSummaryNew.ActivityId__c = activityMap.get(taskRoleSummary.ActivityId__c)?.Id;
			taskRoleSummaryNew.ActivityGroupId__c = activityGroupMap.get(
					taskRoleSummary.ActivityGroupId__c
				)
				?.Id;
			taskRoleSummaryNew.EstimateId__c = taskRoleSummary.EstimateId__c != null
				? newEstimate.Id
				: null;
			if (taskRoleSummary.SummaryLevel__c == 'Activity') {
				taskRoleSummaryNew.SummaryId__c = String.valueof(
					needSummarySObjects.get(taskRoleSummaryNew.ActivityId__c)
						?.get(NAME_SPACE + 'SummaryId__c')
				);
				taskroleSummaryMapping.put(
					taskRoleSummary.ActivityId__c +
					'-' +
					taskRoleSummary.ResourceRoleId__c,
					taskRoleSummaryNew
				);
			} else if (taskRoleSummary.SummaryLevel__c == 'Activity Group') {
				taskRoleSummaryNew.SummaryId__c = String.valueof(
					needSummarySObjects.get(taskRoleSummaryNew.ActivityGroupId__c)
						?.get(NAME_SPACE + 'SummaryId__c')
				);
				taskroleSummaryMapping.put(
					taskRoleSummary.ActivityGroupId__c +
					'-' +
					taskRoleSummary.ResourceRoleId__c,
					taskRoleSummaryNew
				);
			} else if (taskRoleSummary.SummaryLevel__c == 'Estimate') {
				taskRoleSummaryNew.SummaryId__c = String.valueof(
					needSummarySObjects.get(taskRoleSummaryNew.EstimateId__c)
						?.get(NAME_SPACE + 'SummaryId__c')
				);
				taskroleSummaryMapping.put(
					estimateId +
					'-' +
					taskRoleSummary.ResourceRoleId__c,
					taskRoleSummaryNew
				);
			}
		}
		CRUDUtility.insertRecords(taskroleSummaryMapping.values());

		Map<Id, Task__c> taskMap = new Map<Id, Task__c>();
		// Inserting Task Records
		String taskQuery =
			'SELECT ' +
			String.join(getObjectFields(NAME_SPACE + 'Task__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'Task__c WHERE ActivityId__c IN :activityIds WITH SECURITY_ENFORCED';

		for (Task__c task : Database.query(String.escapeSingleQuotes(taskQuery))) {
			Task__c taskNew = task.clone(false, false, false, false);
			taskNew.ActivityId__c = activityMap.get(task.ActivityId__c).Id;
			taskNew.ActivityGroupId__c = activityGroupMap.get(task.ActivityId__c)?.Id;
			taskNew.EstimateId__c = newEstimate.Id;
			taskNew.RoleSummaryId__c = taskroleSummaryMapping.get(
					task.ActivityId__c +
					'-' +
					task.ResourceRoleId__c
				)
				?.Id;
			taskMap.put(task.Id, taskNew);
		}
		CRUDUtility.insertRecords(taskMap.values());
		Map<Id, Id> oldNewTasks = new Map<Id, Id>();
		for (Id taskOld : taskMap.keySet()) {
			oldNewTasks.put(taskOld, taskMap.get(taskOld).Id);
		}
		//Calling the Future method to avoid Governor Limits
		createTaskParamsValueInFuture(oldNewTasks);
		return newEstimate.Id;
	}

	public static Estimate__c processEstimate(
		Map<Id, SObject> needSummarySObjects,
		Id estimateId,
		Estimate__c newEstimate
	) {
		// Creating Estimate
		String clonedEstimateName = newEstimate.Name;
		String estimateQuery =
			'SELECT ' +
			String.join(getObjectFields(NAME_SPACE + 'Estimate__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'Estimate__c WHERE Id =:estimateId WITH SECURITY_ENFORCED Limit 1';
		Estimate__c existingEstimate = Database.query(String.escapeSingleQuotes(estimateQuery));
		newEstimate = existingEstimate.clone(false, false, false, false);
		newEstimate.DerivedFromId__c = existingEstimate.Id;
		newEstimate.Name = clonedEstimateName;
		CRUDUtility.insertRecords(newEstimate);
		needSummarySObjects.put(newEstimate.Id, newEstimate);
		return newEstimate;
	}

	public static void processActivityGroups(
		Map<Id, SObject> needSummarySObjects,
		Map<Id, ActivityGroup__c> activityGroupMap,
		Estimate__c newEstimate
	) {
		@SuppressWarnings('PMD.UnusedLocalVariable')
		String estimateId = newEstimate.DerivedFromId__c;
		String activityGroupQuery =
			'SELECT ' +
			string.join(getObjectFields(NAME_SPACE + 'ActivityGroup__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'ActivityGroup__c WHERE EstimateId__c=:estimateId WITH SECURITY_ENFORCED';
		for (
			ActivityGroup__c activityGroup : Database.query(String.escapeSingleQuotes(activityGroupQuery))
		) {
			ActivityGroup__c activityGroupNew = activityGroup.clone(false, false, false, false);
			activityGroupNew.EstimateId__c = newEstimate.Id;
			activityGroupMap.put(activityGroup.Id, activityGroupNew);
		}
		CRUDUtility.insertRecords(activityGroupMap.values());
		needSummarySObjects.putAll(activityGroupMap.values());
	}
	public static void processActivities(
		Map<Id, SObject> needSummarySObjects,
		Map<Id, Activity__c> activityMap,
		Map<Id, ActivityGroup__c> activityGroupMap
	) {
		@SuppressWarnings('PMD.UnusedLocalVariable')
		Set<Id> activityGroupOldIds = activityGroupMap.KeySet();
		String activityQuery =
			'SELECT ' +
			string.join(getObjectFields(NAME_SPACE + 'Activity__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'Activity__c WHERE ActivityGroupId__c IN :activityGroupOldIds WITH SECURITY_ENFORCED';
		for (Activity__c activity : Database.query(String.escapeSingleQuotes(activityQuery))) {
			Activity__c activityNew = activity.clone(false, false, false, false);
			activityNew.ActivityGroupId__c = activityGroupMap.get(activity.ActivityGroupId__c)?.Id;
			activityMap.put(activity.Id, activityNew);
		}
		CRUDUtility.insertRecords(activityMap.values());
		needSummarySObjects.putAll(activityMap.values());
	}
	public static void updateSummaryObjects(Map<Id, SObject> needSummarySObjects) {
		List<TaskSummary__c> taskSummaryToInsert = new List<TaskSummary__c>();
		for (Id recordId : needSummarySObjects.keySet()) {
			taskSummaryToInsert.add(new TaskSummary__c());
		}
		CRUDUtility.insertRecords(taskSummaryToInsert);
		Integer i = 0;
		for (Sobject record : needSummarySObjects.values()) {
			record.put(NAME_SPACE + 'SummaryId__c', taskSummaryToInsert[i].Id);
			i++;
		}
		CRUDUtility.updateRecords(needSummarySObjects.values());
	}

	@Future
	public static void createTaskParamsValueInFuture(Map<Id, Id> oldNewTasks) {
		// Creating TaskParamterValue records
		@SuppressWarnings('PMD.UnusedLocalVariable')
		Set<Id> taskIds = oldNewTasks.keySet();
		String taskParamQry =
			'SELECT ' +
			string.join(getObjectFields(NAME_SPACE + 'TaskParameterValue__c'), ',') +
			' FROM ' +
			NAME_SPACE +
			'TaskParameterValue__c WHERE TaskId__c IN :taskIds WITH SECURITY_ENFORCED';
		Map<Id, TaskParameterValue__c> taskParameterMap = new Map<Id, TaskParameterValue__c>();
		for (
			TaskParameterValue__c taskParam : Database.query(String.escapeSingleQuotes(taskParamQry))
		) {
			TaskParameterValue__c taskParameterNew = taskParam.clone(false, false, false, false);
			taskParameterNew.TemplateId__c = taskParam.TemplateId__c;
			taskParameterNew.TaskId__c = oldNewTasks.get(taskParam.TaskId__c);
			taskParameterMap.put(taskParam.Id, taskParameterNew);
		}
		CRUDUtility.insertRecords(taskParameterMap.values());
	}
	public static List<String> getObjectFields(string objectApiName) {
		SObjectType contactType = Schema.getGlobalDescribe().get(objectApiName);
		Map<String, Schema.SObjectField> mfields = contactType.getDescribe().fields.getMap();
		List<String> sObjectDetailsList = new List<String>();
		for (String field : mfields.keySet()) {
			if (mfields.get(field).getDescribe().isAccessible()) {
				sObjectDetailsList.add(String.valueOf(mfields.get(field)));
			}
		}
		return sObjectDetailsList;
	}
}
