import { LightningElement, api, track } from 'lwc';

import cloneQuoteToScenario from '@salesforce/apex/CreateNewScenarioController.cloneQuoteToScenario';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import QUOTE_OBJECT from '@salesforce/schema/Quote__c';
import ACCOUNT_ID from '@salesforce/schema/Quote__c.AccountId__c';
import ACCOUNT_NAME from '@salesforce/schema/Quote__c.AccountId__r.Name';
import MARGIN_PERCENT from '@salesforce/schema/Quote__c.MarginPercent__c';
import TOTAL_AMOUNT from '@salesforce/schema/Quote__c.TotalAmount__c';
import getQuoteDetails from '@salesforce/apex/CreateNewScenarioController.getQuoteDetails';
import { get } from 'c/util';
import log from 'c/log';

export default class CreateScenario extends NavigationMixin(LightningElement) {
	@api recordId;
	@track quoteRecord = {};
	@api props = {
		isQuickAction: true,
		isCreate: true,
	};

	ComponentId = 'createScenario';

	quoteRecords = [];
	adjustmentType = 'Revenue Adjustment';

	showRevenue = true;
	showMargin = false;
	showRuleBased = false;
	disableCreate = false;
	loaded = false;

	revenueAdjustment;
	marginAdjustment;
	adjustmentVal;
	scenarioName;
	scenarioId;
	error;
	rendered = false;

	@api renderedCallback() {
		if (!this.rendered && this.recordId) {
			this.rendered = true;
			this.getQuoteRecordDetails();
			this._stateService = this.template.querySelector('[data-id="cs-msg-service"]');
			this._stateService.publish({ key: 'deselect' });
		}
	}

	get contentCSSClass() {
		let classes = 'slds-grid slds-wrap';
		if (this.props.isQuickAction) {
			classes += ' slds-p-around_medium';
		}

		return classes;
	}

	get adjustmentOptions() {
		if (!this.props.adjustmentOptions) {
			return [
				{ label: 'Revenue Adjustment', value: 'Revenue Adjustment' },
				{ label: 'Margin Adjustment', value: 'Margin Adjustment' },
				{ label: 'Rule-Based Adjustment', value: 'Rule-Based Adjustment' },
			];
		}

		return this.props.adjustmentOptions;
	}
	async getQuoteRecordDetails() {
		let quoteDetails;
		try {
			quoteDetails = await getQuoteDetails({ quoteId: this.recordId });
		} catch (error) {
			log(error);
		}

		if (quoteDetails) {
			const forwardSlash = '/';
			quoteDetails.forEach((quoteRecord) => {
				const quoteData = {};
				quoteData.Id = quoteRecord.Id;
				quoteData.Name = quoteRecord.Name;
				quoteData.MarginPercent__c = quoteRecord[MARGIN_PERCENT.fieldApiName] / 100;
				quoteData.AccountId__c = quoteRecord[ACCOUNT_ID.fieldApiName];
				quoteData.TotalAmount__c = quoteRecord[TOTAL_AMOUNT.fieldApiName];
				quoteData.AccountName = get(ACCOUNT_NAME.fieldApiName, quoteRecord);
				quoteData.AccountURL = forwardSlash.concat(quoteRecord[ACCOUNT_ID.fieldApiName]);
				this.quoteRecord = quoteData;
			});
		}
	}

	adjustmentChange(event) {
		const selectedAdjustment = event.detail.value;
		switch (selectedAdjustment) {
			case 'Revenue Adjustment':
				this.showMargin = false;
				this.showRuleBased = false;
				this.showRevenue = true;
				this.disableCreate = false;
				break;
			case 'Margin Adjustment':
				this.showRuleBased = false;
				this.showRevenue = false;
				this.showMargin = true;
				this.disableCreate = false;
				break;
			case 'Rule-Based Adjustment':
			case 'Realign Resource':
				this.showRevenue = false;
				this.showMargin = false;
				this.showRuleBased = true;
				this.disableCreate = true;
				break;
			default:
				break;
		}

		this.adjustmentType = selectedAdjustment;
	}

	@api getAdjustment() {
		return {
			type: this.adjustmentType,
			value: this.adjustmentVal,
		};
	}

	scenarioNameUpdate(event) {
		this.scenarioName = event.detail.value.trim();
	}

	revenueValueUpdate(event) {
		this.revenueAdjustment = event.detail.value.trim();
		this.adjustmentVal = this.revenueAdjustment;
	}

	marginValueUpdate(event) {
		this.marginAdjustment = event.detail.value.trim();
		this.adjustmentVal = this.marginAdjustment;
	}

	handleAccountClick() {
		this.navigateToView(this.quoteRecord.AccountId__c, 'Account');
	}

	@api validate() {
		let inputElt;
		switch (this.adjustmentType) {
			case 'Revenue Adjustment':
				if (this.props.isCreate) {
					inputElt = this.template.querySelector('.scenario-name');

					if (inputElt) {
						inputElt.reportValidity();
					}
				}

				inputElt = this.template.querySelector('.revenue-adjustment');

				if (inputElt) {
					inputElt.reportValidity();
				}

				break;
			case 'Margin Adjustment':
				if (this.props.isCreate) {
					inputElt = this.template.querySelector('.scenario-name');

					if (inputElt) {
						inputElt.reportValidity();
					}
				}

				inputElt = this.template.querySelector('.margin-adjustment');

				if (inputElt) {
					inputElt.reportValidity();
				}

				break;
			default:
				break;
		}
	}

	createScenario() {
		this.validate();

		if (
			this.scenarioName !== undefined
			&& (this.revenueAdjustment !== undefined || this.marginAdjustment !== undefined)
		) {
			this.loaded = true;
			const adjustment = {};
			adjustment.type = this.adjustmentType;
			adjustment.name = this.scenarioName;
			adjustment.value = this.adjustmentVal;

			cloneQuoteToScenario({
				quoteId: this.recordId,
				adjustment: JSON.stringify(adjustment),
			})
				.then((result) => {
					this.scenarioId = result;
					this.navigateToView(this.scenarioId, QUOTE_OBJECT);
				})
				.catch((error) => {
					log(error);
				});
		}
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

	closeAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
		this.rendered = false;
	}
}
