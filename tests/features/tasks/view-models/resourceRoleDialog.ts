import { Component } from '../../support/componentSelector';

const COMPONENT = Component.named('resource-role-dialog');

const BASE_COMBO_BOX = COMPONENT.findWebComponent('lightning-combobox')
	.findWebComponent('lightning-base-combobox');

const RATE_ITEM_ROWS = COMPONENT
	.findWebComponent('c-soql-datatable')
	.findWebComponent('c-base-datatable')
	.findWebComponent('c-base-datatable-extension');

const ResourceRoleDialog = {
	addToQuoteButton: COMPONENT.findWebComponent('lightning-button').child('button').withExactText('Add to quote'),
	cancelButton: COMPONENT.findWebComponent('lightning-button').child('button').withExactText('Cancel'),
	component: COMPONENT,
	noRolesAvailableText: COMPONENT.child('div').withExactText('There are no available roles for the selected Practice and Group.'),
	roleDropdown: BASE_COMBO_BOX.find('input').withAttribute('placeholder', 'Select Resource Role'),
	roleDropDownItem: {
		labeled: (itemLabel: string) => BASE_COMBO_BOX.find((descendant) => {
			const tagName = descendant?.tagName.toLowerCase();
			let comboboxItem;
			if (tagName === 'lightning-base-combobox-item') {
				comboboxItem = descendant.shadowRoot.querySelector(`span[title="${itemLabel}"]`);
			}

			return comboboxItem;
		},
		{ itemLabel }),

	},
	rateItem: {
		number: (selectIdx: number) => ({
			radioButton: RATE_ITEM_ROWS.find('tr').filter((node: Element) => node.hasAttribute('data-row-key-value'))
				.nth(selectIdx - 1)
				.child(1)
				.findWebComponent('lightning-primitive-cell-checkbox')
				.find('label')
				.child(0),
		}),
	},
};

export default ResourceRoleDialog;
