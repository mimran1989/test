import { Component } from '../../support/componentSelector';

const COMPONENT = Component.named('resource-role-dialog');

const BASE_COMBO_BOX = COMPONENT.findWebComponent('lightning-combobox')
	.findWebComponent('lightning-base-combobox');

const ResourceRoleDialog = {
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
};

export default ResourceRoleDialog;
