import { Section, Sections } from './section';
import { QuoteSectionDO } from '../../interfaces/quoteSectionDO';
import { QuoteItem } from './quoteItem';

describe('Section', () => {
	describe('constructor', () => {
		it('should create a new Section', () => {
			const section = Section.for({} as QuoteSectionDO);
			expect(section).toBeDefined();
		});
		it('should create a new child Section', () => {
			const sectionDO: QuoteSectionDO = {} as QuoteSectionDO;
			sectionDO.childSections = [{} as QuoteSectionDO];
			const sections: Section[] = Sections.for([sectionDO], undefined);
			expect(sections[0].childSections.length).toBe(1);
		});
	});
	describe('setLocked', () => {
		it('should set the locked property to true', () => {
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0];
			section.setLocked(true);
			expect(section.isLocked()).toBe(true);
		});
	});
	describe('setRevocable', () => {
		it('should set the revocable property to true', () => {
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0];
			section.setRevocable(true);
			expect(section.isRevocable()).toBe(true);
		});
	});
	describe('clearChildren', () => {
		it('should clear the children list', () => {
			const sectionDO: QuoteSectionDO = {} as QuoteSectionDO;
			sectionDO.childSections = [{} as QuoteSectionDO];
			const section = Sections.for([sectionDO], undefined)[0];
			section.spliceQuoteItems(0, 0);
			expect(section.children.length).toBe(1);
			section.clearChildren();
			expect(section.children.length).toBe(0);
		});
	});
	describe('spliceQuoteItems', () => {
		it('should add quote items into the section', () => {
			const quoteItem = QuoteItem.for({}) as QuoteItem;
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0];
			section.spliceQuoteItems(0, 0, quoteItem);
			expect(section.quoteItems.length).toBe(1);
			expect(section.children.length).toBe(1);
		});
		it('should sequence the added quote items', () => {
			const quoteItem1 = QuoteItem.for({}) as QuoteItem;
			const quoteItem2 = QuoteItem.for({}) as QuoteItem;
			const quoteItem3 = QuoteItem.for({}) as QuoteItem;
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0];
			section.spliceQuoteItems(0, 0, quoteItem1, quoteItem2, quoteItem3);
			expect(section.children[0].elementDO.sectionSequence).toBe(1);
			expect(section.children[1].elementDO.sectionSequence).toBe(2);
			expect(section.children[2].elementDO.sectionSequence).toBe(3);
		});
	});
	describe('setChildren', () => {
		it('should set the parent of the children to the current section', () => {
			const quoteItem1 = QuoteItem.for({}) as QuoteItem;
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0];
			section.setChildren([quoteItem1]);
			expect(quoteItem1.parent).toBe(section);
		});
	});
	describe('setParent', () => {
		it('should set the displaySequence of the child to that of the parent', () => {
			const parentSection = Sections.for([{} as QuoteSectionDO], undefined)[0];
			const childSection = Sections.for([{} as QuoteSectionDO], undefined)[0];
			parentSection.elementDO.displaySequence = 2;
			childSection.setParent(parentSection);
			expect(childSection.elementDO.displaySequence).toBe(parentSection.elementDO.displaySequence);
		});
	});
});
