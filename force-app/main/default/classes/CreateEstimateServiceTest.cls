@IsTest
private class CreateEstimateServiceTest extends EstimatorTestsBase {
	@testSetup
	static void setup() {
		EstimateTemplate__c estimateTemplate = newEstimateTemplate();
		List<ActivityGroupTemplate__c> activityGroupTemplates = createActivityGroupTemplates(
			estimateTemplate.Id
		);
		List<ActivityTemplate__c> activityTemplates = createActivityTemplates(activityGroupTemplates);
		List<Product2> resourceRoles = createResourceRoles();
		createTaskTemplates(activityTemplates, resourceRoles);
	}

	@IsTest
	static void createEstimateFromEstimateTemplateTest() {
		EstimateTemplate__c estimateTemplate = [
			SELECT
				Id,
				Name,
				Description__c,
				Guidance__c,
				IsActive__c,
				RateCardId__c,
				ProductId__c,
				ServiceId__c,
				ServiceId__r.Name
			FROM EstimateTemplate__c
			WHERE Name = 'CLM Development Estimate'
		];

		Test.startTest();
		Estimate__c estimate = Estimate.newSO(estimateTemplate);
		Test.stopTest();

		System.assertEquals(estimateTemplate.Name, estimate.Name, 'Estimate not configured properly');
		System.assertEquals(
			estimateTemplate.Description__c,
			estimate.Description__c,
			'Estimate not configured properly'
		);
	}

	@IsTest
	static void getActivityGroupsFromTemplateTest() {
		EstimateTemplate__c estimateTemplate = [
			SELECT
				Id,
				Name,
				Description__c,
				Guidance__c,
				IsActive__c,
				RateCardId__c,
				ProductId__c,
				ServiceId__c,
				ServiceId__r.Name,
				(
					SELECT Id, Name, Description__c, Guidance__c, Sequence__c
					FROM ActivityGroups__r
					WHERE IsActive__c = TRUE
				)
			FROM EstimateTemplate__c
			WHERE Name = 'CLM Development Estimate'
		];

		Test.startTest();
		Estimate__c estimate = Estimate.newSO(estimateTemplate);
		CRUDUtility.insertRecords(estimate);
		Map<Id, ActivityGroup__c> activitiesByTemplateId = CreateEstimateService.createActivityGroups(
			estimateTemplate.ActivityGroups__r,
			estimate.Id
		);
		Test.stopTest();

		System.assertEquals(
			estimateTemplate.ActivityGroups__r.size(),
			activitiesByTemplateId.values().size(),
			'Activities not configured properly'
		);
	}
}
