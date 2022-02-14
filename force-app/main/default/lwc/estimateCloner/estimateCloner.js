import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createEstimateClone from '@salesforce/apex/EstimateCloner.createEstimateClone';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
	'Estimate__c.Name',
];

export default class EstimateCloner extends NavigationMixin(LightningElement) {
	@api recordId;
	success='Success';
	successTitle='Estimate cloned successfully';
	errorMsg='ERROR';
	errorTitle='There is a problem in Estimate Creation.'
	clonedEstimateName;
	error;

	closeAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	wiredData({ error, data }) {
		if (data) {
			this.clonedEstimateName = data.fields.Name.value;
		} else if (error) {
			this.error = error;
		}
	}

	handleChange(event) {
		this.clonedEstimateName = event.target.value;
	}

	async cloneEstimate() {
		const result = await createEstimateClone({ estimateId: this.recordId, estimateName: this.clonedEstimateName });
		if (result) {
			this.successTitle = `${this.clonedEstimateName} cloned Successfully`;
			this.showNotification(this.successTitle, this.success, 'success');
			this.navigateToView(result, 'Estimate__c');
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

	showNotification(title, message, variant) {
		const evt = new ShowToastEvent({
			title,
			message,
			variant,
		});

		this.dispatchEvent(evt);
	}
}
