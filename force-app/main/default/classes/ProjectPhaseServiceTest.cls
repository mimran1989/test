/**
 *  Provus Services Quoting
 *  ProjectPhaseServiceTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class ProjectPhaseServiceTest extends ProjectPhaseTestsBase {
	@IsTest
	static void itShouldReturnSuccess() {
		Quote__c testQuote = newQuote();
		ProjectPhaseDO projectPhase = new ProjectPhaseDO();
		projectPhase.quoteId = testQuote.Id;
		projectPhase.name = 'Test Phase';
		projectPhase.operationType = BaseDTO.OPERATION_TYPE_INSERT;
		projectPhase.quotePeriodIdList = new List<Id>();

		Test.startTest();
		Boolean result = ProjectPhaseService.commitProjectPhases(
			JSON.serialize(new List<ProjectPhaseDO>{ projectPhase })
		);
		System.assertEquals(result, true, 'should return success');
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetProjectPhasesForQuote() {
		ProjectPhase__c newPhase = newPhase();

		Test.startTest();
		List<ProjectPhaseDO> quoteProjectPhases = ProjectPhaseService.getProjectPhasesForQuote(
			newPhase.QuoteId__c
		);
		System.assertEquals(1, quoteProjectPhases.size(), 'should return 1 phase');
		System.assertEquals(newPhase.Id, quoteProjectPhases[0].id, 'should return the correct phase');
		Test.stopTest();
	}
}
