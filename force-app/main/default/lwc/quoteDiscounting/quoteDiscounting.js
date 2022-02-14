import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import DiscountCustomModal from '@salesforce/resourceUrl/DiscountCustomModal';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CURRENCY from '@salesforce/i18n/currency';
import { reduceErrors } from 'c/sparkUtils';

import DiscountbyCategory from '@salesforce/label/c.DiscountbyCategory';
import DiscountatQuoteLevel from '@salesforce/label/c.DiscountatQuoteLevel';
import DiscountSuccessMessage from '@salesforce/label/c.DiscountSuccessMessage';
import Category from '@salesforce/label/c.Category';
import CurrentAmount from '@salesforce/label/c.CurrentAmount';
import CurrentMargin from '@salesforce/label/c.CurrentMargin';
import Cost from '@salesforce/label/c.Cost';
import DiscountAmount from '@salesforce/label/c.DiscountAmount';
import NewAmount from '@salesforce/label/c.NewAmount';
import NewMargin from '@salesforce/label/c.NewMargin';
import DiscountPercent from '@salesforce/label/c.DiscountPercent';
import CurrentDiscount from '@salesforce/label/c.CurrentDiscount';

import { Discount } from 'c/constantUtil';

export default class QuoteDiscounting extends LightningElement {
	@api recordId;
	rendered;
	@track laborRecord = {};
	@track addonAmount = {};
	@track totalRecord = {};
	@track quoteTotal = {};

	_componentState;
	totalState;
	currency = CURRENCY;
	columnlabels = [Category, CurrentAmount, CurrentMargin, Cost, DiscountPercent, DiscountAmount, NewAmount, NewMargin];
	quoteColumnlabels = [Category, CurrentAmount, CurrentDiscount, CurrentMargin, DiscountPercent, DiscountAmount, NewAmount, NewMargin];
	disableLaborDiscounts = false;
	disableAddonDiscounts = false;
	disableQuoteDiscounts = false;
	types = {
		DISCOUNT_PERCENT: Discount.DISCOUNT_PERCENT,
		DISCOUNT_AMOUNT: Discount.DISCOUNT_AMOUNT,
	}

	labels ={
		DiscountbyCategory,
		DiscountatQuoteLevel,
	}

	closeAction() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	@api renderedCallback() {
		loadStyle(this, DiscountCustomModal);

		if (this.recordId && !this.rendered) {
			this.rendered = true;
			this._componentState = this.template.querySelector('.component-state');
			this._componentState.publish({ key: 'deselect' });
			this.totalState = this.template.querySelector('.quote-total-state');
			this.totalState.getNamedRangeTotalDetails(this.recordId).then(() => {
				this.laborRecord = this.totalState.laborRecord;
				this.addonAmount = this.totalState.addonAmount;
				this.quoteTotal = this.totalState.quoteTotal;
				this.totalRecord = this.totalState.totalRecord;
				this.disableDiscountFields();
			});
		}
	}

	recalculateDiscount(event) {
		this.totalState.applyDiscount(event);
		this.laborRecord = this.totalState.laborRecord;
		this.addonAmount = this.totalState.addonAmount;
		this.quoteTotal = this.totalState.quoteTotal;
		this.totalRecord = this.totalState.totalRecord;
		this.disableDiscountFields();
	}

	disableDiscountFields() {
		if (this.laborRecord.CurrentAmount === 0) {
			this.disableLaborDiscounts = true;
		}

		if (this.addonAmount.CurrentAmount === 0) {
			this.disableAddonDiscounts = true;
		}

		if (this.quoteTotal.CurrentAmount === 0) {
			this.disableQuoteDiscounts = true;
		}
	}

	async saveAction() {
		try {
			await this.totalState.saveTotals();
			this.closeAction();
			getRecordNotifyChange([{ recordId: this.recordId }]);
			this.showSuccessToast('Success', DiscountSuccessMessage, 'success');
		} catch (e) {
			this.notifyError(e);
		}
	}

	notifyError(error) {
		this.showNotification('Error', error.message, 'error');
	}

	showNotification(title, message, variant) {
		const evt = new ShowToastEvent({
			title,
			message: reduceErrors(message).join(', '),
			variant,
		});

		this.dispatchEvent(evt);
	}

	showSuccessToast(title, message, variant) {
		const event = new ShowToastEvent({
			title,
			message,
			variant,
			mode: 'dismissable',
		});

		this.dispatchEvent(event);
	}
}
