/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
@IsTest
private class EstimateTreeSummarySupportTest extends TestBase {
	static TaskSummary__c newTaskSummary() {
		TaskSummary__c newSummary = new TaskSummary__c();
		CRUDUtility.insertRecords(newSummary);

		return newSummary;
	}

	@IsTest
	static void shouldCreateLineageFromActivity() {
		TaskSummary__c summarySO = newTaskSummary();
		Estimate__c estimateSO = new Estimate__c(SummaryId__c = summarySO.Id);
		CRUDUtility.insertRecords(estimateSO);
		ActivityGroup__c groupSO = new ActivityGroup__c(
			EstimateId__c = estimateSO.Id,
			SummaryId__c = summarySO.Id
		);
		CRUDUtility.insertRecords(groupSO);
		Activity__c activitySO = new Activity__c(
			EstimateId__c = estimateSO.Id,
			ActivityGroupId__c = groupSO.Id,
			SummaryId__c = summarySO.Id
		);
		CRUDUtility.insertRecords(activitySO);

		Id productTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Product');
		Product2 productSO = newProduct('Test Product', productTypeId);

		Test.startTest();
		EstimateTreeSummarySupport.createRoleSummaryLineageForActivity(activitySO.Id, productSO.Id, 8);
		TaskRoleSummary__c activitySummarySO = [
			SELECT LevelAdjustment__c
			FROM TaskRoleSummary__c
			WHERE SummaryLevel__c = 'Activity'
		];
		System.assertEquals(
			3,
			EstimateTreeSummarySupport.getRoleSummaryLineageForActivity(activitySO.Id, productSO.Id)
				.size(),
			'should have 3 task role summaries (estimate, group, activity)'
		);
		System.assert(activitySummarySO.LevelAdjustment__c == 8, 'should persist the level adjustment');
		Test.stopTest();
	}

	@IsTest
	static void shouldCreateLineageFromActivityGroup() {
		TaskSummary__c summarySO = newTaskSummary();
		Estimate__c estimateSO = new Estimate__c(SummaryId__c = summarySO.Id);
		CRUDUtility.insertRecords(estimateSO);
		ActivityGroup__c groupSO = new ActivityGroup__c(
			EstimateId__c = estimateSO.Id,
			SummaryId__c = summarySO.Id
		);
		CRUDUtility.insertRecords(groupSO);

		Id productTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Product');
		Product2 productSO = newProduct('Test Product', productTypeId);

		Test.startTest();
		EstimateTreeSummarySupport.createRoleSummaryLineageForActivityGroup(
			groupSO.Id,
			productSO.Id,
			8
		);
		TaskRoleSummary__c groupSummarySO = [
			SELECT LevelAdjustment__c
			FROM TaskRoleSummary__c
			WHERE SummaryLevel__c = 'Activity Group'
		];
		System.assertEquals(
			2,
			EstimateTreeSummarySupport.getRoleSummaryLineageForActivityGroup(groupSO.Id, productSO.Id)
				.size(),
			'should have 2 task role summaries (estimate, group)'
		);
		System.assert(groupSummarySO.LevelAdjustment__c == 8, 'should persist the level adjustment');
		Test.stopTest();
	}
}
