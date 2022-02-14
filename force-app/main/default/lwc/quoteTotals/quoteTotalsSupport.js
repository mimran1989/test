/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
import AMOUNT_FIELD from '@salesforce/schema/Adjustment__c.Amount__c';
import TYPE_FIELD from '@salesforce/schema/Adjustment__c.Type__c';
import NAMED_RANGE_ID_FIELD from '@salesforce/schema/Adjustment__c.NamedRangeId__c';
import METHOD_FIELD from '@salesforce/schema/Adjustment__c.Method__c';
import APPLIED_TO_FIELD from '@salesforce/schema/Adjustment__c.AppliedTo__c';
import TOTAL_AMOUNT_BEFORE_DISCOUNT_FIELD from '@salesforce/schema/Quote__c.TotalAmountBeforeDiscount__c';
import DISCOUNT_AMOUNT_FIELD from '@salesforce/schema/Quote__c.DiscountAmount__c';
import MARGIN_PERCENT_FIELD from '@salesforce/schema/Quote__c.MarginPercent__c';
import TOTAL_AMOUNT_FIELD from '@salesforce/schema/Quote__c.TotalAmount__c';
import { Discount } from 'c/constantUtil';
import { roundDecimals } from './quoteTotalsUtils';

const createBlankRecord = () => {
	const addOn = {};
	addOn.CurrentAmount = 0;
	addOn.CurrentMargin = 0;
	addOn.CurrentDiscount = 0;
	addOn.DiscountAmount = 0;
	addOn.DiscountPercent = 0;
	addOn.NewAmount = 0;
	addOn.NewMargin = 0;
	addOn.Cost = 0;
	return addOn;
};

const updateFieldValues = (record, newValue, fieldType) => {
	const element = record;
	if (fieldType === Discount.DISCOUNT_PERCENT) {
		if (element.DiscountPercent !== newValue) {
			element.DiscountType = fieldType;
			element.DiscountAmount = roundDecimals(
				(element.CurrentAmount * newValue) / 100,
			);
			element.DiscountPercent = newValue;
			element.NewAmount = record.CurrentAmount - element.DiscountAmount;

			if (record.Cost !== 0) {
				element.NewMargin = roundDecimals(
					((element.NewAmount - element.Cost) / element.NewAmount) * 100,
				);
			}
		}
	} else if (fieldType === Discount.DISCOUNT_AMOUNT) {
		if (element.DiscountAmount !== newValue) {
			element.DiscountType = fieldType;
			element.DiscountAmount = newValue;
			element.DiscountPercent = roundDecimals(
				(newValue / record.CurrentAmount) * 100,
			);
			element.NewAmount = record.CurrentAmount - element.DiscountAmount;

			if (record.Cost !== 0) {
				element.NewMargin = roundDecimals(
					((element.NewAmount - element.Cost) / element.NewAmount) * 100,
				);
			}
		}
	}
};

const loadDiscounts = (savedRecord) => {
	const record = savedRecord;
	if (record.DiscountType === Discount.DISCOUNT_AMOUNT) {
		const savedValue = record.DiscountAmount;
		record.DiscountAmount = 0;
		updateFieldValues(record, savedValue, record.DiscountType);
	} else if (record.DiscountType === Discount.DISCOUNT_PERCENT) {
		const savedValue = record.DiscountPercent;
		record.DiscountPercent = 0;
		updateFieldValues(record, savedValue, record.DiscountType);
	}
};

const createQuoteRecord = (quoteTotal, quoteId) => {
	const quoteRecord = {};
	quoteRecord.Id = quoteId;
	quoteRecord[TOTAL_AMOUNT_BEFORE_DISCOUNT_FIELD.fieldApiName] = quoteTotal.CurrentAmount;
	quoteRecord[DISCOUNT_AMOUNT_FIELD.fieldApiName] = quoteTotal.DiscountAmount;
	quoteRecord[MARGIN_PERCENT_FIELD.fieldApiName] = quoteTotal.NewMargin;
	quoteRecord[TOTAL_AMOUNT_FIELD.fieldApiName] = quoteTotal.NewAmount;

	return quoteRecord;
};

const processAdjustmentRecords = (records) => {
	const adjustmentRecords = [];
	records.forEach((element) => {
		const adjustmentRecord = {};
		adjustmentRecord.Id = element.AdjustmentId;
		adjustmentRecord[NAMED_RANGE_ID_FIELD.fieldApiName] = element.Id;

		if (element.DiscountType === Discount.DISCOUNT_PERCENT) {
			adjustmentRecord[AMOUNT_FIELD.fieldApiName] = element.DiscountPercent;
			adjustmentRecord[TYPE_FIELD.fieldApiName] = Discount.DISCOUNT_PERCENT;
		} else if (element.DiscountType === Discount.DISCOUNT_AMOUNT) {
			adjustmentRecord[AMOUNT_FIELD.fieldApiName] = element.DiscountAmount;
			adjustmentRecord[TYPE_FIELD.fieldApiName] = Discount.DISCOUNT_AMOUNT;
		}

		adjustmentRecord[METHOD_FIELD.fieldApiName] = Discount.INITIAL;
		adjustmentRecord[APPLIED_TO_FIELD.fieldApiName] = Discount.COST;
		adjustmentRecords.push(adjustmentRecord);
	});
	return JSON.stringify(adjustmentRecords);
};

export {
	processAdjustmentRecords, createQuoteRecord, updateFieldValues, createBlankRecord,
	loadDiscounts,
};
