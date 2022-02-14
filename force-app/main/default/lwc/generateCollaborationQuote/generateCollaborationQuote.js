import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import SOBJECT_QUOTE from '@salesforce/schema/Quote__c';
import createCollaborationQuote from '@salesforce/apex/QuoteCollaborationController.createCollaborationQuote';

export default class GenerateCollaborationQuote extends NavigationMixin(LightningElement) {
	currentPageReference = null;
	urlStateParameters = null;
	userId = null;
	quoteId = null;

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.urlStateParameters = currentPageReference.state;
			this.setParameters();
		}
	}

	setParameters() {
		this.userId = this.urlStateParameters.c__userId || null;
		this.quoteId = this.urlStateParameters.c__quoteId || null;
	}

	async connectedCallback() {
		const clonedQuoteId = await createCollaborationQuote({ userId: this.userId, sourceQuoteId: this.quoteId });
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: clonedQuoteId,
				objectApiName: SOBJECT_QUOTE.objectApiName,
				actionName: 'view',
			},
		});
	}
}
