/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private class QuoteSummaryServiceTest extends TestBase {
	private static QuotePeriodGroup__c newQuotePeriodGroup(Id quoteId) {
		QuotePeriodGroup__c newQuotePeriodGroup = new QuotePeriodGroup__c();
		newQuotePeriodGroup.QuoteId__c = quoteId;
		CRUDUtility.insertRecords(newQuotePeriodGroup);
		return newQuotePeriodGroup;
	}

	private static NamedRange__c newNamedRange(Id quoteId, String type) {
		NamedRange__c newNamedRange = new NamedRange__c();
		newNamedRange.QuoteId__c = quoteId;
		newNamedRange.Type__c = type;
		CRUDUtility.insertRecords(newNamedRange);
		return newNamedRange;
	}

	private static ProjectPhase__c newProjectPhase(Id quoteId) {
		ProjectPhase__c newProjectPhase = new ProjectPhase__c();
		newProjectPhase.QuoteId__c = quoteId;
		CRUDUtility.insertRecords(newProjectPhase);
		return newProjectPhase;
	}

	@IsTest
	static void shouldOrderPeriodGroupSequence() {
		Quote__c quote = newQuote();
		QuotePeriodGroup__c group2 = newQuotePeriodGroup(quote.Id);
		group2.Name = '2';
		group2.Sequence__c = 2;
		QuotePeriodGroup__c group3 = newQuotePeriodGroup(quote.Id);
		group3.Name = '3';
		group3.Sequence__c = 3;
		QuotePeriodGroup__c group1 = newQuotePeriodGroup(quote.Id);
		group1.Name = '1';
		group1.Sequence__c = 1;

		CRUDUtility.updateRecords(new List<QuotePeriodGroup__c>{ group1, group2, group3 });

		NamedRange__c range1 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_QUOTE_PERIOD_GROUP);
		range1.QuotePeriodGroupId__c = group1.Id;
		NamedRange__c range2 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_QUOTE_PERIOD_GROUP);
		range2.QuotePeriodGroupId__c = group2.Id;
		NamedRange__c range3 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_QUOTE_PERIOD_GROUP);
		range3.QuotePeriodGroupId__c = group3.Id;

		CRUDUtility.updateRecords(new List<NamedRange__c>{ range1, range2, range3 });

		Test.startTest();
		List<QuoteSummaryDO> summaries = QuoteSummaryService.getQuoteSummaries(quote.Id);
		System.assertEquals('1', summaries[0].rowName, 'should be 1');
		System.assertEquals('2', summaries[1].rowName, 'should be 2');
		System.assertEquals('3', summaries[2].rowName, 'should be 3');
		Test.stopTest();
	}

	@IsTest
	static void shouldOrderProjectPhaseSequence() {
		Quote__c quote = newQuote();
		ProjectPhase__c phase2 = newProjectPhase(quote.Id);
		phase2.Name = '2';
		phase2.Sequence__c = 2;
		ProjectPhase__c phase3 = newProjectPhase(quote.Id);
		phase3.Name = '3';
		phase3.Sequence__c = 3;
		ProjectPhase__c phase1 = newProjectPhase(quote.Id);
		phase1.Name = '1';
		phase1.Sequence__c = 1;

		CRUDUtility.updateRecords(new List<ProjectPhase__c>{ phase1, phase2, phase3 });

		NamedRange__c range1 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_PROJECT_PHASE);
		range1.ProjectPhaseId__c = phase1.Id;
		NamedRange__c range2 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_PROJECT_PHASE);
		range2.ProjectPhaseId__c = phase2.Id;
		NamedRange__c range3 = newNamedRange(quote.Id, ProjectPhaseService.NRTYPE_PROJECT_PHASE);
		range3.ProjectPhaseId__c = phase3.Id;

		CRUDUtility.updateRecords(new List<NamedRange__c>{ range1, range2, range3 });

		Test.startTest();
		List<QuoteSummaryDO> summaries = QuoteSummaryService.getQuoteSummaries(quote.Id);
		System.assertEquals('1', summaries[0].rowName, 'should be 1');
		System.assertEquals('2', summaries[1].rowName, 'should be 2');
		System.assertEquals('3', summaries[2].rowName, 'should be 3');
		Test.stopTest();
	}
}
