/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import {
	subscribe, unsubscribe, onError,
} from 'lightning/empApi';
import { createElement } from 'lwc';

describe('eventListener', () => {
	let EventListener;
	let element;
	beforeEach(async() => {
		jest.isolateModules(() => {
			const module = require('c/eventListener');
			EventListener = module.default;
		});

		element = createElement('c-event-listener', {
			is: EventListener,
		});

		element.handler = jest.fn();
		element.channel = 'Test__e';
	});
	it('should call subscribe and register and error callback on connected', async() => {
		document.body.appendChild(element);
		await Promise.resolve();
		expect(subscribe).toBeCalled();
		expect(onError).toBeCalled();
	});
	it('should call subscribe only once when there are multiple elements with the same channel', async() => {
		const element2 = createElement('c-event-listener', {
			is: EventListener,
		});

		element2.handler = jest.fn();
		element2.channel = 'Test__e';
		document.body.appendChild(element);
		document.body.appendChild(element2);
		await Promise.resolve();

		expect(subscribe).toBeCalledTimes(1);
	});
	it('should call subscribe once for each channel when there are multiple elements with different channels', async() => {
		const element2 = createElement('c-event-listener', {
			is: EventListener,
		});

		element2.handler = jest.fn();
		element2.channel = 'Test2__e';
		document.body.appendChild(element);
		document.body.appendChild(element2);
		await Promise.resolve();

		expect(subscribe).toBeCalledTimes(2);
	});
	it('should call unsubscribe when there are no more subscribers for a channel', async(done) => {
		const domElem = document.body.appendChild(element);
		await Promise.resolve();

		setImmediate(() => {
			document.body.removeChild(domElem);
			expect(unsubscribe).toBeCalled();
			done();
		});
	});
});
