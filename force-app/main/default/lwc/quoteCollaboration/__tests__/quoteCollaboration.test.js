/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { createElement } from 'lwc';
import QuoteCollaboration from 'c/quoteCollaboration';
import getUsers from '@salesforce/apex/QuoteCollaborationController.getUsers';
import getAvailableQuoteSections from '@salesforce/apex/QuoteCollaborationController.getAvailableQuoteSections';

jest.mock('lightning/actions', () => {}, { virtual: true });
jest.mock('@salesforce/apex/QuoteCollaborationController.getUsers',
	() => ({
		default: jest.fn(),
	}),
	{ virtual: true });

describe('quoteCollaboration', () => {
	beforeEach(() => {
		getUsers.mockResolvedValue([]);
		getAvailableQuoteSections.mockResolvedValue('[]');
	});
	it('should show the disabled button on load', async() => {
		const element = createElement('c-quote-collaboration', {
			is: QuoteCollaboration,
		});

		document.body.appendChild(element);
		await Promise.resolve();

		const disabledInviteButton = element.shadowRoot.querySelectorAll('button[name="button-invite-disabled"]');
		expect(disabledInviteButton.length).toEqual(1);
	});
});
