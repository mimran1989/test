/**
 *  Provus Services Quoting
 *  TestDataFactory
 *  @2021 Provus Inc. All rights reserved.
 */
public class TestDataFactory {
	public static Product2 createResource(String resourceName, Id recordtypeId) {
		Product2 prd = new Product2();
		prd.Name = resourceName;
		prd.RecordTypeId = recordtypeId;
		return prd;
	}

	public static Estimate__c createEstimate(String estimateName, boolean isActive) {
		Estimate__c es = new Estimate__c();
		es.Name = estimateName;
		es.IsActive__c = isActive;
		return es;
	}

	public static ActivityGroup__c createActivityGroup(String activityGroupName) {
		ActivityGroup__c ag = new ActivityGroup__c();
		ag.Name = activityGroupName;
		ag.IsActive__c = true;
		ag.Sequence__c = 1;
		return ag;
	}

	public static Activity__c createActivity(Id actGrpId) {
		Activity__c at = new Activity__c();
		at.ActivityGroupId__c = actGrpId;
		at.Sequence__c = 1;
		return at;
	}

	public static Activity__c createActivity(String activityName, Id actGrpId) {
		Activity__c at = new Activity__c();
		at.Name = activityName;
		at.ActivityGroupId__c = actGrpId;
		at.Sequence__c = 1;
		return at;
	}

	public static Task__c createTask(Id actId, Id resourceId, Id levelSummaryId) {
		Task__c tk = new Task__c();
		tk.ActivityId__c = actId;
		tk.ResourceRoleId__c = resourceId;
		tk.IsActive__c = true;
		tk.Sequence__c = 1;
		tk.RoleSummaryId__c = levelSummaryId;
		return tk;
	}

	public static TaskSummary__c createTaskSummary() {
		TaskSummary__c taskSummary = new TaskSummary__c();
		return taskSummary;
	}

	public static TaskRoleSummary__c createTaskRoleSummaryForActivity(
		Id activityId,
		String level,
		Id summaryId
	) {
		TaskRoleSummary__c taskRoleSummary = new TaskRoleSummary__c();
		taskRoleSummary.ActivityId__c = activityId;
		taskRoleSummary.SummaryLevel__c = level;
		taskRoleSummary.SummaryId__c = summaryId;
		return taskRoleSummary;
	}

	public static TaskRoleSummary__c createTaskRoleSummaryForEstimate(
		Id estimateId,
		String level,
		Id summaryId
	) {
		TaskRoleSummary__c taskRoleSummary = new TaskRoleSummary__c();
		taskRoleSummary.EstimateId__c = estimateId;
		taskRoleSummary.SummaryLevel__c = level;
		taskRoleSummary.SummaryId__c = summaryId;
		return taskRoleSummary;
	}

	public static EstimateTemplate__c createEstimateTemplate(
		String estimateName,
		Boolean isActive,
		String rateCardId
	) {
		EstimateTemplate__c estimateTemplate = new EstimateTemplate__c(
			Name = estimateName,
			IsActive__c = isActive,
			RateCardId__c = rateCardId
		);
		return estimateTemplate;
	}

	public static ActivityGroupTemplate__c createActivityGroupTemplate(
		String activityGroupName,
		Boolean isActive,
		String estimateTemplateId
	) {
		ActivityGroupTemplate__c activityGroupTemplate = new ActivityGroupTemplate__c(
			Name = activityGroupName,
			IsActive__c = isActive,
			EstimateTemplateId__c = estimateTemplateId
		);
		return activityGroupTemplate;
	}

	public static ActivityTemplate__c createActivityTemplate(
		String activityName,
		Boolean isActive,
		String activityGroupTemplateId
	) {
		ActivityTemplate__c activityRecord = new ActivityTemplate__c(
			Name = activityName,
			IsActive__c = isActive,
			ActivityGroupTemplateId__c = activityGroupTemplateId
		);
		return activityRecord;
	}

	public static TaskTemplate__c createTaskTemplate(
		String taskName,
		Boolean isActive,
		String activityTemplateId
	) {
		TaskTemplate__c taskTemplate = new TaskTemplate__c(
			Name = taskName,
			IsActive__c = isActive,
			ActivityTemplateId__c = activityTemplateId
		);
		return taskTemplate;
	}

	public static TaskParameterTemplate__c createTaskParamTemplate(
		String taskParamName,
		Boolean isActive,
		String taskId
	) {
		TaskParameterTemplate__c taskParamTemplate = new TaskParameterTemplate__c(
			Name = taskParamName,
			IsActive__c = isActive,
			TaskTemplateId__c = taskId
		);
		return taskParamTemplate;
	}

	public static TaskParameterValueTemplate__c createTaskParamValueTemplate(String taskParamTempId) {
		TaskParameterValueTemplate__c taskParamValueTemplate = new TaskParameterValueTemplate__c(
			TaskParameterTemplateId__c = taskParamTempId
		);
		return taskParamValueTemplate;
	}
}
