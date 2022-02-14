/* global $A */

({
	/**
	 * component init
	 * @param {component, event, helper} aura attributes
	 * @return {} Nothing
	 */
	doInit: function(component) {
		const action = component.get('c.copyAsTemplate');
		action.setParams({ recordId: component.get('v.recordId') });
		action.setCallback(this, (response) => {
			const state = response.getState();
			if (state === 'SUCCESS') {
				component.set('v.isButtonActive', false);
				component.set('v.Message', 'Copy is completed successfully.');
			} else {
				const errors = response.getError();
				component.set('v.isButtonActive', false);
				component.set('v.Message', 'An error occurred: ');
				component.set('v.errorMessage', errors[0].message);
			}
		});
		$A.enqueueAction(action);
	},
	/**
	 * component terminate.
	 * @param {component, event, helper} aura attributes
	 * @return {} Nothing
	 */
	doneRendering: function() {
		$A.get('e.force:closeQuickAction').fire();
	},
});
