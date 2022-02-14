import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import getServiceRecommendations from '@salesforce/apex/ServiceRecommendationsController.getServiceRecommendations';
import addServiceToOpportunity from '@salesforce/apex/ServiceRecommendationsController.addServiceToOpportunity';
import log from 'c/log';

// labels
import LABEL_ADD from '@salesforce/label/c.Add';
import LABEL_ADD_SERVICE_RECOMMENDATIONS_SUCCESS from '@salesforce/label/c.AddServiceRecommendationsSuccess';
import LABEL_ADD_SERVICE_RECOMMENDATIONS_TITLE from '@salesforce/label/c.AddServiceRecommendationsTitle';
import LABEL_CLOSE_BUTTON from '@salesforce/label/c.CloseButton';
import LABEL_NO_FURTHER_SERVICE_RECOMMENDATIONS from '@salesforce/label/c.NoFurtherServiceRecommendations';
import LABEL_NO_SERVICE_RECOMMENDATIONS from '@salesforce/label/c.NoServiceRecommendations';
import LABEL_PRODUCT from '@salesforce/label/c.Product';
import LABEL_SERVICE from '@salesforce/label/c.Service';
import LABEL_SERVICE_RECOMMENDATIONS from '@salesforce/label/c.ServiceRecommendations';

export default class ServiceRecommendations extends NavigationMixin(LightningElement) {
	@track serviceRecommendations = [];
	@track serviceRecommendationsByServiceId = [];
	@track loading = false;
	@track hasServiceRecommendations = false;
	@track isAlreadyAdded = false;
	currentPageReference = null;
	urlStateParameters = null;
	opportunityId = null;
	serviceId = null;
	render = null;

	LABEL_ADD = LABEL_ADD;
	LABEL_CLOSE_BUTTON = LABEL_CLOSE_BUTTON;
	LABEL_NO_FURTHER_SERVICE_RECOMMENDATIONS = LABEL_NO_FURTHER_SERVICE_RECOMMENDATIONS;
	LABEL_NO_SERVICE_RECOMMENDATIONS = LABEL_NO_SERVICE_RECOMMENDATIONS;
	LABEL_PRODUCT = LABEL_PRODUCT;
	LABEL_SERVICE = LABEL_SERVICE;
	LABEL_SERVICE_RECOMMENDATIONS = LABEL_SERVICE_RECOMMENDATIONS;

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.urlStateParameters = currentPageReference.state;
			const { attributes } = currentPageReference;
			this.opportunityId = this.urlStateParameters.recordId || attributes.recordId || null;
		}
	}

	async connectedCallback() {
		this.refreshServiceRecommendations();
	}

	disconnectedCallback() {
		this.navigateToView(this.opportunityId, OPPORTUNITY_OBJECT);

		if (this.isAlreadyAdded) {
			this.template.querySelector('c-message-service').forceRefreshView();
		}
	}

	async refreshServiceRecommendations() {
		this.loading = true;

		try {
			getServiceRecommendations({ opportunityId: this.opportunityId }).then((result) => {
				this.loading = false;
				this.rerender();
				this.serviceRecommendations = Object.values(result);
				this.serviceRecommendationsByServiceId = result;
				this.hasServiceRecommendations = this.serviceRecommendations && this.serviceRecommendations.length > 0;
			});
		} catch (error) {
			log(error);
		}
	}

	handleCloseAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
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

	handleClick(event) {
		const targetId = event?.currentTarget?.id || '';
		const serviceId = targetId.split('-')[0]; // service id is appended with some SFDC text to ensure it's a unique id (e.g.id-random number)
		const { product } = this.serviceRecommendationsByServiceId[serviceId];
		this.loading = true;
		// make api call to save
		addServiceToOpportunity({ opportunityId: this.opportunityId, serviceId, productId: product.Id })
			.then((response) => {
				if (!response.success)	{
					this.showNotification(LABEL_ADD_SERVICE_RECOMMENDATIONS_TITLE, response.errorMsg, 'error');
				} else {
					this.showNotification(LABEL_ADD_SERVICE_RECOMMENDATIONS_TITLE, LABEL_ADD_SERVICE_RECOMMENDATIONS_SUCCESS, 'success');
				}

				this.isAlreadyAdded = true;
				this.refreshServiceRecommendations();
			})
			.catch((error) => {
				log(error);
			});
	}

	/**
	 * Forces a DOM rerender.
	 */
	rerender() {
		this.render = Date.now();
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
