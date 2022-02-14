import { createElement } from 'lwc';
import QuoteTotals from 'c/quoteTotals';

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

describe('quoteTotals', () => {
	it('is element created', async() => {
		const element = createElement('c-quote-discounting', {
			is: QuoteTotals,
		});

		document.body.appendChild(element);
		await expect(element).toBeTruthy();
	});
});
