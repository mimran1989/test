import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import EstimateObject from '@salesforce/schema/Estimate__c';
import log from 'c/log';

import createEstimateFromTemplate from '@salesforce/apex/CreateEstimateController.createEstimateFromTemplate';

export default class CreateEstimateQuickAction extends NavigationMixin(LightningElement) {
	@api recordId;
	estimateId;
	success='SUCCESS';
	successTitle='Estimate created successfully';
	errorMsg='ERROR';
	errorTitle='There is a problem in Estimate Creation.';

	@api invoke() {
		createEstimateFromTemplate({ estimateTemplateId: this.recordId })
			.then((result) => {
				this.estimateId = result;
				this.showNotification(this.successTitle, this.success, 'success');
				setTimeout(this.navigateToView(this.estimateId, EstimateObject), 3000);
			})
			.catch((error) => {
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

	showNotification(title, message, variant) {
		const evt = new ShowToastEvent({
			title,
			message,
			variant,
		});

		this.dispatchEvent(evt);
	}
}
