import { UIElementDO } from './elementDO';

export interface ProjectPhaseDO extends UIElementDO {
	id: string;
	name: string;
	quoteId: string;
	sequence: number;
	description: string;
	startDate: string;
	endDate: string;
	operationType: string;
	parentProjectPhaseId: string;
	parentProjectName: string;
	quotePeriodIdList: string[];
}
