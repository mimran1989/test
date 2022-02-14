/**
 *  Provus Services Quoting
 *  ProjectPhase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ProjectPhase extends ManagedObject {
	public ProjectPhase(ProjectPhaseDO projectPhaseDO) {
		super(projectPhaseDO);
		this.pSObject = projectPhaseDO.newSO();
	}

	public ProjectPhase(SObject projectPhaseSO) {
		super(ProjectPhaseDO.newDO(projectPhaseSO));
		this.pSObject = projectPhaseSO;
	}

	public static void commitProjectPhases(List<ProjectPhase> projectPhases) {
		List<ProjectPhase> projectPhasesToCommit = new List<ProjectPhase>();
		List<ProjectPhase__c> projectPhaseSOsToCommit = new List<ProjectPhase__c>();
		List<ProjectPhase__c> projectPhasesToDelete = new List<ProjectPhase__c>();
		for (ProjectPhase projectPhase : projectPhases) {
			ProjectPhase__c projectPhaseSO = (ProjectPhase__c) projectPhase.getSObject();

			if (!projectPhase.isDelete()) {
				projectPhaseSOsToCommit.add(projectPhaseSO);
				projectPhasesToCommit.add(projectPhase);
			} else {
				projectPhasesToDelete.add(projectPhaseSO);
			}
		}

		CRUDUtility.deleteRecords(projectPhasesToDelete);
		CRUDUtility.upsertRecords(projectPhaseSOsToCommit);

		updateQuotePeriodsFor(projectPhasesToCommit);
	}

	private static void updateQuotePeriodsFor(List<ProjectPhase> contextPhases) {
		List<QuotePeriod__c> quotePeriodsToUpdate = new List<QuotePeriod__c>();
		for (ProjectPhase phaseMO : contextPhases) {
			for (Id quotePeriodId : phaseMO.getPeriodIds()) {
				ProjectPhase__c projectPhaseSO = (ProjectPhase__c) phaseMO.getSObject();
				QuotePeriod__c periodToUpdate = new QuotePeriod__c();
				periodToUpdate.Id = quotePeriodId;
				periodToUpdate.ProjectPhaseId__c = projectPhaseSO.Id;
				quotePeriodsToUpdate.add(periodToUpdate);
			}
		}

		CRUDUtility.updateRecords(quotePeriodsToUpdate);
	}

	private List<Id> getPeriodIds() {
		return ((ProjectPhaseDO) baseDTO).quotePeriodIdList;
	}
}
