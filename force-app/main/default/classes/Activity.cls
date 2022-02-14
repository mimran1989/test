/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class Activity {
	public static Activity__c newSO(ActivityTemplate__c templateSO) {
		Activity__c activitySO = new Activity__c();
		activitySO.Name = templateSO.Name;
		activitySO.Description__c = templateSO.Description__c;
		activitySO.Guidance__c = templateSO.Guidance__c;
		activitySO.Sequence__c = templateSO.Sequence__c;
		activitySO.IsActive__c = true;
		return activitySO;
	}
}
