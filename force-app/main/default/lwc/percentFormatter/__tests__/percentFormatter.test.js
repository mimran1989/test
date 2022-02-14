import { createElement } from 'lwc';
import { setImmediate } from 'timers';
import PercentFormatter from 'c/percentFormatter';

jest.mock('lightning/actions', () => {}, { virtual: true });
const flushPromises = () => new Promise(setImmediate);

describe('percentFormatter', () => {
	it('should divide input value into percent', async() => {
		const element = createElement('c-percent-formatter', {
			is: PercentFormatter,
		});

		element.percentValue = 1056.7829;
		document.body.appendChild(element);
		await flushPromises();
		const formattedNumberElement = element.shadowRoot.querySelector('lightning-formatted-number');
		expect(formattedNumberElement.value).toEqual(10.567829);
	});
	it('is element created', async() => {
		const element = createElement('c-percent-formatter', {
			is: PercentFormatter,
		});

		document.body.appendChild(element);

		await expect(element).toBeTruthy();
	});
});
