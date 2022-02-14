/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class CreateQuoteFromEstimateServiceTest extends EstimatorTestsBase {
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
	static void itShouldAssignQuoteItems() {
		Test.startTest();
		Quote__c quoteSO = createQuoteFromEstimate('Months');
		List<QuoteItem__c> quoteItems = [
			SELECT Id, ProductId__r.Name
			FROM QuoteItem__c
			WHERE QuoteId__c = :quoteSO.Id
			ORDER BY Sequence__c
		];
		System.assert(!quoteItems.isEmpty(), 'quote items should exist for quote');
		System.assert(
			quoteItems[0].ProductId__r.Name == 'Software Engineer' &&
			quoteItems[1].ProductId__r.Name == 'Project Manager',
			'quote item creation should follow task order'
		);
		Test.stopTest();
	}

	static Quote__c createQuoteFromEstimate(String timePeriod) {
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

		quoteResult.serviceStartDate = System.today();
		quoteResult.serviceEndDate = System.today().addYears(1);
		quoteResult.timePeriod = timePeriod;
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

		Quote__c quoteSO = QuoteDO.getQuoteFromData(quoteResult);
		quoteSO.QuoteDate__c = System.today();
		quoteSO.Version__c = 1;
		quoteSO.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
		CRUDUtility.insertRecords(quoteSO);
		List<TaskRoleSummary__c> roleSummaries = new List<TaskRoleSummary__c>();
		for (TaskRoleSummary__c roleSummary : [
			SELECT Id
			FROM TaskRoleSummary__c
			WHERE SummaryLevel__c = 'Activity Group'
		]) {
			roleSummary.LevelAdjustment__c = 1;
			roleSummaries.add(roleSummary);
		}

		CRUDUtility.updateRecords(roleSummaries);
		CreateQuoteFromEstimateService.convertEntitiesFromEstimate(quoteSO, rolePrefs);
		return quoteSO;
	}

	@IsTest
	static void shouldGetResourceRoles() {
		Test.startTest();
		Quote__c quoteSO = createQuoteFromEstimate('Months');
		Map<String, CreateQuoteFromEstimateService.ResourceRoleDetail> resourceRolesByProductId = CreateQuoteFromEstimateService.getResourceRoles(
			quoteSO.EstimateId__c,
			quoteSO.RateCardId__c
		);
		System.assert(resourceRolesByProductId.size() > 0, 'should have resource roles');
		for (
			CreateQuoteFromEstimateService.ResourceRoleDetail detail : resourceRolesByProductId.values()
		) {
			System.assert(detail.sequence != null, 'should have a sequence');
		}
		Test.stopTest();
	}

	@IsTest
	static void itShouldSetQuoteItemCellsForMonths() {
		Test.startTest();
		Quote__c quoteSO = createQuoteFromEstimate('Months');
		List<QuoteItem__c> quoteItems = [
			SELECT Id, (SELECT C001__c FROM QuoteItemCells__r)
			FROM QuoteItem__c
			WHERE QuoteId__c = :quoteSO.Id
		];
		System.assert(
			quoteItems[0].QuoteItemCells__r[0].C001__c > 0,
			'quote item cell should be non-zero'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldSetQuoteItemCellsForDays() {
		Test.startTest();
		Quote__c quoteSO = createQuoteFromEstimate('Days');
		List<QuoteItem__c> quoteItems = [
			SELECT Id, (SELECT C001__c FROM QuoteItemCells__r)
			FROM QuoteItem__c
			WHERE QuoteId__c = :quoteSO.Id
		];
		System.assert(
			quoteItems[0].QuoteItemCells__r[0].C001__c > 0,
			'quote item cell should be non-zero'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldSetQuoteItemCellsForWeeks() {
		Test.startTest();
		Quote__c quoteSO = createQuoteFromEstimate('Weeks');
		List<QuoteItem__c> quoteItems = [
			SELECT Id, (SELECT C001__c FROM QuoteItemCells__r)
			FROM QuoteItem__c
			WHERE QuoteId__c = :quoteSO.Id
		];
		System.assert(
			quoteItems[0].QuoteItemCells__r[0].C001__c > 0,
			'quote item cell should be non-zero'
		);
		Test.stopTest();
	}
}
