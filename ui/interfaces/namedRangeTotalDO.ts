import { UIElementDO } from './elementDO';

export interface NamedRangeTotalDO extends UIElementDO {
	namedRangeTotalId: string;
	marginPercent: number;
	quantityUOM: string;
	totalAmount: number;
	totalCost: number;
	totalQuantity: number;
}
