import { UIElementDO } from './elementDO';
import { SObjectFieldDO } from './SObjectFieldDO';
import { QuotePeriodDO } from './quotePeriodDO';

export interface QuoteTemplateDO extends UIElementDO {
	quoteTimePeriod: string;
	fieldsList: SObjectFieldDO[];
	quotePeriodList: QuotePeriodDO[];
	isScenario: boolean;
}
