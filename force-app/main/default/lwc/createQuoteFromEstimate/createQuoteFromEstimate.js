import {
	LightningElement, track, api, wire,
} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import errorSavingNotificationTitleLabel from '@salesforce/label/c.ErrorSavingNotificationTitle';
import QUOTE_OBJECT from '@salesforce/schema/Quote__c';
import NAME from '@salesforce/schema/Quote__c.Name';
import IS_PRIMARY from '@salesforce/schema/Quote__c.IsPrimary__c';
import ACCOUNT_ID from '@salesforce/schema/Quote__c.AccountId__c';
import DESCRIPTION from '@salesforce/schema/Quote__c.Description__c';
import OPPORTUNITY_ID from '@salesforce/schema/Quote__c.OpportunityId__c';
import SERVICE_START_DATE from '@salesforce/schema/Quote__c.ServiceStartDate__c';
import RATE_CARD_ID from '@salesforce/schema/Quote__c.RateCardId__c';
import SERVICE_END_DATE from '@salesforce/schema/Quote__c.ServiceEndDate__c';
import PRACTICE from '@salesforce/schema/Quote__c.Practice__c';
import TIME_PERIOD from '@salesforce/schema/Quote__c.TimePeriod__c';
import GROUP from '@salesforce/schema/Quote__c.Group__c';
import TIME_PERIODS_GROUP_METHOD from '@salesforce/schema/Quote__c.TimePeriodsGroupMethod__c';
import STATUS from '@salesforce/schema/Quote__c.Status__c';
import TIME_PERIODS_ALIGNMENT from '@salesforce/schema/Quote__c.TimePeriodsAlignment__c';

import getEstimateDetails from '@salesforce/apex/CreateQuoteFromEstimateController.getEstimateDetails';
import getResourceRoleData from '@salesforce/apex/CreateQuoteFromEstimateController.getResourceRoleData';
import createQuote from '@salesforce/apex/CreateQuoteFromEstimateController.createQuote';
import getServiceEndDate from '@salesforce/apex/CreateQuoteFromEstimateController.getServiceEndDate';
import log from 'c/log';
import { reduceErrors } from 'c/sparkUtils';

export default class CreateQuoteFromEstimate extends NavigationMixin(LightningElement) {
	@api recordId;
	@track quote = {};
	@track isQuoteForm = true;
	@track resourceRoleData;
	@track resourceSelections = [];
	@track quoteObjectAPIName = QUOTE_OBJECT.objectApiName;
	@track quoteFields ={
		name: NAME.fieldApiName,
		isPrimary: IS_PRIMARY.fieldApiName,
		accountId: ACCOUNT_ID.fieldApiName,
		description: DESCRIPTION.fieldApiName,
		opportunityId: OPPORTUNITY_ID.fieldApiName,
		serviceStartDate: SERVICE_START_DATE.fieldApiName,
		rateCardId: RATE_CARD_ID.fieldApiName,
		serviceEndDate: SERVICE_END_DATE.fieldApiName,
		practice: PRACTICE.fieldApiName,
		timePeriod: TIME_PERIOD.fieldApiName,
		group: GROUP.fieldApiName,
		timePeriodsGroupMethod: TIME_PERIODS_GROUP_METHOD.fieldApiName,
		status: STATUS.fieldApiName,
		timePeriodsAlignment: TIME_PERIODS_ALIGNMENT.fieldApiName,
	}
	labels = {
		errorSavingNotificationTitle: errorSavingNotificationTitleLabel,
	};
	@wire(getEstimateDetails, { estimateId: '$recordId' })
	wireOppData({ data, error }) {
		if (data) {
			this.quote = { ...data };
		} else if (error) {
			log(error);
		}
	}

	async onChange(event) {
		try {
			this.quote[event.target.name] = event.target.value;
			const fieldName = event.target.name;
			if (fieldName === 'serviceStartDate') {
				const endDateArgs = {
					timePeriods: this.quote.timePeriod,
					calendarAlignment: this.quote.timePeriodsAlignment,
					serviceStartDate: event.target.value,
				};

				const [endDate] = await Promise.all([getServiceEndDate({
					estimateId: this.recordId,
					endDateArgs,
				})]);

				this.quote.serviceEndDate = endDate;
			}
		} catch (error) {
			log(error);
		}
	}

	async handleNext() {
		try {
			const isQuoteValid = [...this.template.querySelectorAll('lightning-input-field')]
				.reduce((validSoFar, inputField) => {
					const validity = inputField.reportValidity();
					return validSoFar && validity;
				}, true);

			if (isQuoteValid) {
				this.isQuoteForm = false;
				const [resourceData] = await Promise.all([getResourceRoleData({ estimateId: this.recordId, rateCardId: this.quote.rateCardId })]);
				this.resourceRoleData = resourceData;
				Object.keys(resourceData).forEach((key) => {
					const options = [];
					const resourceDetail = resourceData[key];

					Object.keys(resourceDetail.skillMap).forEach((skillKey) => {
						options.push({ label: skillKey, value: skillKey });
					});

					const role = {
						role: resourceDetail.resourceRoleName,
						Id: key,
						skillLevels: options,
						locations: this.getResourceLocations(key),
						skillLevel: resourceDetail.defaultSkill,
						location: resourceDetail.defaultLocation,
						noSkill: !resourceDetail.defaultSkill,
						sequence: resourceDetail.sequence,
					};

					this.resourceSelections.push(role);
				});

				this.resourceSelections.sort((a, b) => a.sequence - b.sequence);
			}
		} catch (error) {
			log(error);
		}
	}

	getResourceLocations(key) {
		const locations = [];
		if (this.resourceRoleData[key].defaultLocation) {
			this.resourceRoleData[key].skillMap[this.resourceRoleData[key].defaultSkill].forEach((location) => {
				locations.push({ label: location, value: location });
			});
		}

		return locations;
	}

	handleSkillSelection(event) {
		const { index } = event.target.dataset;
		this.resourceSelections[index].skillLevel = event.target.value;
		this.resourceSelections[index].locations = [];
		this.resourceRoleData[this.resourceSelections[index].Id].skillMap[event.target.value].forEach((location) => {
			this.resourceSelections[index].locations.push({ label: location, value: location });
		});
		this.resourceSelections[index].noSkill = false;
	}

	handleLocationSelection(event) {
		const { index } = event.target.dataset;
		this.resourceSelections[index].location = event.target.value;
	}

	saveQuote() {
		const rolePreferences = {};
		this.resourceSelections.forEach((resourceSelection) => {
			const rolePreference = {};
			rolePreference.role = resourceSelection.role;
			rolePreference.location = resourceSelection.location;
			rolePreference.skillLevel = resourceSelection.skillLevel;
			rolePreferences[resourceSelection.Id] = rolePreference;
		});

		createQuote({ quoteDetails: JSON.stringify(this.quote), rolePreferences: JSON.stringify(rolePreferences) })
			.then((result) => {
				this.navigateToView(result, this.quoteObjectAPIName);
			})
			.catch((error) => {
				if (error.body.pageErrors.length) {
					const evt = new ShowToastEvent({
						title: this.labels.errorSavingNotificationTitle,
						message: reduceErrors(error).join(', '),
						variant: 'error',
					});

					this.dispatchEvent(evt);
				}

				log(error);
			});
	}

	navigateToView(recordId, objectName) {
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId,
				objectApiName: objectName,
				actionName: 'view',
			},
		});
	}

	handleCancel() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}
