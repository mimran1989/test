import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import COLA_RATE_SHEET_OBJECT from '@salesforce/schema/Quote__c';
import cloneColaRateSheet from '@salesforce/apex/ColaRateSheetCloneController.cloneColaRateSheet';
import COLARATESHEET_NAME_FIELD from '@salesforce/schema/COLARateSheet__c.Name';
import COLARATESHEET_YEAR_OVER_YEAR_RATE_FIELD from '@salesforce/schema/COLARateSheet__c.YearOverYearRate__c';
import log from 'c/log';
import { reduceErrors } from 'c/sparkUtils';
import { formatLabel } from 'c/util';

import LABEL_CLONE_ERROR_MESSAGE from '@salesforce/label/c.CloneErrorMessage';
import LABEL_CLONE_SUCCESS_MESSAGE from '@salesforce/label/c.CloneSuccessMessage';
import LABEL_CANCEL_BUTTON from '@salesforce/label/c.CancelButton';
import LABEL_CLONE_BUTTON from '@salesforce/label/c.CloneButton';
import LABEL_COLA_RATE_SHEET_CLONE_HEADER from '@salesforce/label/c.ColaRateSheetCloneHeader';

export default class colaRateSheetCloner extends NavigationMixin(LightningElement) {
	@api recordId;
	success='Success';
	errorMsg='ERROR';
	successTitle;
	errorTitle;
	colaRateSheetData = {};

	LABEL_CANCEL_BUTTON = LABEL_CANCEL_BUTTON;
	LABEL_CLONE_BUTTON = LABEL_CLONE_BUTTON;
	LABEL_COLA_RATE_SHEET_CLONE_HEADER = LABEL_COLA_RATE_SHEET_CLONE_HEADER;

	COLA_RATE_SHEET_OBJECT = {
		objectApiName: COLARATESHEET_NAME_FIELD.objectApiName,
		Name: COLARATESHEET_NAME_FIELD.fieldApiName,
		yearOverYearRate: COLARATESHEET_YEAR_OVER_YEAR_RATE_FIELD.fieldApiName,
	};

	handleChange(event) {
		this.colaRateSheetData[event.target.name] = event.target.value;
	}

	async doClone() {
		try {
			const isQuoteValid = [...this.template.querySelectorAll('lightning-input-field')]
				.reduce((validSoFar, inputField) => {
					const validity = inputField.reportValidity();
					return validSoFar && validity;
				}, true);

			if (isQuoteValid) {
				const clonedRecordId = await cloneColaRateSheet({ colaRateSheetId: this.recordId, clonedRateSheetData: JSON.stringify(this.colaRateSheetData) });
				this.successTitle = formatLabel(LABEL_CLONE_SUCCESS_MESSAGE, [this.colaRateSheetData.Name]);
				this.showNotification(this.successTitle, this.success, 'success');
				this.navigateToView(clonedRecordId, COLA_RATE_SHEET_OBJECT.objectApiName);
			}
		} catch (e) {
			log(e);
			this.notifyError(e);
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

	notifyError(error) {
		this.errorTitle = formatLabel(LABEL_CLONE_ERROR_MESSAGE, [this.COLA_RATE_SHEET_OBJECT.objectApiName]);
		this.showNotification(this.errorTitle, error.message, 'error');
	}

	showNotification(title, message, variant) {
		const evt = new ShowToastEvent({
			title,
			message: reduceErrors(message).join(', '),
			variant,
		});

		this.dispatchEvent(evt);
	}

	closeAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}
