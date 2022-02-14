import { createElement } from 'lwc';
import QuoteAncillaries from 'c/quoteAncillaries';
import QUOTE_ITEM_PRICE_METHOD_FIELD from '@salesforce/schema/QuoteItem__c.PriceMethod__c';

jest.mock(
	'lightning/platformResourceLoader',
	() => ({
		loadScript() {
			return new Promise((resolve) => {
				global.Provus = {};
				global.Provus.Queue = jest.fn().mockImplementation(() => ({ registerActions: jest.fn() }));

				global.Provus.Sync = {};
				global.Provus.Sync.forType = jest.fn(() => ({ watch: jest.fn() }));

				resolve();
			});
		},
	}),
	{ virtual: true },
);

const PRICE_METHOD = {
	FLAT_PRICE: 'Flat Price',
	PER_HEAD: 'Per Head',
	PERCENTAGE_OF_COST: '% of Cost',
	PERCENTAGE_OF_REVENUE: '% of Revenue',
	NON_BILLABLE: 'Non-Billable',
};

describe('quoteAncillaries', () => {
	it('should add readonly cells into cellOptions when PriceMethod is Non-billable', async() => {
		const element = createElement('c-quote-ancillaries', {
			is: QuoteAncillaries,
		});

		document.body.appendChild(element);
		await Promise.resolve();
		const quoteItemSO = {};
		quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] = PRICE_METHOD.NON_BILLABLE;

		const quoteItem = {
			quoteItemSO,
		};

		const options = element.checkNonBillableSetting(quoteItem, 1);
		expect(options.get('1-6').row).toBe(1);
		expect(options.get('1-6').col).toBe(6);
		expect(options.get('1-6').readOnly).toBe(true);

		expect(options.get('1-7').row).toBe(1);
		expect(options.get('1-7').col).toBe(7);
		expect(options.get('1-7').readOnly).toBe(true);
	});
	it('should not add readonly cells into cellOptions when PriceMethod is not Non-billable', async() => {
		const element = createElement('c-quote-ancillaries', {
			is: QuoteAncillaries,
		});

		document.body.appendChild(element);
		await Promise.resolve();
		const quoteItemSO = {};
		quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] = PRICE_METHOD.FLAT_PRICE;

		const quoteItem = {
			quoteItemSO,
		};

		const options = element.checkNonBillableSetting(quoteItem, 1);
		expect(options.get('1-6').row).toBe(1);
		expect(options.get('1-6').col).toBe(6);
		expect(options.get('1-6').readOnly).toBe(false);

		expect(options.get('1-7').row).toBe(1);
		expect(options.get('1-7').col).toBe(7);
		expect(options.get('1-7').readOnly).toBe(false);
	});
	it('is element created', async() => {
		const element = createElement('c-quote-ancillaries', {
			is: QuoteAncillaries,
		});

		document.body.appendChild(element);

		await expect(element).toBeTruthy();
	});
});
