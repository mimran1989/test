import { createElement } from 'lwc';
import QuoteDiscounting from 'c/quoteDiscounting';

jest.mock(
	'lightning/actions',
	() => ({
		CloseActionScreenEvent: jest.fn(),
	}),
	{ virtual: true },
);

jest.mock(
	'lightning/platformResourceLoader',
	() => ({
		loadStyle() {},
	}),
	{ virtual: true },
);

describe('loadDiscounts', () => {
	it('is element created', async() => {
		const element = createElement('c-quote-discounting', {
			is: QuoteDiscounting,
		});

		document.body.appendChild(element);
		await expect(element).toBeTruthy();
	});
});
