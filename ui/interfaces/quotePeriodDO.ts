export interface QuotePeriodDO {
	id: string;
	name: string;
	startDate: Date;
	endDate: Date;
	sequence: number;
	term: number;
	periodGroupName: string;
	periodGroupId: string;
	projectPhaseId: string;
	projectPhaseName: string;
}
