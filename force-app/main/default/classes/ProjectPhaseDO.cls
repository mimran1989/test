public class ProjectPhaseDO extends BaseDTO {
	public Id id;
	public String name;
	public Id quoteId;
	public Decimal sequence;
	public String description;
	public Date startDate;
	public Date endDate;

	public Id parentProjectPhaseId;
	public String parentProjectName;

	public List<Id> quotePeriodIdList;

	public static BaseDTO newDO(SObject fromSO) {
		ProjectPhase__c projectPhaseSO = (ProjectPhase__c) fromSO;
		ProjectPhaseDO newDO = new ProjectPhaseDO();
		newDO.id = projectPhaseSO.Id;
		newDO.name = projectPhaseSO.Name;
		newDO.quoteId = projectPhaseSO.QuoteId__c;
		newDO.sequence = projectPhaseSO.Sequence__c;
		newDO.description = projectPhaseSO.Description__c;
		newDO.startDate = projectPhaseSO.StartDate__c;
		newDO.endDate = projectPhaseSO.EndDate__c;

		newDO.quotePeriodIdList = new List<Id>();
		for (QuotePeriod__c quotePeriod : projectPhaseSO.QuotePeriods__r) {
			newDO.quotePeriodIdList.add(quotePeriod.Id);
		}

		return newDO;
	}

	public ProjectPhase__c newSO() {
		ProjectPhase__c projectPhaseSO = new ProjectPhase__c(
			Id = this.id,
			Name = this.name,
			QuoteId__c = this.quoteId,
			Sequence__c = this.sequence,
			Description__c = this.description,
			StartDate__c = this.startDate,
			EndDate__c = this.endDate
		);

		return projectPhaseSO;
	}
}
