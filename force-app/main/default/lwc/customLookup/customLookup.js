import { LightningElement, api, track } from 'lwc';
import fetchRecords from '@salesforce/apex/CustomLookupController.fetchRecords';
import fetchDefaultRecord from '@salesforce/apex/CustomLookupController.fetchDefaultRecord';

export default class CustomLookup extends LightningElement {
	@api objectName;
	@api filterField;
	@api filterCriteria;
	@api value;
	@api iconName;
	@api activityAgRecordId;
	@api level;
	@api label;
	@api placeholder;
	@api className;
	@api required = false;
	@track searchString;
	@track selectedRecord;
	@track recordsList;
	@track message;
	@track showPill = false;
	@track showSpinner = false;
	@track showDropdown = false;
	@track sObjectApiName;
	@api rateCardId;
	@api defaultRecordId;

	connectedCallback() {
		if (this.defaultRecordId !== '') {
			fetchDefaultRecord({ recordId: this.defaultRecordId, sObjectApiName: this.objectName })
				.then((result) => {
					if (result != null) {
						this.selectedRecord = result;
						this.selectedRecord.label = this.selectedRecord.Name;
						this.showPill = true;
					}
				})
				.catch((error) => {
					this.error = error;
					this.selectedRecord = {};
				});
		}
	}

	handelSelectRecordHelper() {
		this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
		const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
		searchBoxWrapper.classList.remove('slds-show');
		searchBoxWrapper.classList.add('slds-hide');
		const pillDiv = this.template.querySelector('.pillDiv');
		pillDiv.classList.remove('slds-hide');
		pillDiv.classList.add('slds-show');
	}

	searchRecords(event) {
		this.searchString = event.target.value;

		if (this.searchString) {
			this.fetchData();
		} else {
			this.showDropdown = false;
		}
	}

	@api isValid() {
		[...this.template.querySelectorAll('lightning-input')]
			.reduce((validSoFar, inputCmp) => {
				inputCmp.reportValidity();
				return validSoFar && inputCmp.checkValidity();
			}, true);
	}

	selectItem(event) {
		if (event.currentTarget.dataset.key) {
			const index = this.recordsList.findIndex(
				(x) => x.value === event.currentTarget.dataset.key,
			);

			if (index !== -1) {
				this.selectedRecord = this.recordsList[index];
				this.value = this.selectedRecord.value;
				this.showDropdown = false;
				this.showPill = true;

				const eventSelected = new CustomEvent('selected', {
					// detail contains only primitives
					detail: { recordId: this.selectedRecord.value, TaskId: this.activityAgRecordId },
				});

				this.dispatchEvent(eventSelected);
			}
		}
	}

	removeItem() {
		this.showPill = false;
		this.value = '';
		this.selectedRecord = '';
		this.searchString = '';

		const eventRemoved = new CustomEvent('selected', {
			detail: { recordId: undefined, TaskId: this.activityAgRecordId },
		});

		this.dispatchEvent(eventRemoved);
	}

	showRecords() {
		if (this.recordsList && this.searchString) {
			this.showDropdown = true;
		}
	}

	blurEvent() {
		this.showDropdown = false;
	}

	fetchData() {
		this.showSpinner = true;
		this.message = '';
		this.recordsList = [];

		const request = {
			objectName: this.objectName,
			filterField: this.filterField,
			filterCriteria: this.filterCriteria,
			searchString: this.searchString,
			value: this.value,
			hierarchylevel: this.level,
			hierarchylevelId: this.activityAgRecordId,
			rateCard: this.rateCardId,
		};

		fetchRecords({ paramMap: request })
			.then((result) => {
				if (result && result.length > 0) {
					if (this.value) {
						this.selectedRecord = [...result[0]];
						this.showPill = true;
					} else {
						this.recordsList = result;
					}
				} else {
					this.message = `No Records Found for ${this.searchString}`;
				}

				this.showSpinner = false;
			})
			.catch((error) => {
				this.message = error.message;
				this.showSpinner = false;
			});

		if (!this.value) {
			this.showDropdown = true;
		}
	}
}
