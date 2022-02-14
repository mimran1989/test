/**
 *  Provus Services Quoting
 *  ProjectPhaseTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class ProjectPhaseTestsBase extends TestBase {
	public static ProjectPhase__c newPhase() {
		Quote__c testQuote = newQuote();
		return newPhase(testQuote.Id);
	}

	public static ProjectPhase__c newPhase(Id quoteId) {
		ProjectPhase__c newPhase = new ProjectPhase__c();
		newPhase.Name = 'Test Phase';
		newPhase.QuoteId__c = quoteId;

		CRUDUtility.insertRecords(newPhase);
		return newPhase;
	}

	public static ProjectPhaseDO newPhaseDO() {
		Quote__c testQuote = newQuote();
		return newPhaseDO(testQuote.Id);
	}

	public static ProjectPhaseDO newPhaseDO(Id quoteId) {
		ProjectPhaseDO newDO = new ProjectPhaseDO();
		newDO.quotePeriodIdList = new List<Id>();
		newDO.quoteId = quoteId;
		return newDO;
	}
}
