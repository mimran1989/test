import * as _ from 'lodash';
import UIElement from './element';
import { QuoteSectionDO } from '../../interfaces/quoteSectionDO';
import { QuoteItem } from './quoteItem';

export class Section extends UIElement {
	$type: string = Section.TYPE;
	$treeLevel: number = 0;
	quoteItems: QuoteItem[] = [];
	elementDO: QuoteSectionDO;
	parent: Section;
	childSections: Section[] = [];
	children: (Section | QuoteItem)[] = [];

	static TYPE = 'Section';
	private locked: boolean;
	private revocable: boolean;

	static ascendingBySequence(lhs: Section, rhs: Section) {
		const left = lhs.elementDO as QuoteSectionDO;
		const right = rhs.elementDO as QuoteSectionDO;
		let result = 0;
		if (left.sequence < right.sequence) {
			result = -1;
		} else if (left.sequence > right.sequence) {
			result = 1;
		}

		return result;
	}

	static ascendingByDisplaySequence(lhs: Section | QuoteItem, rhs: Section | QuoteItem) {
		const left = lhs.elementDO as QuoteSectionDO;
		const right = rhs.elementDO as QuoteSectionDO;
		let result = 0;
		if (left.displaySequence < right.displaySequence) {
			result = -1;
		} else if (left.displaySequence > right.displaySequence) {
			result = 1;
		}

		return result;
	}

	static ascendingBySectionSequence(lhs: Section | QuoteItem, rhs: Section | QuoteItem) {
		const left = lhs.elementDO as QuoteSectionDO;
		const right = rhs.elementDO as QuoteSectionDO;
		let result = 0;
		if (left.sectionSequence < right.sectionSequence) {
			result = -1;
		} else if (left.sectionSequence > right.sectionSequence) {
			result = 1;
		}

		return result;
	}

	static newDO({ ...props }): QuoteSectionDO {
		return {
			childSections: [],
			description: null,
			displaySequence: null,
			id: null,
			isLocked: false,
			isRevocable: false,
			name: null,
			operationType: null,
			parentSectionId: null,
			parentSectionName: null,
			quoteId: props.quoteId,
			quoteItemIdList: [],
			sectionSequence: null,
			sequence: null,
			startRow: 0,
		};
	}

	spliceQuoteItems = (start: number, deleteCount?: number, ...itemsToAdd: QuoteItem[]): void => {
		this.quoteItems.splice(start, deleteCount, ...itemsToAdd);
		this.elementDO.quoteItemIdList = [...this.quoteItems.map((item) => item.elementDO.id)];
		const combined = [...this.quoteItems, ...this.childSections];
		combined.sort(Section.ascendingBySectionSequence);
		this.children = combined;
		this.sequenceChildren();
	};

	setChildren = (itemsToAdd: (Section | QuoteItem)[]): void => {
		this.clearChildren();
		this.quoteItems = itemsToAdd.filter((nextItem) => nextItem.$type === QuoteItem.TYPE) as QuoteItem[];
		this.childSections = itemsToAdd.filter((nextItem) => nextItem.$type === Section.TYPE) as Section[];
		this.elementDO.quoteItemIdList = [...this.quoteItems.map((item) => item.elementDO.id)];
		this.children = itemsToAdd;
		this.sequenceChildren();
	};

	sequenceChildren = (): void => {
		const self = this;
		let nextSectionSequence = 1;
		this.children.forEach((nextItem) => {
			nextItem.setTreeLevel(self.$treeLevel + 1);

			if (nextItem.$type === QuoteItem.TYPE) {
				const item = nextItem as QuoteItem;
				item.setParent(self.$proxied);
			}

			const childItem = nextItem;
			childItem.elementDO.sectionSequence = nextSectionSequence;
			nextSectionSequence += 1;
		});
	}

	addQuoteItem = (item: QuoteItem): void => {
		this.quoteItems.push(item);
		this.children.push(item);
		this.elementDO.quoteItemIdList = this.elementDO.quoteItemIdList || [];
		this.elementDO.quoteItemIdList.push(item.elementDO.id);
		this.sequenceChildren();
	}

	removeChild = (item: QuoteItem): void => {
		item.clearSection();
		_.remove(this.quoteItems, item);
		_.remove(this.children, item);
		_.remove(this.elementDO.quoteItemIdList, item.elementDO.id);
		this.sequenceChildren();
	}

	clearChildren = (): void => {
		this.children.length = 0;
	}

	setParent = (newParent: Section): void => {
		this.parent = newParent;
		this.elementDO.parentSectionId = newParent.elementDO.id;
		this.elementDO.displaySequence = newParent.elementDO.displaySequence;
		this.setTreeLevel(newParent.$treeLevel + 1);
	}

	setTreeLevel = (level: number): void => {
		this.$treeLevel = level;
	}

	metadata = () => ({
		$id: this.$id,
		isSectionHeader: true,
		readOnly: true,
	})

	setLocked = (value: boolean): void => {
		this.locked = value;
	}

	isLocked = (): boolean => this.locked

	setRevocable = (value: boolean): void => {
		this.revocable = value;
	}

	isRevocable = (): boolean => this.revocable
}

export const Sections = {
	for: (sectionDOs: QuoteSectionDO[], parent: Section): Section[] => {
		const wrappedSections: Section[] = [];
		sectionDOs.forEach((sectionDO) => {
			const wrappedSection = Section.for(sectionDO) as Section;
			wrappedSections.push(wrappedSection);

			if (parent) {
				wrappedSection.setParent(parent);
			}

			if (sectionDO.childSections?.length > 0) {
				wrappedSection.childSections.push(...Sections.for(sectionDO.childSections, wrappedSection));
			}
		});

		return wrappedSections;
	},
};
