import {
	LightningElement, api, track,
} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

import getResourceRoleData from '@salesforce/apex/ResourceDefaults.getResourceRoleData';
import saveResourceDefaults from '@salesforce/apex/ResourceDefaults.saveResourceDefaults';

import FIELD_ESTIMATE_TEMPLATE from '@salesforce/schema/ResourceDefault__c.EstimateTemplateId__c';
import FIELD_FIELD_API_NAME from '@salesforce/schema/ResourceDefault__c.FieldAPIName__c';
import FIELD_LOCATION_DISPLAY_NAME from '@salesforce/schema/RateCardItem__c.LocationDisplayName__c';
import FIELD_PRODUCT from '@salesforce/schema/ResourceDefault__c.ProductId__c';
import FIELD_SKILL_LEVEL from '@salesforce/schema/RateCardItem__c.SkillLevel__c';
import FIELD_TEXT_VALUE from '@salesforce/schema/ResourceDefault__c.TextValue__c';

import ResourceDefaultSuccessMessage from '@salesforce/label/c.ResourceDefaultSuccessMessage';
import ResourceDefaultsHeaderLabel from '@salesforce/label/c.ResourceDefaultsHeaderLabel';

export default class ResourceDefaults extends LightningElement {
	@api recordId;
	@track resourceRoleData;
	@track resourceSelections;
	rendered;
	ResourceDefaultsHeaderLabel= ResourceDefaultsHeaderLabel;

	closeAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	renderedCallback() {
		// Since resourceDefaults is opened from a lwc quick action, recordId isn't available during
		// connectedCallback() and is available after the second render. This is true for all lwc quick actions.
		if (this.recordId && !this.rendered) {
			this.rendered = true;
			this.getResourceData();
		}
	}

	async getResourceData() {
		const resourceSelections = [];
		const resourceData = await getResourceRoleData({ estimateTemplateId: this.recordId });
		this.resourceRoleData = resourceData;
		Object.keys(resourceData).forEach((key) => {
			const options = [];
			Object.keys(resourceData[key].skillLevelByLocation).forEach((skillKey) => {
				options.push({ label: skillKey, value: skillKey });
			});
			const locations = [];
			if (resourceData[key].defaultLocation) {
				resourceData[key].skillLevelByLocation[resourceData[key].defaultSkill].forEach((location) => {
					locations.push({ label: location, value: location });
				});
			}

			const role = {
				role: resourceData[key].resourceRoleName,
				Id: key,
				skillLevels: options,
				locations,
				skillLevel: resourceData[key].defaultSkill,
				location: resourceData[key].defaultLocation,
				noSkill: !resourceData[key].defaultSkill,
				resourceDefaultSkillId: resourceData[key].resourceDefaultSkillId,
				resourceDefaultLocationId: resourceData[key].resourceDefaultLocationId,
			};

			resourceSelections.push(role);
		});

		this.resourceSelections = resourceSelections;
	}

	handleSkillSelection(event) {
		const { index } = event.target.dataset;
		this.resourceSelections[index].skillLevel = event.target.value;
		this.resourceSelections[index].locations = [];
		this.resourceRoleData[this.resourceSelections[index].Id].skillLevelByLocation[event.target.value].forEach((location) => {
			this.resourceSelections[index].locations.push({ label: location, value: location });
		});
		this.resourceSelections[index].noSkill = false;
	}

	handleLocationSelection(event) {
		const { index } = event.target.dataset;
		this.resourceSelections[index].location = event.target.value;
	}

	async savePreferences() {
		try {
			const rolePreferences = [];
			this.resourceSelections.forEach((resourceSelection) => {
				this.createResourceRecords(rolePreferences, resourceSelection);
			});
			await saveResourceDefaults({ resourceDefaultRecords: JSON.stringify(rolePreferences) });
			getRecordNotifyChange([{ recordId: this.recordId }]);
			this.closeAction();
			this.template.querySelector('c-message-service').notifySuccess('Success', ResourceDefaultSuccessMessage);
		} catch (error) {
			this.template.querySelector('c-message-service').notifySingleError('Error', error.message);
		}
	}

	createResourceRecords(rolePreferences, resourceSelection) {
		const rolePreferenceSkill = {};
		rolePreferenceSkill[FIELD_PRODUCT.fieldApiName] = resourceSelection.Id;
		rolePreferenceSkill[FIELD_ESTIMATE_TEMPLATE.fieldApiName] = this.recordId;
		rolePreferenceSkill[FIELD_TEXT_VALUE.fieldApiName] = resourceSelection.skillLevel;
		rolePreferenceSkill[FIELD_FIELD_API_NAME.fieldApiName] = FIELD_SKILL_LEVEL.fieldApiName;
		rolePreferenceSkill.Id = resourceSelection.resourceDefaultSkillId;

		if (resourceSelection.skillLevel) {
			rolePreferences.push(rolePreferenceSkill);
		}

		const rolePreferenceLocation = {};
		rolePreferenceLocation[FIELD_PRODUCT.fieldApiName] = resourceSelection.Id;
		rolePreferenceLocation[FIELD_ESTIMATE_TEMPLATE.fieldApiName] = this.recordId;
		rolePreferenceLocation[FIELD_TEXT_VALUE.fieldApiName] = resourceSelection.location;
		rolePreferenceLocation[FIELD_FIELD_API_NAME.fieldApiName] = FIELD_LOCATION_DISPLAY_NAME.fieldApiName;
		rolePreferenceLocation.Id = resourceSelection.resourceDefaultLocationId;

		if (resourceSelection.location) {
			rolePreferences.push(rolePreferenceLocation);
		}
	}
}
