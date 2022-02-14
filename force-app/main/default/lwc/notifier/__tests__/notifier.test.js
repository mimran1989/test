/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { createElement } from 'lwc';
import Notifier from 'c/notifier';
import {
	subscribe,
} from 'lightning/empApi';
import NamespacePrefix from '@salesforce/apex/SystemUtility.getNamespacePrefix';

jest.mock(
	'@salesforce/apex/QuoteConfiguratorController.getNamespacePrefix',
	() => {
		const {
			createApexTestWireAdapter,
		} = require('@salesforce/sfdx-lwc-jest');

		return {
			default: createApexTestWireAdapter(jest.fn()),
		};
	},
	{ virtual: true },
);

jest.useFakeTimers();

describe('notifier', () => {
	let onMessage;
	beforeEach(() => {
		subscribe.mockImplementation((channel, code, handler) => {
			onMessage = handler;
		});
	});
	it('should show the notification when the current quote is affected', async() => {
		const element = createElement('c-notifier', {
			is: Notifier,
		});

		element.quote = 'testId';
		element.handler = jest.fn();
		NamespacePrefix.emit('');

		document.body.appendChild(element);
		await Promise.resolve();

		onMessage({
			data: {
				payload: {
					AffectedQuotes__c: 'testId',
					User__c: 'testUser',
				},
			},
		});
		await Promise.resolve();

		const notifyContainer = element.shadowRoot.querySelectorAll('.slds-notify_container');
		expect(notifyContainer.length).toEqual(1);
	});
	it('should hide the notification after the timer runs out', async() => {
		const element = createElement('c-notifier', {
			is: Notifier,
		});

		element.quote = 'testId';
		element.handler = jest.fn();
		NamespacePrefix.emit('');

		document.body.appendChild(element);
		await Promise.resolve();

		onMessage({
			data: {
				payload: {
					AffectedQuotes__c: 'testId',
					User__c: 'testUser',
				},
			},
		});
		await Promise.resolve();

		let notifyContainer = element.shadowRoot.querySelectorAll('.slds-notify_container');
		expect(notifyContainer.length).toEqual(1);
		jest.runAllTimers();
		await Promise.resolve();

		notifyContainer = element.shadowRoot.querySelectorAll('.slds-notify_container');
		expect(notifyContainer.length).toEqual(0);
	});
});
