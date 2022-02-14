import { QuoteItem, QuoteItems } from './quoteItem';
import { QuoteItemDTO } from '../../interfaces/quoteItemDTO';
import { QuoteSectionDO } from '../../interfaces/quoteSectionDO';
import { Section, Sections } from './section';

describe('QuoteItem', () => {
	describe('metadata', () => {
		it('should return the row metadata object', () => {
			const quoteItem = QuoteItems.for([{ productId: 'testProductId', lineSequence: 1 } as QuoteItemDTO])[0] as QuoteItem;
			expect(quoteItem.metadata()).toEqual({
				$id: quoteItem.$id,
				productId: 'testProductId',
				lineSequence: 1,
			});
		});
	});
	describe('clearSection', () => {
		let quoteItem: QuoteItem;
		beforeEach(() => {
			quoteItem = QuoteItems.for([{ quoteItemSO: {} } as QuoteItemDTO])[0] as QuoteItem;
		});
		it('should remove the associated section', () => {
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0] as Section;
			quoteItem.setParent(section);
			expect(quoteItem.parent).toBeDefined();
			quoteItem.clearSection();
			expect(quoteItem.parent).toBeUndefined();
		});
		it('should set the $treeLevel to 0', () => {
			quoteItem.clearSection();
			expect(quoteItem.$treeLevel).toBe(0);
		});
	});
	describe('setTreeLevel', () => {
		it('should set the treeLevel to the passed in value', () => {
			const quoteItem = QuoteItems.for([{ quoteItemSO: {} } as QuoteItemDTO])[0] as QuoteItem;
			quoteItem.setTreeLevel(3);
			expect(quoteItem.$treeLevel).toBe(3);
		});
	});
	describe('setParent', () => {
		it('should set the treeLevel to the parent treeLevel + 1', () => {
			const quoteItem = QuoteItems.for([{ quoteItemSO: {} } as QuoteItemDTO])[0] as QuoteItem;
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0] as Section;
			section.setTreeLevel(1);
			quoteItem.setParent(section);
			expect(quoteItem.$treeLevel).toBe(2);
		});
		it('should set the displaySequence of the child to that of the parent', () => {
			const quoteItem = QuoteItems.for([{ quoteItemSO: {} } as QuoteItemDTO])[0] as QuoteItem;
			const section = Sections.for([{} as QuoteSectionDO], undefined)[0] as Section;
			section.elementDO.displaySequence = 2;
			section.setTreeLevel(1);
			quoteItem.setParent(section);
			expect(quoteItem.elementDO.displaySequence).toBe(section.elementDO.displaySequence);
		});
	});
});
