import { UIElementDO } from './elementDO';
import { AdjustmentDO } from './adjustmentDO';

export interface QuoteItemDTO extends UIElementDO {
	adjustmentId?: string;
	adjustment: AdjustmentDO;
	displaySequence: number;
	id?: string;
	lineSequence: number;
	operationType?: string;
	periodValueMap: Record<string, number>;
	productId?: string;
	quoteItemCellId?: string;
	quoteItemSO: Record<string, any>;
	rateCardItemId?: string;
	sectionId: string;
	sectionSequence: number;
}
