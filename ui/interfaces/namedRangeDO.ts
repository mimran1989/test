import { AdjustmentDO } from './adjustmentDO';
import { UIElementDO } from './elementDO';
import { NamedRangeTotalDO } from './namedRangeTotalDO';

export interface NamedRangeDO extends UIElementDO {
	name: string;
	namedRangeId?: string;
	quoteItemId?: string;
	quotePeriodId?: string;
	quotePeriodGroupId?: string;
	quoteSectionId?: string;
	projectPhaseId?: string;
	type: string;
	rangeSpec?: string;
	relatedTotal: NamedRangeTotalDO;
	adjustmentList: AdjustmentDO[];
}
