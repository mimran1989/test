/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ProjectPhaseService {
	// constants
	public static final String SOBJECT_NAME = 'ProjectPhase__c';

	public static final String OPERATION_TYPE_INSERT = 'insert';

	public static final String NRTYPE_PROJECT_PHASE = 'Project Phase';
	public static final String NRTYPE_QUOTE_ITEM = 'Quote Item';
	public static final String NRTYPE_QUOTE_PERIOD_GROUP = 'Quote Item Period Group';

	/**
	 * Gets all project phases for quote
	 * @param   quoteId Id of the quote
	 * @return  List<ProjectPhaseDO>
	 */
	public static List<ProjectPhaseDO> getProjectPhasesForQuote(Id quoteId) {
		List<ProjectPhaseDO> projectPhaseMOs = new List<ProjectPhaseDO>();

		for (ProjectPhase__c projectPhaseSO : ProjectPhaseFactory.getProjectPhasesForQuote(quoteId)) {
			ProjectPhaseDO projectPhaseDO = (ProjectPhaseDO) ProjectPhaseDO.newDO(projectPhaseSO);
			projectPhaseMOs.add(projectPhaseDO);
		}

		return projectPhaseMOs;
	}

	/**
	 * @param projectPhaseColData project phase col data
	 *
	 * @return boolean indicating true if method executed till the end
	 */
	public static Boolean commitProjectPhases(String projectPhaseColData) {
		List<ProjectPhaseDO> projectPhaseDOs = (List<ProjectPhaseDO>) JSON.deserialize(
			projectPhaseColData,
			List<ProjectPhaseDO>.class
		);

		List<ProjectPhase> projectPhasesToCommit = new List<ProjectPhase>();
		for (ProjectPhaseDO projectPhaseDO : projectPhaseDOs) {
			ProjectPhase projectPhase = new ProjectPhase(projectPhaseDO);
			projectPhasesToCommit.add(projectPhase);
		}

		ProjectPhase.commitProjectPhases(projectPhasesToCommit);

		Boolean isSuccess = true;
		return isSuccess;
	}
}
