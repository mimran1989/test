/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class EstimateTemplateCreator {
	@Auraenabled
	public static object getActivityGroups(String estimateTemplateId) {
		return [
			SELECT Id, IsActive__c, Sequence__c, Guidance__c, Name, EstimateTemplateId__c
			FROM ActivityGroupTemplate__c
			WHERE EstimateTemplateId__c = :estimateTemplateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}

	@Auraenabled
	public static object getActivities(String activityGroupTemplateId) {
		return [
			SELECT IsActive__c, Sequence__c, Guidance__c, Name, ActivityGroupTemplateId__c
			FROM ActivityTemplate__c
			WHERE ActivityGroupTemplateId__c = :activityGroupTemplateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}

	@Auraenabled
	public static object getTasks(String activityTemplateId) {
		return [
			SELECT IsActive__c, Sequence__c, Guidance__c, Name, ActivityTemplateId__c, ResourceRoleId__c
			FROM TaskTemplate__c
			WHERE ActivityTemplateId__c = :activityTemplateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}

	@Auraenabled
	public static object getTaskParams(String taskTemplateId) {
		return [
			SELECT
				IsActive__c,
				Name,
				Sequence__c,
				DataType__c,
				Guidance__c,
				Description__c,
				TaskTemplateId__c
			FROM TaskParameterTemplate__c
			WHERE TaskTemplateId__c = :taskTemplateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}

	@Auraenabled
	public static object getTaskParamValues(String taskParamsTemplateId) {
		return [
			SELECT
				Label__c,
				PerUnitDuration__c,
				FromValue__c,
				ToValue__c,
				Sequence__c,
				TaskParameterTemplateId__r.Datatype__c
			FROM TaskParameterValueTemplate__c
			WHERE TaskParameterTemplateId__c = :taskParamsTemplateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
	}

	@Auraenabled
	public static String upsertTaskParamsValues(
		TaskParameterTemplate__c taskParamTemplateRecord,
		List<TaskParameterValueTemplate__c> taskParamValues
	) {
		if (string.valueof(taskParamTemplateRecord.Id).startsWith(EstimatorConstants.RECORD)) {
			taskParamTemplateRecord.Id = null;
		}
		upsert taskParamTemplateRecord;
		for (TaskParameterValueTemplate__c tpVt : taskParamValues) {
			if (string.valueof(tpVt.Id).startsWith(EstimatorConstants.RECORD)) {
				tpVt.Id = null;
			}
			tpVt.TaskParameterTemplateId__c = taskParamTemplateRecord.Id;
		}
		CRUDUtility.upsertRecords(taskParamValues);
		return 'Success';
	}

	@Auraenabled
	public static void deleteRecords(List<Id> removeRecordIds) {
		List<sObject> records = new List<sObject>();
		for (Id removeRecordId : removeRecordIds) {
			records.add(removeRecordId.getSobjectType().newSobject(removeRecordId));
		}
		CRUDUtility.deleteRecords(records);
	}

	@Auraenabled
	public static String saveRecords(string recordString, string typeOf) {
		if (typeOf == EstimatorConstants.ACTIVITYGROUP_TEMPLATES) {
			List<ActivityGroupTemplate__c> ags = (List<ActivityGroupTemplate__c>) JSON.deserialize(
				recordString,
				List<ActivityGroupTemplate__c>.class
			);
			CRUDUtility.upsertRecords(ags);
		} else if (typeOf == EstimatorConstants.ACTIVITY_TEMPLATES) {
			List<ActivityTemplate__c> activityTemplates = (List<ActivityTemplate__c>) JSON.deserialize(
				recordString,
				List<ActivityTemplate__c>.class
			);
			CRUDUtility.upsertRecords(activityTemplates);
		} else if (typeOf == EstimatorConstants.TASK_TEMPLATES) {
			List<TaskTemplate__c> taskTemplates = (List<TaskTemplate__c>) JSON.deserialize(
				recordString,
				List<TaskTemplate__c>.class
			);
			CRUDUtility.upsertRecords(taskTemplates);
		} else if (typeOf == EstimatorConstants.TASK_PARAMETERS) {
			List<TaskParameterTemplate__c> taskParameters = (List<TaskParameterTemplate__c>) JSON.deserialize(
				recordString,
				List<TaskParameterTemplate__c>.class
			);
			CRUDUtility.upsertRecords(taskParameters);
		}
		return 'Success';
	}

	@AuraEnabled(cacheable=true)
	public static object getTemplateStructure(String estimateId) {
		List<ActivityGroupTemplate__c> activityGroupTemplateList = [
			SELECT Id, IsActive__c, Sequence__c, Name
			FROM ActivityGroupTemplate__c
			WHERE EstimateTemplateId__c = :estimateId
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		];
		List<ActivityTemplate__c> activityTemplates = [
			SELECT
				Id,
				Name,
				ActivityGroupTemplateId__c,
				Path__c,
				(SELECT Id, Name, Path__c, ResourceRoleId__r.Name FROM Tasks__r ORDER BY Path__c ASC)
			FROM ActivityTemplate__c
			WHERE ActivityGroupTemplateId__c IN :activityGroupTemplateList
			WITH SECURITY_ENFORCED
			ORDER BY Path__c ASC
		];
		map<Id, List<ActivityTemplate__c>> activityTemplatesMP = new Map<Id, List<ActivityTemplate__c>>();
		for (ActivityTemplate__c at : activityTemplates) {
			if (!activityTemplatesMP.containskey(at.ActivityGroupTemplateId__c)) {
				activityTemplatesMP.put(at.ActivityGroupTemplateId__c, new List<ActivityTemplate__c>());
			}
			activityTemplatesMP.get(at.ActivityGroupTemplateId__c).add(at);
		}
		List<string> gridExpanedIds = new List<string>();
		List<Object> objlst = new List<Object>();
		for (ActivityGroupTemplate__c activityGroupTemplate : activityGroupTemplateList) {
			map<string, object> activityGroupTemplateMap = new Map<string, object>();
			activityGroupTemplateMap.put(EstimatorConstants.TYPE, 'ActivityGroupTemplate');
			activityGroupTemplateMap.put(
				'ActivityGroup',
				activityGroupTemplate.Sequence__c +
				' ' +
				activityGroupTemplate.Name
			);
			activityGroupTemplateMap.put('ActivityGroupName', activityGroupTemplate.Name);
			activityGroupTemplateMap.put('ActivityGroupId', activityGroupTemplate.Id);
			activityGroupTemplateMap.put(EstimatorConstants.ACTION_ICON, 'standard:work_type');
			activityGroupTemplateMap.put(EstimatorConstants.ICON_TYPE, 'standard:work_type_group');
			activityGroupTemplateMap.put(EstimatorConstants.ACTION_LABEL, 'Add/Edit Activities');
			gridExpanedIds.add(activityGroupTemplate.Id);
			if (activityTemplatesMP.containskey(activityGroupTemplate.Id)) {
				List<Object> activityTaskStructure = createActivityTemplates(
					activityTemplatesMP.get(activityGroupTemplate.Id),
					gridExpanedIds,
					activityGroupTemplate
				);
				activityGroupTemplateMap.put(EstimatorConstants.CHILDREN, activityTaskStructure);
			}
			objlst.add(activityGroupTemplateMap);
		}
		for (object obj : objlst) {
			map<string, object> mapRecord = (map<string, object>) obj;
			mapRecord.put('gridExpandedIds', gridExpanedIds);
			break;
		}
		return objlst;
	}

	@TestVisible
	private static List<Object> createActivityTemplates(
		List<ActivityTemplate__c> activityTemplateslist,
		List<String> gridExpanedIds,
		ActivityGroupTemplate__c activityGroupTemplate
	) {
		List<Object> activityTaskObject = new List<object>();
		for (ActivityTemplate__c activityTemplate : activityTemplateslist) {
			map<string, object> activityTemplateMap = new Map<string, object>();
			activityTemplateMap.put(EstimatorConstants.TYPE, 'ActivityTemplate');
			activityTemplateMap.put(
				'ActivityGroup',
				activityTemplate.Path__c +
				' ' +
				activityTemplate.Name
			);
			activityTemplateMap.put('ActivityGroupName', activityTemplate.Name);
			activityTemplateMap.put('ActivityGroupId', activityTemplate.Id);
			activityTemplateMap.put('ActionIcon', 'standard:task');
			activityTemplateMap.put('IconType', 'standard:work_type');
			activityTemplateMap.put('Actionlabel', 'Add/Edit Tasks');
			activityTemplateMap.put(
				EstimatorConstants.PARENT_LABEL,
				activityGroupTemplate.Name +
				'/ ' +
				activityTemplate.Name
			);
			gridExpanedIds.add(activityTemplate.Id);
			List<Object> taskObj = new List<object>();
			if (activityTemplate.Tasks__r != null) {
				for (TaskTemplate__c taskTemplate : activityTemplate.Tasks__r) {
					map<string, object> taskTemplateMap = new Map<string, object>();
					taskTemplateMap.put(EstimatorConstants.TYPE, 'TaskTemplate');
					taskTemplateMap.put('ActivityGroup', taskTemplate.Path__c + ' ' + taskTemplate.Name);
					taskTemplateMap.put('ActivityGroupName', taskTemplate.Name);
					taskTemplateMap.put('ActivityGroupId', taskTemplate.Id);
					taskTemplateMap.put('ResourceName', taskTemplate.ResourceRoleId__r.Name);
					taskTemplateMap.put('ActionIcon', 'action:edit');
					taskTemplateMap.put('IconType', 'standard:task');
					taskTemplateMap.put('Actionlabel', 'Add/Edit Task Parameters');
					taskTemplateMap.put(
						EstimatorConstants.PARENT_LABEL,
						activityGroupTemplate.Name +
						'/ ' +
						activityTemplate.Name +
						'/ ' +
						taskTemplate.Name
					);
					gridExpanedIds.add(taskTemplate.Id);
					taskObj.add(taskTemplateMap);
				}
				activityTemplateMap.put(EstimatorConstants.CHILDREN, taskObj);
			}
			activityTaskObject.add(activityTemplateMap);
		}
		return activityTaskObject;
	}
}
