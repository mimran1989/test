/**
 *  Provus Services Quoting
 *  ProjectPhaseDOTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class ProjectPhaseDOTest extends ProjectPhaseTestsBase {
	@IsTest
	static void itShouldConstructDOFromSO() {
		ProjectPhase__c newPhaseSO = newPhase();
		newPhaseSO.Name = 'Test Phase';
		newPhaseSO.Sequence__c = 2;
		newPhaseSO.Description__c = 'Testing the description';
		newPhaseSO.StartDate__c = Date.Today();
		newPhaseSO.EndDate__c = Date.Today() + 1;
		CRUDUtility.updateRecords(newPhaseSO);

		QuotePeriod__c testPeriod = newQuotePeriod(newPhaseSO.QuoteId__c);
		testPeriod.ProjectPhaseId__c = newPhaseSO.Id;
		CRUDUtility.updateRecords(testPeriod);

		ProjectPhase__c testPhaseSO = ProjectPhaseFactory.getProjectPhasesForQuote(
			newPhaseSO.QuoteId__c
		)[0];

		Test.startTest();
		ProjectPhaseDO testPhaseDO = (ProjectPhaseDO) ProjectPhaseDO.newDO(testPhaseSO);
		System.assertEquals(testPhaseDO.id, testPhaseSO.Id, 'Id should be copied to the DO');
		System.assertEquals(testPhaseDO.name, testPhaseSO.Name, 'Name should be copied to the DO');
		System.assertEquals(
			testPhaseDO.quoteId,
			testPhaseSO.QuoteId__c,
			'Quote Id should be copied to the DO'
		);
		System.assertEquals(
			testPhaseDO.sequence,
			testPhaseSO.Sequence__c,
			'Sequence should be copied to the DO'
		);
		System.assertEquals(
			testPhaseDO.description,
			testPhaseSO.Description__c,
			'Description should be copied to the DO'
		);
		System.assertEquals(
			testPhaseDO.startDate,
			testPhaseSO.StartDate__c,
			'Start Date should be copied to the DO'
		);
		System.assertEquals(
			testPhaseDO.endDate,
			testPhaseSO.EndDate__c,
			'End Date should be copied to the DO'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldConstructSOFromDO() {
		ProjectPhaseDO newDO = newPhaseDO();
		newDO.name = 'Test Phase';
		newDO.sequence = 2;
		newDO.description = 'Testing the description';
		newDO.startDate = Date.Today();
		newDO.endDate = Date.Today() + 1;

		Test.startTest();
		ProjectPhase__c testPhaseSO = newDO.newSO();
		System.assertEquals(testPhaseSO.Name, newDO.name, 'Name should be copied to the DO');
		System.assertEquals(
			testPhaseSO.QuoteId__c,
			newDO.quoteId,
			'Quote Id should be copied to the DO'
		);
		System.assertEquals(
			testPhaseSO.Sequence__c,
			newDO.sequence,
			'Sequence should be copied to the DO'
		);
		System.assertEquals(
			testPhaseSO.Description__c,
			newDO.description,
			'Description should be copied to the DO'
		);
		System.assertEquals(
			testPhaseSO.StartDate__c,
			newDO.startDate,
			'Start Date should be copied to the DO'
		);
		System.assertEquals(
			testPhaseSO.EndDate__c,
			newDO.endDate,
			'End Date should be copied to the DO'
		);
		Test.stopTest();
	}
}
