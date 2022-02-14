@IsTest
private class CreateEstimateControllerTest extends EstimatorTestsBase {
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
	static void createEstimateFromTemplateTest() {
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
		Id estimateId = CreateEstimateController.createEstimateFromTemplate(estimateTemplate.Id);
		Test.stopTest();

		System.assertNotEquals(null, estimateId, 'Estimate not created from Estimate Template');
	}
}
