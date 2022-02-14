/**
 *  Provus Services Quoting
 *  ProjectPhaseTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class ProjectPhaseTest extends ProjectPhaseTestsBase {
	@IsTest
	static void itShouldConstructProjectPhaseFromDO() {
		ProjectPhaseDO projectPhaseDO = new ProjectPhaseDO();

		Test.startTest();
		ProjectPhase projectPhase = new ProjectPhase(projectPhaseDO);
		System.assertNotEquals(projectPhase, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldConstructProjectPhaseFromSO() {
		ProjectPhase__c newPhaseSO = newPhase();
		ProjectPhase__c testPhaseSO = ProjectPhaseFactory.getProjectPhasesForQuote(
			newPhaseSO.QuoteId__c
		)[0];

		Test.startTest();
		ProjectPhase projectPhase = new ProjectPhase(testPhaseSO);
		System.assertNotEquals(projectPhase, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldInsertNewProjectPhase() {
		ProjectPhaseDO testPhaseDO = newPhaseDO();
		testPhaseDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		ProjectPhase testPhase = new ProjectPhase(testPhaseDO);

		Test.startTest();
		ProjectPhase.commitProjectPhases(new List<ProjectPhase>{ testPhase });
		ProjectPhase__c testPhaseSO = (ProjectPhase__c) testPhase.getSObject();

		System.assertNotEquals(null, testPhaseSO.Id, 'should create new named range');
		Test.stopTest();
	}

	@IsTest
	static void itShouldDeleteProjectPhase() {
		ProjectPhase__c newPhaseSO = newPhase();
		ProjectPhaseDO testPhaseDO = newPhaseDO(newPhaseSO.QuoteId__c);
		testPhaseDO.id = newPhaseSO.Id;
		testPhaseDO.operationType = BaseDTO.OPERATION_TYPE_DELETE;

		Test.startTest();
		ProjectPhase testPhase = new ProjectPhase(testPhaseDO);
		ProjectPhase.commitProjectPhases(new List<ProjectPhase>{ testPhase });
		ProjectPhase__c testPhaseSO = [
			SELECT IsDeleted
			FROM ProjectPhase__c
			WHERE Id = :newPhaseSO.Id
			ALL ROWS
		];

		System.assertEquals(true, testPhaseSO.IsDeleted, 'should delete phase');
		Test.stopTest();
	}

	@IsTest
	static void itShouldAssociateProjectPhaseIdToPeriods() {
		ProjectPhaseDO newPhaseDO = newPhaseDO();
		QuotePeriod__c newQuotePeriod = newQuotePeriod(newPhaseDO.quoteId);

		newPhaseDO.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		newPhaseDO.quotePeriodIdList = new List<Id>{ newQuotePeriod.Id };

		ProjectPhase testPhase = new ProjectPhase(newPhaseDO);

		Test.startTest();
		ProjectPhase.commitProjectPhases(new List<ProjectPhase>{ testPhase });
		ProjectPhase__c testPhaseSO = (ProjectPhase__c) testPhase.getSObject();
		QuotePeriod__c testQuotePeriod = [
			SELECT ProjectPhaseId__c
			FROM QuotePeriod__c
			WHERE Id = :newQuotePeriod.Id
		];

		System.assertEquals(
			testPhaseSO.Id,
			testQuotePeriod.ProjectPhaseId__c,
			'should associate quote period to project phase'
		);
		Test.stopTest();
	}
}
