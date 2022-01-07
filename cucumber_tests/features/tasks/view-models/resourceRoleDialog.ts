import { Component } from '../../support/componentSelector';

const COMPONENT = Component.named('resource-role-dialog');

const ResourceRoleDialog = {
	cancelButton: COMPONENT.findComponent('lightning-button').child('button').withExactText('Cancel'),
	component: COMPONENT,
	noRolesAvailableText: COMPONENT.child('div').withExactText('There are no available roles for the selected Practice and Group.'),
};

export default ResourceRoleDialog;
