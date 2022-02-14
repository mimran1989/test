/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class Task {
	public static Task__c newSO(TaskTemplate__c templateSO) {
		Task__c taskSO = new Task__c();
		taskSO.Name = templateSO.Name;
		taskSO.Description__c = templateSO.Description__c;
		taskSO.Guidance__c = templateSO.Guidance__c;
		taskSO.Sequence__c = templateSO.Sequence__c;
		taskSO.IsActive__c = true;
		taskSO.ResourceRoleId__c = templateSO.ResourceRoleId__c;
		taskSO.TemplateId__c = templateSO.Id;
		return taskSO;
	}
}
