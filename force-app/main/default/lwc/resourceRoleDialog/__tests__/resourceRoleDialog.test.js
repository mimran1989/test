/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { createElement } from 'lwc';
import ResourceRoleDialog from 'c/resourceRoleDialog';
import getAllOriginalProductsForQuote from '@salesforce/apex/QuoteConfiguratorController.getAllOriginalProductsForQuote';

jest.mock('lightning/flowSupport', () => {}, { virtual: true });
jest.mock(
	'@salesforce/apex/QuoteConfiguratorController.getAllOriginalProductsForQuote',
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

describe('resourceRoleDialog', () => {
	describe('constructor', () => {
		it('should render the soql datatable', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			element.selectedRole = 'testRoleName';

			document.body.appendChild(element);
			await Promise.resolve();

			const datatable = element.shadowRoot.querySelectorAll('c-soql-datatable');
			expect(datatable.length).toEqual(1);
		});

		it('should render the resource role dropdown', async() => {
			const products = [
				{ name: 'test1', id: 'test1' },
				{ name: 'test2', id: 'test2' },
				{ name: 'test3', id: 'test3' },
			];

			// lightning-base-combobox-item
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			getAllOriginalProductsForQuote.emit(products);

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			document.body.appendChild(element);
			await Promise.resolve();

			const dropdown = element.shadowRoot.querySelectorAll('lightning-combobox');
			expect(dropdown.length).toEqual(1);
		});
		it('should have a default rate card item ID array', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			expect(element.rateCardItemId).toEqual([]);
		});
		it('should transform the given rate card item ID into an array', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.rateCardItemId = 'testId';
			expect(element.rateCardItemId).toEqual(['testId']);

			element.rateCardItemId = ['testId'];
			expect(element.rateCardItemId).toEqual(['testId']);
		});
	});
	describe('showCloseButton', () => {
		it('showCloseButton parameter not specified cancel button IS rendered', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			element.selectedRole = 'testRoleName';

			document.body.appendChild(element);
			await Promise.resolve();

			const lightningButton = element.shadowRoot.querySelectorAll('lightning-button');
			expect(lightningButton.length).toEqual(2);
			expect(lightningButton[0].label).toEqual('c.CancelButton');
		});

		it('showCloseButton parameter true cancel button IS rendered', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			element.selectedRole = 'testRoleName';
			element.showCloseButton = true;

			document.body.appendChild(element);
			await Promise.resolve();

			const lightningButton = element.shadowRoot.querySelectorAll('lightning-button');
			expect(lightningButton.length).toEqual(2);
			expect(lightningButton[0].label).toEqual('c.CancelButton');
		});

		it('should hide the close button when showCloseButton parameter is false and there are resources to select', async() => {
			const products = [
				{ name: 'test1', id: 'test1' },
			];

			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			element.showCloseButton = false;

			getAllOriginalProductsForQuote.emit(products);

			document.body.appendChild(element);
			await Promise.resolve();

			const lightningButton = element.shadowRoot.querySelectorAll('lightning-button');
			expect(lightningButton.length).toEqual(1);
			expect(lightningButton[0].label).toEqual('c.AddToQuote');
		});

		it('should NOT hide the close button when showCloseButton parameter is false and there are no resources to select', async() => {
			const element = createElement('c-resource-role-dialog', {
				is: ResourceRoleDialog,
			});

			element.group = 'test group';
			element.practice = 'test practice';
			element.quote = 'testId';
			element.rateCard = 'testId';
			element.showCloseButton = false;

			getAllOriginalProductsForQuote.emit([]);

			document.body.appendChild(element);
			await Promise.resolve();

			const lightningButton = element.shadowRoot.querySelectorAll('lightning-button');
			expect(lightningButton.length).toEqual(2);
			expect(lightningButton[0].label).toEqual('c.CancelButton');
			expect(lightningButton[1].label).toEqual('c.AddToQuote');
		});
	});
});
