/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class EstimateTreeTaskSupport {
	public static Map<String, Object> getTaskDetails(String taskId) {
		Map<String, Object> finalMp = new Map<String, Object>();
		List<Object> dataFields = new List<Object>();
		List<TaskParameterValue__c> taskParameterValues = [
			SELECT
				Id,
				TemplateId__c,
				BooleanValue__c,
				IntegerValue__c,
				TextValue__c,
				TaskId__r.Name,
				TaskId__r.ActivityId__r.Name,
				TaskId__r.ActivityId__r.ActivityGroupId__r.Name
			FROM TaskParameterValue__c
			WHERE TaskId__c = :taskId
			WITH SECURITY_ENFORCED
		];
		Map<Id, TaskParameterValue__c> taskParameterValueMap = new Map<Id, TaskParameterValue__c>();
		if (!taskParameterValues.isEmpty()) {
			taskParameterValueMap = (Map<Id, TaskParameterValue__c>) SystemUtility.keyByIdType(
				taskParameterValues,
				Schema.TaskParameterValue__c.TemplateId__c
			);
		}

		//Querying the taskparameters..it contains the field definition info
		for (TaskParameterTemplate__c taskParameterTemplate : [
			SELECT
				Id,
				TaskTemplateId__c,
				DataType__c,
				Name,
				Guidance__c,
				(
					SELECT Id, Name, Label__c, PerUnitDuration__c, FromValue__c, ToValue__c
					FROM ParameterValues__r
					ORDER BY Sequence__c ASC
				)
			FROM TaskParameterTemplate__c
			WHERE Id IN :taskParameterValueMap.keySet() AND IsActive__c = TRUE
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		]) {
			dataFields.add(createTaskParams(taskParameterTemplate, taskParameterValueMap));
		}
		//taskId
		finalMp.put('TaskDetails', taskDetails(taskId));
		finalMp.put('TaskParams', dataFields);
		return finalMp;
	}

	private static Map<String, Object> createTaskParams(
		TaskParameterTemplate__c taskParameterTemplate,
		Map<Id, TaskParameterValue__c> taskParameterValueMap
	) {
		Map<String, Object> mapObject = new Map<String, Object>();
		mapObject.put(EstimatorConstants.DATA_TYPE, taskParameterTemplate.DataType__c);
		EstimateTreeSupport.processObject(taskParameterTemplate, mapObject, taskParameterValueMap);
		mapObject.put('FieldId', taskParameterTemplate.Id);
		mapObject.put('FieldName', taskParameterTemplate.Name);
		mapObject.put('Description', taskParameterTemplate.Guidance__c);
		mapObject.put(
			'PicklistValue',
			taskParameterValueMap.get(taskParameterTemplate.Id).TextValue__c
		);
		mapObject.put(
			'isIntegerTiers',
			taskParameterTemplate.DataType__c == 'Integer Tiers' ? true : false
		);
		mapObject.put('isNumberField', taskParameterTemplate.DataType__c == 'Integer' ? true : false);
		mapObject.put('isPickList', taskParameterTemplate.DataType__c == 'Picklist' ? true : false);
		mapObject.put('isBoolean', taskParameterTemplate.DataType__c == 'Checkbox' ? true : false);
		if (taskParameterTemplate.ParameterValues__r != null) {
			processTemplateValues(
				taskParameterTemplate.ParameterValues__r,
				mapObject,
				taskParameterTemplate
			);
		}
		return mapObject;
	}

	@TestVisible
	private static Map<String, Object> taskDetails(String taskId) {
		Task__c tk = [
			SELECT Id, Path__c, EstimateId__c
			FROM Task__c
			WHERE Id = :taskId
			WITH SECURITY_ENFORCED
		];
		Integer agSeq = Integer.valueof(tk.Path__c.split('\\.')[0]);
		Integer prvSeq = agSeq - 2;
		Integer nxtSeq = agSeq + 2;
		Map<Id, Task__c> activityTasks = new Map<Id, Task__c>(
			[
				SELECT
					Id,
					Path__c,
					Name,
					TemplateId__c,
					ActivityId__r.Name,
					ActivityId__r.ActivityGroupId__r.Name,
					IsNotApplicable__c,
					CalculatedDuration__c,
					LevelAdjustment__c,
					EstimatedDuration__c,
					ResourceRoleId__r.Name,
					AdjustmentReason__c
				FROM Task__c
				WHERE
					EstimateId__c = :tk.EstimateId__c
					AND ActivityId__r.ActivityGroupId__r.Sequence__c >= :prvSeq
					AND ActivityId__r.ActivityGroupId__r.Sequence__c <= :nxtSeq
				WITH SECURITY_ENFORCED
				ORDER BY Path__c ASC
			]
		);
		List<Id> tskIIds = new List<Id>(activityTasks.keySet());
		Map<String, Object> mpTask = new Map<String, Object>();
		Integer indx = tskIIds.indexOf(Id.valueOf(taskId));
		if (indx == 0) {
			mpTask = EstimateTreeSupport.taskDetailObject(activityTasks.get(taskId));
			mpTask.put('beforeExists', false);
			mpTask.put('afterExists', tskIIds.size() == 1 ? false : true);
			mpTask.put('beforeTaskId', '');
			mpTask.put('afterTaskId', tskIIds.size() == 1 ? '' : tskIIds[indx + 1]);
		} else if (indx == tskIIds.size() - 1) {
			mpTask = EstimateTreeSupport.taskDetailObject(activityTasks.get(taskId));
			mpTask.put('beforeExists', true);
			mpTask.put('afterExists', false);
			mpTask.put('beforeTaskId', tskIIds[indx - 1]);
			mpTask.put('afterTaskId', '');
		} else {
			mpTask = EstimateTreeSupport.taskDetailObject(activityTasks.get(taskId));
			mpTask.put('beforeExists', true);
			mpTask.put('afterExists', true);
			mpTask.put('beforeTaskId', tskIIds[indx - 1]);
			mpTask.put('afterTaskId', tskIIds[indx + 1]);
		}
		return mpTask;
	}

	private static void processTemplateValues(
		List<TaskParameterValueTemplate__c> taskParamRecords,
		Map<String, Object> mps,
		TaskParameterTemplate__c tp
	) {
		List<Object> tpaLst = new List<Object>();
		Map<String, String> picklistLabelValues = new Map<String, String>();
		for (TaskParameterValueTemplate__c tpv : taskParamRecords) {
			if (tp.DataType__c == 'Picklist') {
				Map<String, String> mpval = new Map<String, String>();
				mpval.put('label', tpv.Label__c);
				mpval.put('value', String.valueOf(tpv.PerUnitDuration__c));
				tpaLst.add(mpval);
				picklistLabelValues.put(tpv.Label__c, String.valueOf(tpv.PerUnitDuration__c));
			} else if (tp.DataType__c == 'Integer' || tp.DataType__c == 'Checkbox') {
				mps.put('Multiplier', tpv.PerUnitDuration__c);
			} else if (tp.DataType__c == 'Integer Tiers') {
				mps.put('IntegerTiers', tp.ParameterValues__r);
			}
		}
		if (tp.DataType__c == 'Picklist') {
			mps.put(
				'selectedValue',
				picklistLabelValues.containsKey(String.valueOf(mps.get('PicklistValue')))
					? picklistLabelValues.get(String.valueOf(mps.get('PicklistValue')))
					: ''
			);
		}
		mps.put('PicklistValues', tpaLst);
	}
}
