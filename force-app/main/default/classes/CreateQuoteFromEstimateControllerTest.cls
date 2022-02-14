@IsTest
private class CreateQuoteFromEstimateControllerTest extends EstimatorTestsBase {
	@TestSetup
	static void setup() {
		List<Product2> resourceRoles = createResourceRoles();
		RateCard__c rateCard = newRateCardWithItems(resourceRoles);
		EstimateTemplate__c estimateTemplate = newEstimateTemplate();
		estimateTemplate.RateCardId__c = rateCard.Id;
		update estimateTemplate;
		List<ActivityGroupTemplate__c> activityGroupTemplates = createActivityGroupTemplates(
			estimateTemplate.Id
		);
		List<ActivityTemplate__c> activityTemplates = createActivityTemplates(activityGroupTemplates);

		createTaskTemplates(activityTemplates, resourceRoles);
		CreateEstimateController.createEstimateFromTemplate(estimateTemplate.Id);
	}

	@IsTest
	static void verifyEstimateDetails() {
		Estimate__c estimateObj = [
			SELECT Id, Name, Description__c, AccountId__c
			FROM Estimate__c
			WHERE Name = 'CLM Development Estimate'
		];

		Test.startTest();
		QuoteDO quoteResult = CreateQuoteFromEstimateController.getEstimateDetails(estimateObj.Id);
		Test.stopTest();

		System.assertEquals(
			estimateObj.AccountId__c,
			quoteResult.accountId,
			'Estimate details not fetched properly'
		);
		System.assertEquals(
			estimateObj.Description__c,
			quoteResult.description,
			'Estimate Description is not matching'
		);
	}

	@IsTest
	static void verifyServiceEndDate() {
		Estimate__c estimateObj = [SELECT Id FROM Estimate__c WHERE Name = 'CLM Development Estimate'];

		EndDateArgs endDateArgs = new EndDateArgs();
		endDateArgs.serviceStartDate = System.today();
		endDateArgs.timePeriods = 'Months';
		endDateArgs.calendarAlignment = 'Calendar';

		Test.startTest();
		Date serviceEndDate = CreateQuoteFromEstimateController.getServiceEndDate(
			estimateObj.Id,
			endDateArgs
		);
		Test.stopTest();

		System.assertNotEquals(serviceEndDate, null, 'ServiceEndDate is NULL');
	}

	@IsTest
	static void verifyResourceRoleData() {
		Estimate__c estimateObj = [
			SELECT Id, RateCardId__c
			FROM Estimate__c
			WHERE Name = 'CLM Development Estimate'
		];

		Test.startTest();
		Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> resourceRoleStruct = CreateQuoteFromEstimateController.getResourceRoleData(
			estimateObj.Id,
			estimateObj.RateCardId__c
		);
		Test.stopTest();

		System.assertNotEquals(resourceRoleStruct, null, 'Resource Role data is null');
		System.assertEquals(
			resourceRoleStruct.values().size(),
			2,
			'Resource Role Structure is doesn\'t matched'
		);
	}

	@IsTest
	static void verifyQuoteCreation() {
		Estimate__c estimateObj = [
			SELECT Id, RateCardId__c
			FROM Estimate__c
			WHERE Name = 'CLM Development Estimate'
		];
		Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> resourceRoleByName = CreateQuoteFromEstimateController.getResourceRoleData(
			estimateObj.Id,
			estimateObj.RateCardId__c
		);
		QuoteDO quoteResult = CreateQuoteFromEstimateController.getEstimateDetails(estimateObj.Id);

		EndDateArgs endDateArgs = new EndDateArgs();
		endDateArgs.serviceStartDate = System.today();
		endDateArgs.timePeriods = 'Months';
		endDateArgs.calendarAlignment = 'Calendar';

		quoteResult.serviceStartDate = System.today();
		quoteResult.serviceEndDate = System.today().addYears(1);
		quoteResult.timePeriod = 'Months';
		quoteResult.timePeriodsGroupMethod = 'Year';
		quoteResult.timePeriodsAlignment = 'Calendar';

		Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences> rolePrefs = new Map<Id, CreateQuoteFromEstimateService.ResourceRolePreferences>();
		for (String roleName : resourceRoleByName.keySet()) {
			CreateQuoteFromEstimateService.ResourceRolePreferences rolePref = new CreateQuoteFromEstimateService.ResourceRolePreferences();
			rolePref.role = roleName;
			rolePref.location = 'India/Bangalore';
			rolePref.skillLevel = 'L1';
			rolePrefs.put(roleName, rolePref);
		}

		Test.startTest();
		Id quoteId = CreateQuoteFromEstimateController.createQuote(
			JSON.serialize(quoteResult),
			JSON.serialize(rolePrefs)
		);
		Test.stopTest();

		System.assertNotEquals(resourceRoleByName, null, 'ResoureRoleStruct is empty');
		System.assertNotEquals(quoteId, null, 'Quote is not genrated properly');
	}
}
