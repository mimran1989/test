import { UIElementDO } from './elementDO';

export interface QuoteSectionDO extends UIElementDO {
	childSections: QuoteSectionDO[];
	description?: string;
	displaySequence: number;
	id?: string;
	isLocked: boolean;
	isRevocable: boolean;
	name: string;
	operationType?: string;
	parentSectionId?: string;
	parentSectionName?: string;
	quoteId: string;
	quoteItemIdList: string[];
	sectionSequence: number;
	sequence: number;
	startRow: number;
}
