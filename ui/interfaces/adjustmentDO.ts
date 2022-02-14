import { UIElementDO } from './elementDO';

export interface AdjustmentDO extends UIElementDO {
	type: string;
	amount: number;
	sequence: number;
	method: string;
	appliedTo: string;
	appliedBy: string;
	adjustmentId: string;
}
