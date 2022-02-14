import UIElement, { ObservedElement } from './element';
import { QuoteItemDTO } from '../../interfaces/quoteItemDTO';
import { Section } from './section';

export class QuoteItem extends UIElement {
	$treeLevel: number = 0;
	elementDO: QuoteItemDTO;
	parent: Section;

	static TYPE = 'QuoteItem';

	constructor() {
		super();
		this.$type = QuoteItem.TYPE;
	}

	metadata = () : {} => ({ lineSequence: this.elementDO.lineSequence, productId: this.elementDO.productId, $id: this.$id });

	clearSection = () => {
		this.parent = undefined;
		this.$treeLevel = 0;
		this.elementDO.quoteItemSO.sectionId = null;
		this.elementDO.quoteItemSO.sectionSequence = null;
	}

	setParent = (section: Section): void => {
		this.parent = section;
		this.$treeLevel = section.$treeLevel + 1;
		this.elementDO.sectionId = section.elementDO.id;
		this.elementDO.displaySequence = section.elementDO.displaySequence;
	}

	setTreeLevel = (number: number) => {
		this.$treeLevel = number;
	}
}

export const QuoteItems = {
	for: (quoteItemDOs: QuoteItemDTO[]): ObservedElement[] => quoteItemDOs.map((quoteItemDO) => QuoteItem.for(quoteItemDO)),
};
