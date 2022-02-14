import { createElement } from 'lwc';
import renameAddOn from 'c/renameAddOn';
import getAllProductsForQuote from '@salesforce/apex/QuoteConfiguratorController.getAllProductsForQuote';

jest.mock('lightning/flowSupport', () => {}, { virtual: true });
jest.useFakeTimers();

describe('renameAddOn', () => {
	describe('constructor', () => {
		it('should render the rename add-on lwc', async() => {
			const products = [
				{ name: 'test1', id: 'test1' },
				{ name: 'test2', id: 'test2' },
				{ name: 'test3', id: 'test3' },
			];

			getAllProductsForQuote.mockReturnValue(JSON.stringify(products));

			// lightning-base-combobox-item
			const element = createElement('c-rename-add-on', {
				is: renameAddOn,
			});

			element.quote = 'testId';
			document.body.appendChild(element);
			await Promise.resolve();

			const inputtext = element.shadowRoot.querySelectorAll('lightning-input');
			expect(inputtext.length).toEqual(1);
		});
	});
});
