import {
	LightningElement, track, api, wire,
} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import retrieveQuoteTemplateDetails from '@salesforce/apex/CreateQuoteFromTemplateController.retrieveQuoteTemplateDetails';
import computeNewEndDate from '@salesforce/apex/CreateQuoteFromTemplateController.computeNewEndDate';
import getOpportunityDetails from '@salesforce/apex/CreateQuoteFromTemplateController.getOpportunityDetails';
import { CloseActionScreenEvent } from 'lightning/actions';
import log from 'c/log';

export default class CreateQuoteFromTemplate extends NavigationMixin(LightningElement) {
	@api recordId;
	@track selectedTemplate;
	@track selectedTemplateId = null;
	@track serviceStartDate;
	@track serviceEndDate;
	@track quoteName;
	@track accountId;
	@track opportunityId;
	@track timePeriod;
	@track timePeriodsAlignment;
	@track timePeriodsGroupMethod;
	@track rateCardId;
	@track practice;
	@track group;
	@track marginPercent;
	@track priceUOM;
	@track profitAmount;
	@track quoteDate;
	@track totalAmount;
	@track totalCost;

	quoteId;

	@wire(getOpportunityDetails, { opportunityId: '$recordId' })
	wireOppData({ data, error }) {
		if (data) {
			this.accountId = data.AccountId;
			this.opportunityId = data.Id;
		} else if (error) {
			log(error);
		}
	}

	onTemplateSelection(event) {
		this.selectedTemplateId = event.detail.value;
		retrieveQuoteTemplateDetails({ selectedTemplateId: this.selectedTemplateId.toString() })
			.then((result) => {
				this.selectedTemplate = result;
				this.quoteName = result.Name;
				this.serviceStartDate = result.ServiceStartDate__c;
				this.serviceEndDate = result.ServiceEndDate__c;
				this.accountId = result.AccountId__c;
				this.opportunityId = result.OpportunityId__c;
				this.timePeriod = result.TimePeriod__c;
				this.timePeriodsAlignment = result.TimePeriodsAlignment__c;
				this.timePeriodsGroupMethod = result.TimePeriodsGroupMethod__c;
				this.rateCardId = result.RateCardId__c;
				const marginPercentUnrounded = result.MarginPercent__c;
				this.marginPercent = Math.round(marginPercentUnrounded * 100) / 100;
				this.priceUOM = result.PriceUOM__c;
				this.profitAmount = result.ProfitAmount__c;
				this.quoteDate = result.QuoteDate__c;
				this.totalAmount = result.TotalAmount__c;
				this.totalCost = result.TotalCost__c;
				this.practice = result.Practice__c;
				this.group = result.Group__c;
			})
			.catch((error) => {
				this.error = error;
			});
	}

	async onStartDateChange(event) {
		const newStartDate = event.detail.value;

		const newEndDate = await computeNewEndDate({
			selectedTemplateId: this.selectedTemplateId.toString(),
			newStartDate,
		});

		this.serviceEndDate = JSON.parse(newEndDate);
	}

	handleError(event) {
		const detailedMessage = event.detail?.data?.output?.message;
		const shortMessage = event.detail?.message;

		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Failed to Create Quote',
				message: JSON.stringify(detailedMessage || shortMessage),
				variant: 'error',
			}),
		);
	}

	handleSuccess(event) {
		this.quoteId = event.detail.id.toString();
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.quoteId,
				objectApiName: 'Quote__c',
				actionName: 'view',
			},
		});
	}

	cancel() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}
