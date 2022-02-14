import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import PROPOSAL_OBJECT from '@salesforce/schema/Proposal__c';
import createProposal from '@salesforce/apex/CreateProposalController.createProposal';
import log from 'c/log';

export default class CreateProposalFromOpportunity extends NavigationMixin(LightningElement) {
	@track loading = false;

	opportunityId = null;
	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.urlStateParameters = currentPageReference.state;
			const { attributes } = currentPageReference;
			this.opportunityId = this.urlStateParameters.recordId || attributes.recordId || null;
		}
	}

	async connectedCallback() {
		this.createProposalForOpportunity();
	}

	async createProposalForOpportunity() {
		this.loading = true;

		try {
			createProposal({ opportunityId: this.opportunityId }).then((result) => {
				this.loading = false;

				if (result.success) {
					this.navigateToView(result.proposalSO.Id, PROPOSAL_OBJECT);
				} else {
					log(result.errorMsgs);
				}
			});
		} catch (error) {
			log(error);
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
}
