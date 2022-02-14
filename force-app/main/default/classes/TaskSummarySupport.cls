/**
 *  Provus Services Quoting
 *  TaskSummarySupport
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class TaskSummarySupport {
	private static Map<Schema.SObjectType, Schema.SObjectField> childSummaryFields;
	private static Map<Schema.SObjectType, String> childSummaryFieldNames;

	private static String getSummaryFieldName(Schema.sObjectType sObjectType) {
		if (childSummaryFieldNames == null) {
			childSummaryFieldNames = new Map<Schema.SObjectType, String>();
		}

		String childSummaryFieldName = childSummaryFieldNames.get(sObjectType);
		if (childSummaryFieldName == null) {
			childSummaryFieldName = getSummaryField(sObjectType).getDescribe().getName();
			childSummaryFieldNames.put(sObjectType, childSummaryFieldName);
		}

		return childSummaryFieldName;
	}

	private static Schema.SObjectField getSummaryField(Schema.sObjectType sObjectType) {
		if (childSummaryFields == null) {
			childSummaryFields = new Map<Schema.SObjectType, Schema.SObjectField>();
			List<Schema.ChildRelationship> childRelationShips = TaskSummary__c.sObjectType.getDescribe()
				.getChildRelationships();
			for (Schema.ChildRelationship childRelationShip : childRelationShips) {
				childSummaryFields.put(childRelationShip.getChildSObject(), childRelationShip.getField());
			}
		}

		return childSummaryFields.get(sObjectType);
	}

	public static Map<Id, TaskSummary__c> createTaskSummaries(Map<Id, SObject> parentSObjectsById) {
		Map<Id, TaskSummary__c> summariesByParentId = new Map<Id, TaskSummary__c>();

		for (SObject parentSObject : parentSObjectsById.values()) {
			String foreignKey = getSummaryFieldName(parentSObject.getSObjectType());
			if (parentSObject.get(foreignKey) == null) {
				summariesByParentId.put(parentSObject.Id, new TaskSummary__c());
			}
		}

		CRUDUtility.insertRecords(summariesByParentId.values());

		for (Id parentId : parentSObjectsById.keySet()) {
			TaskSummary__c summaryForParent = summariesByParentId.get(parentId);
			SObject parentSObject = parentSObjectsById.get(parentId);

			if (summaryForParent != null) {
				String foreignKey = getSummaryFieldName(parentSObject.getSObjectType());
				parentSObject.put(foreignKey, summaryForParent.Id);
			}
		}

		CRUDUtility.updateRecords(parentSObjectsById.values());

		return summariesByParentId;
	}
}
