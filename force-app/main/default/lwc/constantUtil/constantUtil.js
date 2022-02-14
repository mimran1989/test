/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
const RateCardItem = {
	PriceUom: {
		HOURLY: 'Hourly',
		DAILY: 'Daily',
		WEEKLY: 'Weekly',
		MONTHLY: 'Monthly',
		YEARLY: 'Yearly',
	},
};

const Quote = {
	TimePeriod: {
		DAYS: 'Days',
		WEEKS: 'Weeks',
		MONTHS: 'Months',
		QUARTERS: 'Quarters',
	},
};

const AdjustmentType = {
	MARGIN_ADJUSTMENT: 'Margin Adjustment',
	REALIGN_RESOURCE: 'Realign Resource',
	REVENUE_ADJUSTMENT: 'Revenue Adjustment',
};

const OBSERVER_NAME_SFDC = 'SFDC';

const CollaborationRequest = {
	Status: {
		READY_TO_MERGE: 'Ready to Merge',
		MERGED: 'Merged',
		ACCEPTED: 'Accepted',
		ASSIGNED: 'Assigned',
	},
};

const ColumnGroup = {
	RATE_ATTRIBUTE: 0,
	PRICING_ATTRIBUTE: 1,
};

const RecordType = {
	QUOTE: 'Quote',
	COLLABORATION: 'Collaboration',
};

const ScheduleSettingFields = {
	STANDARD_DAY_HOURS: 'StandardDayHours__c',
	STANDARD_WEEK_HOURS: 'StandardWeekHours__c',
	STANDARD_MONTH_HOURS: 'StandardMonthHours__c',
	STANDARD_YEAR_HOURS: 'StandardYearHours__c',
};

const ContextMenuActions = {
	ROW_BELOW: 'row_below',
	EDIT_ROW: 'edit_row',
};

const Discount = {
	DISCOUNT_PERCENT: 'Discount Percent',
	DISCOUNT_AMOUNT: 'Discount Amount',
	INITIAL: 'Initial',
	COST: 'Cost',
};

export {
	AdjustmentType,
	CollaborationRequest,
	ColumnGroup,
	ContextMenuActions,
	Discount,
	OBSERVER_NAME_SFDC,
	Quote,
	RateCardItem,
	RecordType,
	ScheduleSettingFields,
};
