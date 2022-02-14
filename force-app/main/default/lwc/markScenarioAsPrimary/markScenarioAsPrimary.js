import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import QuoteObject from '@salesforce/schema/Quote__c';
import log from 'c/log';
import { reduceErrors } from 'c/sparkUtils';

import cloneScenarioToPrimaryQuote from '@salesforce/apex/MakeScenarioPrimaryController.cloneScenarioToPrimaryQuote';

// labels
import LABEL_MAKE_SCENARIO_PRIMARY_SUCCESS from '@salesforce/label/c.MakeScenarioSuccessMessage';
import LABEL_MAKE_SCENARIO_PRIMARY_ERROR from '@salesforce/label/c.MakeScenarioErrorMessage';

export default class MarkScenarioAsPrimary extends NavigationMixin(LightningElement) {
	@api recordId;
	quoteId;
	quoteObjectApiName = QuoteObject;
	success='SUCCESS';
	successTitle=LABEL_MAKE_SCENARIO_PRIMARY_SUCCESS;
	errorMsg='ERROR';
	errorTitle=LABEL_MAKE_SCENARIO_PRIMARY_ERROR;

	@api invoke() {
		this.cloneScenario(this.recordId);
	}

	async cloneScenario(scenarioRecordId) {
		try {
			const clonedQuoteId = await cloneScenarioToPrimaryQuote({ scenarioId: scenarioRecordId });
			this.quoteId = clonedQuoteId;
			log(this.quoteId);
			this.showNotification(this.successTitle, this.success, 'success');
			setTimeout(this.navigateToView(this.quoteId, this.quoteObjectApiName), 3000);
		} catch (e) {
			log(e);
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
			message: reduceErrors(message).join(', '),
			variant,
		});

		this.dispatchEvent(evt);
	}
}
