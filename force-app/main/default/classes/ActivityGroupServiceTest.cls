/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
@IsTest
private class ActivityGroupServiceTest {
	@IsTest
	static void shouldReturnApplicableGroups() {
		Estimate__c estimateSO = new Estimate__c();
		CRUDUtility.insertRecords(estimateSO);

		ActivityGroup__c groupSO1 = new ActivityGroup__c(EstimateId__c = estimateSO.Id);
		ActivityGroup__c groupSO2 = new ActivityGroup__c(
			EstimateId__c = estimateSO.Id,
			IsNotApplicable__c = true
		);
		CRUDUtility.insertRecords(new List<ActivityGroup__c>{ groupSO1, groupSO2 });

		Test.startTest();
		List<ActivityGroup__c> groups = ActivityGroupService.getApplicableGroups(estimateSO.Id);
		System.assertEquals(1, groups.size(), 'should return the 1 applicable group');
		Test.stopTest();
	}
}
