import { api, LightningElement } from 'lwc';
import getNamedRangeTotals from '@salesforce/apex/QuoteDiscountController.getNamedRangeTotals';
import updateAdjustments from '@salesforce/apex/QuoteDiscountController.updateAdjustments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/sparkUtils';
import {
	createBlankRecord, createQuoteRecord, loadDiscounts, processAdjustmentRecords, updateFieldValues,
} from './quoteTotalsSupport';
import { findPercentage, roundDecimals } from './quoteTotalsUtils';

export default class QuoteTotals extends LightningElement {
	@api laborRecord;
	@api addonAmount;
	@api quoteTotal;
	@api totalRecord;
	quoteId;

	@api async getNamedRangeTotalDetails(quoteId) {
		try {
			this.quoteId = quoteId;
			const response = await getNamedRangeTotals({ recordId: this.quoteId });
			if (response) {
				if (response['Labor Amount']) {
					this.laborRecord = response['Labor Amount'];
				} else {
					this.laborRecord = createBlankRecord();
				}

				if (response['Add-Ons Amount']) {
					this.addonAmount = response['Add-Ons Amount'];
				} else {
					this.addonAmount = createBlankRecord();
				}

				if (response['Quote Totals']) {
					this.quoteTotal = response['Quote Totals'];
				} else {
					this.quoteTotal = createBlankRecord();
				}

				this.totalRecord = createBlankRecord();
				loadDiscounts(this.laborRecord);
				this.recalculateTotal();
				loadDiscounts(this.addonAmount);
				this.recalculateTotal();
				loadDiscounts(this.quoteTotal);
				this.recalculateQuoteTotal();
			}
		} catch (e) {
			this.notifyError(e);
		}
	}

	@api applyDiscount(event) {
		if (event.target.name === 'Labor') {
			updateFieldValues(
				this.laborRecord,
				event.target.value,
				event.target.dataset.type,
			);
			this.recalculateTotal();
			this.recalculateQuoteTotal();
		} else if (event.target.name === 'Addon') {
			updateFieldValues(
				this.addonAmount,
				event.target.value,
				event.target.dataset.type,
			);
			this.recalculateTotal();
			this.recalculateQuoteTotal();
		} else if (event.target.name === 'QuoteTotal') {
			updateFieldValues(this.quoteTotal, event.target.value, event.target.dataset.type);
			this.recalculateTotal();
			this.recalculateQuoteTotalAfterDiscount();
		}
	}

	@api async saveTotals() {
		const records = [];
		records.push(this.laborRecord, this.addonAmount, this.quoteTotal);
		const quoteRecord = createQuoteRecord(this.quoteTotal, this.quoteId);
		await updateAdjustments({
			recordString: processAdjustmentRecords(records),
			quote: quoteRecord,
		});
		getRecordNotifyChange([{ recordId: this.quoteId }]);
	}

	recalculateTotal() {
		this.totalRecord.CurrentAmount =			+this.laborRecord.CurrentAmount + +this.addonAmount.CurrentAmount;
		this.totalRecord.Cost = +this.laborRecord.Cost + +this.addonAmount.Cost;
		this.totalRecord.NewAmount = +this.laborRecord.NewAmount + +this.addonAmount.NewAmount;
		const profit = this.totalRecord.CurrentAmount - this.totalRecord.Cost;
		if (this.totalRecord.CurrentAmount !== 0) {
			this.totalRecord.CurrentMargin = roundDecimals(
				(profit / this.totalRecord.CurrentAmount) * 100,
			);
		}

		if (this.totalRecord.NewAmount !== 0) {
			this.totalRecord.NewMargin = roundDecimals(
				((this.totalRecord.NewAmount - this.totalRecord.Cost) / this.totalRecord.NewAmount) * 100,
			);
		}

		this.totalRecord.DiscountPercent = roundDecimals(
			findPercentage(this.totalRecord.CurrentAmount, this.totalRecord.NewAmount),
		);
		this.totalRecord.DiscountAmount = this.totalRecord.CurrentAmount - this.totalRecord.NewAmount;
	}

	recalculateQuoteTotal() {
		this.quoteTotal.CurrentAmount = this.totalRecord.NewAmount;
		this.quoteTotal.CurrentMargin = this.totalRecord.NewMargin;
		this.quoteTotal.CurrentDiscount = this.totalRecord.DiscountPercent;
		this.quoteTotal.DiscountAmount = roundDecimals(
			(this.quoteTotal.CurrentAmount * this.quoteTotal.DiscountPercent) / 100,
		);
		this.quoteTotal.NewAmount = this.quoteTotal.CurrentAmount - this.quoteTotal.DiscountAmount;

		if (this.totalRecord.NewAmount !== 0) {
			this.quoteTotal.NewMargin = roundDecimals(
				((this.quoteTotal.NewAmount - this.totalRecord.Cost) / this.totalRecord.NewAmount) * 100,
			);
		}
	}

	recalculateQuoteTotalAfterDiscount() {
		this.quoteTotal.CurrentAmount = this.totalRecord.NewAmount;
		this.quoteTotal.CurrentMargin = this.totalRecord.NewMargin;
		this.quoteTotal.CurrentDiscount = this.totalRecord.DiscountPercent;
		this.quoteTotal.NewAmount = this.quoteTotal.CurrentAmount - this.quoteTotal.DiscountAmount;

		if (this.totalRecord.NewAmount !== 0) {
			this.quoteTotal.NewMargin = roundDecimals(
				((this.quoteTotal.NewAmount - this.totalRecord.Cost) / this.totalRecord.NewAmount) * 100,
			);
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
}
