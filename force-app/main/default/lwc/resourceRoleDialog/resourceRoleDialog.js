/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { LightningElement, api, wire } from 'lwc';
import getAllOriginalProductsForQuote from '@salesforce/apex/QuoteConfiguratorController.getAllOriginalProductsForQuote';
import getAttributesFor from '@salesforce/apex/RateCardService.getAttributesFor';
import checkIfRateCardIsExpired from '@salesforce/apex/RateCardService.checkIfRateCardIsExpired';

import LABEL_ADD_TO_QUOTE from '@salesforce/label/c.AddToQuote';
import LABEL_CANCEL from '@salesforce/label/c.CancelButton';
import LABEL_SELECT_RESOURCE_ROLE from '@salesforce/label/c.SelectResourceRole';
import LABEL_ERROR_NO_AVAILABLE_ROLES from '@salesforce/label/c.ErrorNoAvailableRoles';
import LABEL_ERROR_RATECARD_EXPIRED from '@salesforce/label/c.ErrorRateCardExpired';
import LABEL_CONTINUE from '@salesforce/label/c.Continue';

import OBJECT_RATE_CARD_ITEM from '@salesforce/schema/RateCardItem__c';
import FIELD_PRODUCT from '@salesforce/schema/RateCardItem__c.ProductId__c';
import FIELD_RATE_CARD from '@salesforce/schema/RateCardItem__c.RateCardId__c';
import FIELD_UNIT_COST from '@salesforce/schema/RateCardItem__c.UnitCost__c';
import FIELD_UNIT_PRICE from '@salesforce/schema/RateCardItem__c.UnitPrice__c';
import FIELD_MARGIN_PERCENT from '@salesforce/schema/RateCardItem__c.MarginPercent__c';
import FIELD_GROUP from '@salesforce/schema/Product2.Group__c';
import FIELD_PRACTICE from '@salesforce/schema/Product2.Practice__c';

export default class ResourceRoleDialog extends LightningElement {
	@api quote;
	@api group;
	@api practice;
	@api rateCard;
	@api selectedRole;
	@api showCloseButton;
	rateItemId = [];
	hasExpired = false;

	LABEL_ADD_TO_QUOTE = LABEL_ADD_TO_QUOTE;
	LABEL_CANCEL = LABEL_CANCEL;
	LABEL_SELECT_RESOURCE_ROLE = LABEL_SELECT_RESOURCE_ROLE;
	LABEL_ERROR_NO_AVAILABLE_ROLES = LABEL_ERROR_NO_AVAILABLE_ROLES;
	LABEL_CONTINUE = LABEL_CONTINUE;

	_messageService;
	_roleDatatable;
	queryStr;
	selectedRateItem;
	roles = [];
	sortedBy = FIELD_MARGIN_PERCENT.fieldApiName;

	@wire(checkIfRateCardIsExpired, { quoteId: '$quote' })
	rateCardStatus({ data }) {
		if (data) {
			Object.keys(data).forEach((key) => {
				if (key === 'true') {
					this.hasExpired = key;
					this.LABEL_ERROR_RATECARD_EXPIRED = LABEL_ERROR_RATECARD_EXPIRED.replace('{0}', data[key]);
				}
			});
		}
	}

	handleContinue() {
		this.hasExpired = false;
	}

	@wire(getAttributesFor, { rateCardId: '$rateCard' })
	_rateCardAttributes;

	get rateCardAttributes() {
		return this._rateCardAttributes.data;
	}

	get hasRoles() {
		return this.roles.length > 0;
	}

	get disableAddButton() {
		return !this.selectedRateItem;
	}

	get disableContinueButton() {
		return this.hasExpired;
	}

	@api
	get rateCardItemId() {
		return this.rateItemId;
	}
	set rateCardItemId(val) {
		this.rateItemId = [].concat(val); // preselect requires an array
	}

	get isAddButtonDisabled() {
		return !this.selectedRateItem;
	}

	@wire(getAllOriginalProductsForQuote, {
		quoteId: '$quote',
	})
	wiredProducts({ data }) {
		if (data) {
			this.roles = data.filter(
				(nextProduct) => (!nextProduct.isMiscellaneous),
			).map((nextProduct) => ({ label: nextProduct.name, value: nextProduct.id }));

			if (this.selectedRole) {
				this.refreshTableWithQueryString(this.selectedRole);
			}
		}
	}

	renderedCallback() {
		this._messageService = this.template.querySelector('c-message-service');
	}

	get datatableClasses() {
		let tableClass = 'role-datatable';
		if (!this.selectedRole) {
			tableClass += ' slds-hide';
		}

		return tableClass;
	}

	get showCancelButton() {
		let displayCloseBtn = true;
		if (this.showCloseButton === false) {
			// if there are no roles available for selection, allow the user to cancel out of the dialog
			displayCloseBtn = !this.hasRoles;
		}

		return displayCloseBtn;
	}

	get roleDatatable() {
		if (!this._roleDatatable) {
			this._roleDatatable = this.template.querySelector('.role-datatable');
		}

		return this._roleDatatable;
	}

	refreshTableWithQueryString(productId) {
		const fields = [
			FIELD_PRODUCT.fieldApiName,
			...(this.rateCardAttributes || []),
			FIELD_UNIT_PRICE.fieldApiName,
			FIELD_UNIT_COST.fieldApiName,
			FIELD_MARGIN_PERCENT.fieldApiName,
			'Id',
		];

		const productRFieldName = FIELD_PRODUCT.fieldApiName.replace('__c', '__r');
		this.queryStr = `SELECT ${fields.join(', ')}`
			+ ` FROM ${OBJECT_RATE_CARD_ITEM.objectApiName}`
			+ ` WHERE ${FIELD_RATE_CARD.fieldApiName} = '${this.rateCard}'`
			+ ` AND ${FIELD_PRODUCT.fieldApiName} = '${productId}'`;

		if (this.group == null) {
			this.queryStr += ` AND ${productRFieldName}.${FIELD_GROUP.fieldApiName} = NULL`;
		} else {
			this.queryStr += ` AND ${productRFieldName}.${FIELD_GROUP.fieldApiName} = '${this.group}'`;
		}

		if (this.practice == null) {
			this.queryStr += ` AND ${productRFieldName}.${FIELD_PRACTICE.fieldApiName} = NULL`;
		} else {
			this.queryStr += ` AND ${productRFieldName}.${FIELD_PRACTICE.fieldApiName} = '${this.practice}'`;
		}

		this.roleDatatable.refreshTableWithQueryString(this.queryStr);
	}

	handleRateItemSelection(event) {
		[this.selectedRateItem] = event.detail.selectedRows;
	}

	handleRoleSelection(event) {
		this.selectedRole = event.detail.value;
		this.refreshTableWithQueryString(this.selectedRole);
	}

	handleAddResource() {
		this._messageService.publish({ key: 'roleselected', value: this.selectedRateItem });
		this._messageService.notifyClose();
	}

	handleCancel() {
		this._messageService.notifyClose();
	}
}
