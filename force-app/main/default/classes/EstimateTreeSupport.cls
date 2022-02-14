/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class EstimateTreeSupport {
	public static final String ACTIVITY_GROUP = 'ActivityGroup';

	public static Object createActivityAndTask(
		List<Activity__c> activityList,
		List<String> gridExpanedIds,
		Map<Id, String> roleSumMp
	) {
		List<Object> activityGroupChildren = new List<Object>();
		for (Activity__c activity : activityList) {
			Map<String, Object> activityMap = processActivity(activity, gridExpanedIds);
			List<Object> taskObj = new List<Object>();
			if (activity.Tasks__r != null) {
				for (Task__c task : activity.Tasks__r) {
					//Building the Task
					taskObj.add(processTask(task, gridExpanedIds));
				}
			}
			if (roleSumMp.containsKey(activity.Id)) {
				activityMap.put('Resourcerole', roleSumMp.get(activity.Id));
			}
			activityMap.put('_children', taskObj);
			activityGroupChildren.add(activityMap);
		}
		return activityGroupChildren;
	}

	private static Map<String, Object> processActivity(
		Activity__c activity,
		List<String> gridExpanedIds
	) {
		Map<String, Object> activityMap = new Map<String, Object>();
		//Building the Activities
		activityMap.put('Type', 'Activity');
		activityMap.put(ACTIVITY_GROUP, activity.Path__c + ' ' + activity.Name);
		activityMap.put('ActivityGroupName', activity.Name);
		activityMap.put('ActivityGroupId', activity.Id);
		activityMap.put('EstimatedDuration', activity.TotalEstimatedDuration__c);
		activityMap.put('AdjustedDuration', activity.TotalAdjustments__c);
		activityMap.put('levelAdjustments', activity.TotalLevelAdjustments__c);
		activityMap.put('CalculatedDuration', activity.TotalCalculatedDuration__c);
		activityMap.put('IconType', 'standard:work_type');
		activityMap.put('NotApplicable', activity.IsNotApplicable__c);
		activityMap.put('ActionbuttonTitle', 'Resource Summary');
		activityMap.put('ActionIcon', 'action:share_poll');
		gridExpanedIds.add(activity.Id);
		return activityMap;
	}

	private static Map<String, Object> processTask(Task__c task, List<String> gridExpanedIds) {
		Map<String, Object> taskMap = new Map<String, Object>();
		taskMap.put('Type', 'Task');
		taskMap.put(ACTIVITY_GROUP, task.Path__c + ' ' + task.Name);
		taskMap.put('ActivityGroupName', task.Name);
		taskMap.put('ActivityGroupId', task.Id);
		taskMap.put('AdjustmentReason', task.AdjustmentReason__c);
		taskMap.put(
			'EstimatedDuration',
			task.EstimatedDuration__c != null ? task.EstimatedDuration__c : 0
		);
		taskMap.put('levelAdjustments', task.LevelAdjustment__c != null ? task.LevelAdjustment__c : 0);
		taskMap.put(
			'CalculatedDuration',
			task.CalculatedDuration__c != null ? task.CalculatedDuration__c : 0
		);
		taskMap.put('Resourcerole', task.ResourceRoleId__r.Name);
		taskMap.put('IconType', 'standard:task');
		taskMap.put('NotTouched', task.EstimatedDuration__c == 0 ? 'utility:warning' : '');
		if (task.IsNotApplicable__c) {
			taskMap.put('NotTouched', '');
		}
		taskMap.put('TaskTemplateId', task.TemplateId__c);
		taskMap.put('NotApplicable', task.IsNotApplicable__c);
		taskMap.put('ActionbuttonTitle', 'Edit Task');
		taskMap.put('ActionIcon', 'action:edit');
		gridExpanedIds.add(task.Id);
		return taskMap;
	}

	public static void notApplicableForActivity(String recordId, Boolean notApplicable, String type) {
		Activity__c at = new Activity__c();
		at.Id = recordId;
		at.IsNotApplicable__c = notApplicable;
		CRUDUtility.updateRecords(at);
		Id activityGrpId;
		List<Task__c> tklst = [
			SELECT
				Id,
				ActivityId__r.ActivityGroupId__c,
				IsNotApplicable__c,
				CalculatedDuration__c,
				LevelAdjustment__c,
				EstimatedDuration__c
			FROM Task__c
			WHERE ActivityId__c = :recordId
			WITH SECURITY_ENFORCED
		];
		for (Task__c tk : tklst) {
			activityGrpId = tk.ActivityId__r.ActivityGroupId__c;
			tk.IsNotApplicable__c = notApplicable;
			if (notApplicable) {
				tk.CalculatedDuration__c = 0;
				tk.LevelAdjustment__c = 0;
				tk.EstimatedDuration__c = 0;
			}
		}
		CRUDUtility.updateRecords(tklst);
		if (!notApplicable) {
			ActivityGroup__c ag = new ActivityGroup__c();
			ag.Id = activityGrpId;
			ag.IsNotApplicable__c = notApplicable;
			CRUDUtility.updateRecords(ag);
		}
		if (notApplicable) {
			List<TaskRoleSummary__c> actSumRllst = [
				SELECT Id, LevelAdjustment__c
				FROM TaskRoleSummary__c
				WHERE ActivityId__c = :recordId
				WITH SECURITY_ENFORCED
			];
			for (TaskRoleSummary__c asm : actSumRllst) {
				asm.LevelAdjustment__c = 0;
			}
			CRUDUtility.updateRecords(actSumRllst);
		}
	}

	public static void notApplicableForActivityGroup(
		String recordId,
		Boolean notApplicable,
		String type
	) {
		ActivityGroup__c ag = new ActivityGroup__c();
		ag.Id = recordId;
		ag.IsNotApplicable__c = notApplicable;
		CRUDUtility.updateRecords(ag);
		List<Activity__c> actLst = [
			SELECT Id, IsNotApplicable__c
			FROM Activity__c
			WHERE ActivityGroupId__c = :recordId
			WITH SECURITY_ENFORCED
		];
		for (Activity__c tk : actLst) {
			tk.IsNotApplicable__c = notApplicable;
		}
		CRUDUtility.updateRecords(actLst);
		List<Task__c> tklst = [
			SELECT Id, IsNotApplicable__c, CalculatedDuration__c, LevelAdjustment__c, EstimatedDuration__c
			FROM Task__c
			WHERE ActivityId__r.ActivityGroupId__c = :recordId
			WITH SECURITY_ENFORCED
		];
		for (Task__c tk : tklst) {
			tk.IsNotApplicable__c = notApplicable;
			if (notApplicable) {
				tk.CalculatedDuration__c = 0;
				tk.LevelAdjustment__c = 0;
				tk.EstimatedDuration__c = 0;
			}
		}
		CRUDUtility.updateRecords(tklst);
		if (notApplicable) {
			List<TaskRoleSummary__c> agrGrpSumlst = [
				SELECT Id, LevelAdjustment__c
				FROM TaskRoleSummary__c
				WHERE ActivityGroupId__c = :recordId
				WITH SECURITY_ENFORCED
			];
			for (TaskRoleSummary__c agSum : agrGrpSumlst) {
				agSum.LevelAdjustment__c = 0;
			}
			CRUDUtility.updateRecords(agrGrpSumlst);
			List<TaskRoleSummary__c> actSumRllst = [
				SELECT Id, LevelAdjustment__c
				FROM TaskRoleSummary__c
				WHERE ActivityId__r.ActivityGroupId__c = :recordId
				WITH SECURITY_ENFORCED
			];
			for (TaskRoleSummary__c asm : actSumRllst) {
				asm.LevelAdjustment__c = 0;
			}
			CRUDUtility.updateRecords(actSumRllst);
		}
	}

	public static Map<String, Object> taskDetailObject(Task__c tk) {
		Map<String, Object> tskMp = new Map<String, Object>();
		tskMp.put('Type', 'Task');
		tskMp.put(EstimateTreeSupport.ACTIVITY_GROUP, tk.Path__c + ' ' + tk.Name);
		tskMp.put('ActivityGroupName', tk.Name);
		tskMp.put('ActivityGroupId', tk.Id);
		tskMp.put('AdjustmentReason', tk.AdjustmentReason__c);
		tskMp.put('EstimatedDuration', tk.EstimatedDuration__c != null ? tk.EstimatedDuration__c : 0);
		tskMp.put('AdjustedDuration', tk.LevelAdjustment__c != null ? tk.LevelAdjustment__c : 0);
		tskMp.put(
			'CalculatedDuration',
			tk.CalculatedDuration__c != null ? tk.CalculatedDuration__c : 0
		);
		tskMp.put('Resourcerole', tk.ResourceRoleId__r.Name);
		tskMp.put('TaskTemplateId', tk.TemplateId__c);
		tskMp.put('NotApplicable', tk.IsNotApplicable__c);
		tskMp.put('Level2', tk.ActivityId__r.Name);
		tskMp.put('Level1', tk.ActivityId__r.ActivityGroupId__r.Name);
		return tskMp;
	}

	public static void processObject(
		TaskParameterTemplate__c taskParameterTemplate,
		Map<String, Object> mapObject,
		Map<Id, TaskParameterValue__c> taskParameterValueMap
	) {
		if (taskParameterValueMap.containsKey(taskParameterTemplate.Id)) {
			mapObject.put('TaskParameterValueId', taskParameterValueMap.get(taskParameterTemplate.Id).Id);
			if (taskParameterTemplate.DataType__c == EstimatorConstants.INTEGER_DATATYPE) {
				mapObject.put(
					'selectedValue',
					taskParameterValueMap.get(taskParameterTemplate.Id).IntegerValue__c != null
						? taskParameterValueMap.get(taskParameterTemplate.Id).IntegerValue__c
						: 0
				);
			}
			if (taskParameterTemplate.DataType__c == 'checkbox') {
				mapObject.put(
					'selectedValue',
					taskParameterValueMap.get(taskParameterTemplate.Id).BooleanValue__c
				);
			}
			if (taskParameterTemplate.DataType__c == 'Integer Tiers') {
				mapObject.put(
					'selectedValue',
					taskParameterValueMap.get(taskParameterTemplate.Id).IntegerValue__c
				);
			}
			mapObject.put('TaskName', taskParameterValueMap.get(taskParameterTemplate.Id).TaskId__r.Name);
			mapObject.put(
				'ActivityName',
				taskParameterValueMap.get(taskParameterTemplate.Id).TaskId__r.ActivityId__r.Name
			);
			mapObject.put(
				'ActivityGroupName',
				taskParameterValueMap.get(taskParameterTemplate.Id)
					.TaskId__r.ActivityId__r.ActivityGroupId__r.Name
			);
		}
	}
}
