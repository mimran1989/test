@IsTest
private class EstimateTemplateCreatorTest {
	@testSetup
	static void setup() {
		EstimateTemplate__c estimateTemplate = TestDataFactory.createEstimateTemplate(
			'EstimateTemplate',
			true,
			null
		);
		CRUDUtility.insertRecords(estimateTemplate);

		ActivityGroupTemplate__c activityGroupTemplate = TestDataFactory.createActivityGroupTemplate(
			'activityGroup1',
			true,
			estimateTemplate.Id
		);
		CRUDUtility.insertRecords(activityGroupTemplate);

		ActivityTemplate__c activityTemplate = TestDataFactory.createActivityTemplate(
			'activityTemplate1',
			true,
			activityGroupTemplate.Id
		);
		CRUDUtility.insertRecords(activityTemplate);

		TaskTemplate__c taskTemplate = TestDataFactory.createTaskTemplate(
			'task1',
			true,
			activityTemplate.Id
		);
		CRUDUtility.insertRecords(taskTemplate);

		TaskParameterTemplate__c taskParamTemplate = TestDataFactory.createTaskParamTemplate(
			'Taskparamtemp',
			true,
			taskTemplate.Id
		);
		CRUDUtility.insertRecords(taskParamTemplate);

		TaskParameterValueTemplate__c taskParamValueTemplate = TestDataFactory.createTaskParamValueTemplate(
			taskParamTemplate.Id
		);
		CRUDUtility.insertRecords(taskParamValueTemplate);
	}

	@isTest
	static void testMethod1() {
		Id estimateId = [SELECT Id FROM EstimateTemplate__c LIMIT 1].Id;

		List<ActivityGroupTemplate__c> activityGroupData = (list<ActivityGroupTemplate__c>) EstimateTemplateCreator.getActivityGroups(
			estimateId
		);
		EstimateTemplateCreator.getTemplateStructure(estimateId);
		EstimateTemplateCreator.getActivities([SELECT Id FROM ActivityGroupTemplate__c LIMIT 1].Id);
		EstimateTemplateCreator.getTasks([SELECT Id FROM ActivityTemplate__c LIMIT 1].Id);
		EstimateTemplateCreator.getTaskParams([SELECT Id FROM TaskTemplate__c LIMIT 1].Id);
		EstimateTemplateCreator.getTaskParamValues(
			[SELECT Id FROM TaskParameterTemplate__c LIMIT 1]
			.Id
		);
		EstimateTemplateCreator.deleteRecords(
			new List<Id>{ [SELECT Id FROM TaskParameterValueTemplate__c LIMIT 1].Id }
		);
		EstimateTemplateCreator.saveRecords(
			JSON.serialize([SELECT Id FROM ActivityGroupTemplate__c]),
			'Activity Group Templates'
		);
		EstimateTemplateCreator.saveRecords(
			JSON.serialize([SELECT Id FROM ActivityTemplate__c]),
			'Activity Templates'
		);
		EstimateTemplateCreator.saveRecords(
			JSON.serialize([SELECT Id FROM TaskTemplate__c]),
			'Task Templates'
		);
		EstimateTemplateCreator.saveRecords(
			JSON.serialize([SELECT Id FROM TaskParameterTemplate__c]),
			'Task Parameters'
		);
		EstimateTemplateCreator.upsertTaskParamsValues(
			[SELECT Id FROM TaskParameterTemplate__c LIMIT 1],
			[SELECT Id FROM TaskParameterValueTemplate__c]
		);
		system.assertEquals(
			'activityGroup1',
			activityGroupData[0].Name,
			'Activity Group Name is activityGroup1'
		);
	}
}
