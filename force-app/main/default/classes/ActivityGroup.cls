/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class ActivityGroup {
	public static ActivityGroup__c newSO(ActivityGroupTemplate__c templateSO) {
		ActivityGroup__c groupSO = new ActivityGroup__c();
		groupSO.Name = templateSO.Name;
		groupSO.Description__c = templateSO.Description__c;
		groupSO.Guidance__c = templateSO.Guidance__c;
		groupSO.Sequence__c = templateSO.Sequence__c;
		groupSO.IsActive__c = true;
		return groupSO;
	}
}
