import {
	LightningElement,
	api,
} from 'lwc';
import {
	ShowToastEvent,
} from 'lightning/platformShowToastEvent';
import {
	reduceErrors,
} from 'c/sparkUtils';
import { componentNamespace, isEmpty } from 'c/util';
import log from 'c/log';

import getAllProductsForQuote from '@salesforce/apex/QuoteConfiguratorController.getAllProductsForQuote';
import getRateCardItemsForProduct from '@salesforce/apex/QuoteConfiguratorController.getAllRateCardItemsForProduct';
import getQuoteTemplate from '@salesforce/apex/QuoteConfiguratorController.getQuoteTemplate';
import getQuoteItemsForQuote from '@salesforce/apex/QuoteConfiguratorController.getQuoteItemsForQuote';
import getNamedRangesForQuote from '@salesforce/apex/QuoteConfiguratorController.getNamedRangesForQuote';

import QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD from '@salesforce/schema/QuoteItem__c.PriceMethodMarkdown__c';
import QUOTE_ITEM_UNIT_PRICE_FIELD from '@salesforce/schema/QuoteItem__c.UnitPrice__c';
import QUOTE_ITEM_UNIT_COST_FIELD from '@salesforce/schema/QuoteItem__c.UnitCost__c';
import QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD from '@salesforce/schema/QuoteItem__c.AdjustedUnitPrice__c';
import QUOTE_ITEM_PRICE_METHOD_FIELD from '@salesforce/schema/QuoteItem__c.PriceMethod__c';
import QUOTE_ITEM_MARGIN_PERCENT_FIELD from '@salesforce/schema/QuoteItem__c.MarginPercent__c';
import QUOTE_ITEM_LINE_TYPE_FIELD from '@salesforce/schema/QuoteItem__c.LineType__c';
import QUOTE_ITEM_FREQUENCY_FIELD from '@salesforce/schema/QuoteItem__c.Frequency__c';
import QUOTE_ITEM_ROLE_NAME_OVERRIDE_FIELD from '@salesforce/schema/QuoteItem__c.RoleNameOverride__c';
import QUOTE_ITEM_NET_EXTENDED_AMOUNT_FIELD from '@salesforce/schema/QuoteItem__c.NetExtendedAmount__c';
import QUOTE_ITEM_NET_EXTENDED_COST_FIELD from '@salesforce/schema/QuoteItem__c.NetExtendedCost__c';

// labels
import LABEL_ANCILLARY from '@salesforce/label/c.Ancillary';
import LABEL_DISCOUNT_PERCENT from '@salesforce/label/c.DiscountPercent';
import LABEL_FREQUENCY from '@salesforce/label/c.Frequency';
import LABEL_GRAND_TOTAL from '@salesforce/label/c.GrandTotal';
import LABEL_MARGIN_PERCENT from '@salesforce/label/c.MarginPercent';
import LABEL_PRICE_METHOD from '@salesforce/label/c.PriceMethod';
import LABEL_PRICE_METHOD_MARKDOWN from '@salesforce/label/c.PriceMethodMarkdown';
import LABEL_QUOTED_RATE from '@salesforce/label/c.QuotedRate';
import LABEL_RENAME_ADDON from '@salesforce/label/c.RenameAddon';
import LABEL_STD_COST from '@salesforce/label/c.StdCost';
import LABEL_STD_RATE from '@salesforce/label/c.StdRate';
import LABEL_TOTAL_AMOUNT from '@salesforce/label/c.TotalAmount';
import ContextMenu from './contextMenu';

const RECURRING_VALUE = {
	SUFFIX: 'ly',
	PROJECT_END: 'Project End',
	PROJECT_START: 'Project Start',
	PROJECT_PHASE_END: 'Phase End',
	CUSTOM: 'Custom',
};

const PRICE_METHOD = {
	FLAT_PRICE: 'Flat Price',
	PER_HEAD: 'Per Head',
	PERCENTAGE_OF_COST: '% of Cost',
	PERCENTAGE_OF_REVENUE: '% of Revenue',
	NON_BILLABLE: 'Non-Billable',
};

const UNIT_FREQUENCY = {
	Months: {
		Monthly: 1,
		Weekly: 4.3,
		Yearly: 12,
	},
	Quarters: {
		Quarterly: 1,
		Monthly: 0.33,
		Yearly: 4,
	},
	Weeks: {
		Weekly: 1,
		Quarterly: 13,
		Monthly: 4.3,
		Days: 0.143,
	},
	Days: {
		Yearly: 365,
		Weekly: 7,
	},
};

export default class quoteAncillaries extends LightningElement {
	@api recordId;
	namespace;
	initPromise;
	products;
	rowItems;
	rateCardsForProduct = {};
	columnMetadata;
	columnsByName;
	mainItems;
	quoteNamedRange;
	ancillaryQuoteNamedRange;
	ancillarySheetTotals = {
		revenue: 0,
		cost: 0,
	};
	quoteTemplate;
	grid;
	cellOptions = new Map();
	_componentState;
	selectedRange;
	get _quoteService() {
		return this.template.querySelector('c-quote-service');
	}

	get quoteRecordId() {
		return this.recordId;
	}

	connectedCallback() {
		this.namespace = componentNamespace(this);
	}

	async batchRender(callback) {
		await this.grid.suspendRender();
		callback();
		this.grid.resumeRender();
	}

	async updateAddonDisplayNames(rowIdx, newValue) {
		const rowItem = this.rowItems[rowIdx];
		const product = (await this.getProductsById())[rowItem.productId];
		rowItem.quoteItemSO[QUOTE_ITEM_ROLE_NAME_OVERRIDE_FIELD.fieldApiName] = newValue;
		this.grid.setDataAtCell(rowIdx, 0, `${newValue} (${product.name})`);
		this._quoteService.saveLines();
	}

	handleDeselect() {
		this.grid.deselectCell();
	}

	async updateAddon(event) {
		try {
			const {
				start,
			} = this.selectedRange;

			const selectedRow = this.rowItems[start.row];
			const newAddonName = event.detail.value;
			if (newAddonName && selectedRow?.productId) {
				this.updateAddonDisplayNames(start.row, newAddonName);
			}
		} catch (e) {
			this.toastError(e);
		}
	}

	toastError(error) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Application Exception',
				message: reduceErrors(error).join(', '),
				variant: 'error',
			}),
		);
	}
	async initGrid() {
		const data = await this.loadData(this.recordId);
		this.grid = this.template.querySelector('c-provus-grid').grid;
		this._componentState = this.template.querySelector('.component-state');
		// request the visibility of the connected components
		this._componentState.publish({
			key: 'status',
			value: {
				receiver: null,
			},
		});
		await this.grid.init(data, Object.keys(data));

		const quoteTotals = await this.updateTotals(true);
		await this.grid.setDataAtRowProp([...quoteTotals], 'adjustPricePoints');

		for (let row = 0; row < data.data.length; row++) {
			const quoteItem = this.getRowItem(row);
			this.checkNonBillableSetting(quoteItem, row);
		}

		this.updateNonBillableSetting();
	}

	async getFrequencyLOV() {
		const quoteTemplate = await this.getQuoteTemplate();

		const {
			quoteTimePeriod,
			quoteTimePeriodsGroupMethod,
		} = quoteTemplate;

		const quoteTimePeriodPrefix = quoteTimePeriod.substr(0, quoteTimePeriod.length - 1);

		const choices = new Set([
			quoteTimePeriodsGroupMethod + RECURRING_VALUE.SUFFIX,
			quoteTimePeriodPrefix + RECURRING_VALUE.SUFFIX,
			RECURRING_VALUE.PROJECT_END,
			RECURRING_VALUE.PROJECT_START,
			RECURRING_VALUE.PROJECT_PHASE_END,
			RECURRING_VALUE.CUSTOM,
		]);

		const sortedChoices = [...choices].sort();
		sortedChoices.unshift(null);
		return sortedChoices;
	}

	static getPriceMethodLOV() {
		const sortedPriceMethod = Object.values(PRICE_METHOD).sort();
		return [null, ...sortedPriceMethod];
	}

	async loadData() {
		return {
			afterChange: (...args) => this.onChange(...args),
			colWidth: [200],
			className: 'slds-table',
			startRows: 1,
			minSpareRows: 2,
			licenseKey: 'non-commercial-and-evaluation',
			data: await this.getQuoteItems(),
			columns: await this.getColumnMetadata(),
			colHeaders: true,
			rowHeaders: true,
			nestedHeaders: await this.getColumnHeaders(),
			search: true,
			beforeRemoveRow: (...args) => this.onRemoveRows(...args),
			contextMenu: this.buildContextMenuItems(),
		};
	}

	buildContextMenuItems() {
		return {
			items: {
				rename_addon: {
					...ContextMenu.items.rename_addon,
					callback: (...args) => this.handleOpenRoleDialog(...args),
				},
				remove_row: {
					...ContextMenu.items.remove_row,
				},
			},
		};
	}

	onRemoveRows(startIdx, numberOfRows, deletedRows) {
		const deletePromises = [];
		deletedRows.forEach((rowIdx) => {
			const quoteItem = this.rowItems[rowIdx];
			if (quoteItem && !isEmpty(quoteItem.id)) {
				deletePromises.push(this._quoteService.deleteQuoteItem(quoteItem));
			}

			delete this.rowItems[rowIdx];
		});

		this.rowItems = this.rowItems.filter((element) => !!element);

		const quoteTotals = this.updateTotals(false);
		quoteTotals.then((newTotals) => {
			this.grid.setDataAtRowProp([...newTotals], 'adjustPricePoints');
		});

		return Promise.all(deletePromises).catch((e) => {
			log('Failed to delete line items.');
			log(e);
		});
	}

	handleOpenRoleDialog(action, phaseRange) {
		this.modalAction = action;
		[this.selectedRange] = phaseRange;

		const dialogServicePayload = {
			method: 'bodyModalLarge',
			config: {
				auraId: 'rename-addon-dialog',
				headerLabel: LABEL_RENAME_ADDON,
				component: `${this.namespace}:renameAddOn`,
				componentParams: {
					quote: this.recordId,
				},
			},
		};

		this._componentState.dialogService(dialogServicePayload);
	}
	async updateAncillaryNamedRanges(newSheetTotals, deltaRevenue, deltaCost) {
		const quoteAncillaryNamedRange = await this.getOrCreateAncillaryQuoteNamedRange();

		const {
			relatedTotal,
		} = quoteAncillaryNamedRange;

		relatedTotal.totalAmount = newSheetTotals.revenue;
		relatedTotal.totalCost = newSheetTotals.cost;
		relatedTotal.marginPercent = quoteAncillaries.percentDifference(
			relatedTotal.totalAmount,
			relatedTotal.totalCost,
		);

		const quoteTotalNamedRange = await this.getOrCreateQuoteTotalNamedRange();

		const {
			relatedTotal: quoteTotalRelatedTotal,
		} = quoteTotalNamedRange;

		quoteTotalRelatedTotal.totalAmount += deltaRevenue;
		quoteTotalRelatedTotal.totalCost += deltaCost;
		quoteTotalRelatedTotal.marginPercent = quoteAncillaries.percentDifference(
			quoteTotalRelatedTotal.totalAmount,
			quoteTotalRelatedTotal.totalCost,
		);
		this._quoteService.saveNamedRanges();
	}

	async updateTotals(init) {
		const periodGroups = await this.getPeriodGroups();
		const quoteItems = await this.getQuoteItems();
		const data = [];
		const newSheetTotals = { cost: 0, revenue: 0 };
		for (let i = 0; i < quoteItems.length; i++) {
			const quoteItem = quoteItems[i];
			let periodCounter = 0;
			let totalRevenue = 0;
			let totalCost = 0;
			const periodGroupIds = Object.keys(periodGroups);
			for (let j = 0; j < periodGroupIds.length; j++) {
				const groupId = periodGroupIds[j];
				const periods = periodGroups[groupId];
				let periodGroupRevenue = 0;
				for (let k = 0; k < periods.length; k++) {
					const period = periods[k];
					const periodToken = `${periodCounter + 1}`.padStart(3, '0');
					const periodQty = quoteItem[periodToken] || 0;
					const adjustedUnitPrice = quoteItem[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName];
					const revenue = period.term * periodQty * adjustedUnitPrice;
					const cost = (parseFloat(quoteItem[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]) || 0) * periodQty * period.term;
					totalRevenue += revenue;
					periodGroupRevenue += revenue;
					periodCounter += 1;
					newSheetTotals.revenue += revenue;
					newSheetTotals.cost += cost;
					totalCost += cost;
				}

				data.push([i, `NamedRange__${groupId}__mdt`, periodGroupRevenue]);
			}

			data.push([i, 'NamedRange__GrandTotal__mdt', totalRevenue]);
			const quoteSOItem = this.getRowItem(i);
			quoteSOItem.quoteItemSO[QUOTE_ITEM_NET_EXTENDED_AMOUNT_FIELD.fieldApiName] = totalRevenue;
			quoteSOItem.quoteItemSO[QUOTE_ITEM_NET_EXTENDED_COST_FIELD.fieldApiName] = totalCost;
		}

		const deltaRevenue = newSheetTotals.revenue - this.ancillarySheetTotals.revenue;
		const deltaCost = newSheetTotals.cost - this.ancillarySheetTotals.cost;
		this.ancillarySheetTotals = newSheetTotals;

		if (init === false) {
			this.updateAncillaryNamedRanges(newSheetTotals, deltaRevenue, deltaCost);
		}

		return data;
	}

	async getOrCreateAncillaryQuoteNamedRange() {
		if (!this.ancillaryQuoteNamedRange) {
			const namedRanges = await this.getNamedRanges();

			const ancillaryQuoteNamedRangeDO = (namedRanges).filter(
				(namedRange) => namedRange.type === 'Quote Ancillaries',
			);

			if (ancillaryQuoteNamedRangeDO.length) {
				[this.ancillaryQuoteNamedRange] = Provus.NamedRanges.for([ancillaryQuoteNamedRangeDO[0]]);
			} else {
				this.ancillaryQuoteNamedRange = Provus.NamedRange.for(Provus.NamedRange.newDO({
					name: 'Add-Ons Amount',
					quoteId: this.recordId,
					type: 'Quote Ancillaries',
				}));
			}
		}

		return this.ancillaryQuoteNamedRange;
	}

	async getOrCreateQuoteTotalNamedRange() {
		if (!this.quoteNamedRange) {
			const namedRanges = await this.getNamedRanges();

			const quoteNamedRangeDO = (namedRanges).filter(
				(namedRange) => namedRange.type === 'Quote',
			);

			if (quoteNamedRangeDO.length) {
				[this.quoteNamedRange] = Provus.NamedRanges.for([quoteNamedRangeDO[0]]);
			} else {
				this.quoteNamedRange = Provus.NamedRange.for(Provus.NamedRange.newDO({
					name: 'Quote Totals',
					quoteId: this.recordId,
					type: 'Quote',
				}));
			}
		}

		return this.quoteNamedRange;
	}

	async getNamedRanges() {
		if (!this.namedRanges) {
			const results = await getNamedRangesForQuote({
				quoteId: this.recordId,
			});

			if (results) {
				this.namedRanges = JSON.parse(results);
			}
		}

		return this.namedRanges;
	}

	async getQuoteItems() {
		if (!this.rowItems) {
			const quoteItems = await getQuoteItemsForQuote({
				quoteId: this.recordId,
			});

			this.rowItems = Provus.QuoteItems.for(JSON.parse(quoteItems)).filter(
				(quotItem) => quotItem.isMiscellaneous === true,
			);
		}

		const productsById = await this.getProductsById();
		return this.rowItems.map((rowItem) => ({
			...rowItem.elementDO.quoteItemSO,
			...rowItem.elementDO.periodValueMap,
			baseAdjustmentAmount: rowItem.elementDO.adjustment.amount,
			ProductName: productsById[rowItem.productId]?.name,
		}));
	}

	static newQuoteItemDO(row) {
		const quoteItemSO = {};
		quoteItemSO[QUOTE_ITEM_LINE_TYPE_FIELD.fieldApiName] = 'Miscellaneous';

		return {
			lineSequence: 100000 + parseInt(row, 10),
			periodValueMap: {},
			quoteItemSO,
			adjustment: {
				amount: 0,
			},
			isMiscellaneous: true,
		};
	}

	async onChange(changes, context) {
		if (changes && context !== 'adjustPricePoints' && context !== 'loadData') {
			const data = [];
			for (let i = 0; i < changes.length; i++) {
				const [row, prop, oldValue, newValue] = changes[i];
				if (oldValue !== newValue) {
					let quoteItem = this.getRowItem(row);
					const columnsByName = await this.getColumnsByName();
					const column = columnsByName[prop];
					if (!quoteItem) {
						quoteItem = Provus.QuoteItem.for(quoteAncillaries.newQuoteItemDO(row + 1));
						this.rowItems[row] = quoteItem;
					}

					switch (prop) {
						case 'ProductName':
							quoteItem.ProductName = newValue;
							await this.setProductId(row);
							await this.setRateCard(row);

							if (quoteItem.rateCardItemId) {
								await this.calculatePricePoints(row);
							}

							break;
						case QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName:
							quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] = newValue;
							await this.calculatePricePoints(row);
							break;
						case QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName:
							quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName] = newValue;
							await this.calculatePricePoints(row);
							break;
						case QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName:
							quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName] = newValue;
							await this.calculatePricePoints(row);
							break;
						case 'baseAdjustmentAmount':
							quoteItem.adjustment.amount = newValue;
							quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
							await this.calculatePricePoints(row);
							break;
						case QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName:
							quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = newValue;
							quoteItem.adjustment.amount = null;
							await this.calculatePricePoints(row);
							break;
						default:
							if (column.isPeriod === true) {
								quoteItem.periodValueMap[column.data] = newValue;

								if (quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName]) {
									quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName] = RECURRING_VALUE.CUSTOM;
								}

								quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] = null;
								quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName] = null;
							}

							break;
					}

					data.push([row, QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]]);
					data.push([row, QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName]]);
					data.push([row, QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName]]);
					data.push([row, QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName]]);
					data.push([row, 'baseAdjustmentAmount', quoteItem.adjustment.amount]);
					data.push([row, QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName]]);
					data.push([row, QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]]);
					data.push([row, QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName]]);
					const columns = await this.getColumnMetadata();
					for (let j = 0; j < columns.length; j++) {
						const columnMeta = columns[j];
						if (columnMeta.isPeriod === true) {
							data.push([row, columnMeta.data, quoteItem.periodValueMap[columnMeta.data]]);
						}
					}

					// Update the Ancillary sheet totals
					const newTotals = await this.updateTotals(false);
					data.push(...newTotals);
					this.checkNonBillableSetting(quoteItem, row);
				}
			}

			this.updateNonBillableSetting();
			this.grid.setDataAtRowProp(data, 'adjustPricePoints');
		}

		this._quoteService.saveLines().catch((e) => {
			log('Failed to save lines ');
			log(e);
		});
	}

	@api
	checkNonBillableSetting(quoteItem, row) {
		const readOnlyNeeded = quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] === PRICE_METHOD.NON_BILLABLE;
		this.cellOptions.set(`${row}-6`, {
			row,
			col: 6, // discount column
			readOnly: readOnlyNeeded,
		});
		this.cellOptions.set(`${row}-7`, {
			row,
			col: 7, // quoted rate column
			readOnly: readOnlyNeeded,
		});
		return this.cellOptions;
	}

	updateNonBillableSetting() {
		const options = [];
		this.cellOptions.forEach((value) => {
			options.push(value);
		});
		this.grid.updateSettings({
			cell: options,
		});
	}

	static percentDifference(from, to) {
		const relativeDifference = from - to || 0;
		return relativeDifference === 0 ? 0 : (relativeDifference / from) * 100;
	}

	async calculatePricePoints(row) {
		const quoteItem = this.getRowItem(row);
		if (quoteItem.productId) {
			const rateCards = await this.getRateCardsFor(quoteItem.productId);
			const rateCard = rateCards && rateCards[0];
			let adjustedUnitPrice = parseFloat(rateCard[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName]);
			let discountPercentage = null;
			if (Number.isNaN(quoteItem.adjustment.amount) || Number.isNaN(parseFloat(quoteItem.adjustment.amount))) {
				quoteItem.adjustment.amount = null;
			}

			if (
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] !== null
				&& quoteItem.adjustment.amount === null
			) {
				adjustedUnitPrice = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]);
				discountPercentage = quoteAncillaries.percentDifference(
					rateCard[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName],
					adjustedUnitPrice,
				);
				discountPercentage = discountPercentage === 0 ? null : discountPercentage;
			} else if (
				quoteItem.adjustment.amount !== null
				&& quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] === null
			) {
				discountPercentage = parseFloat(quoteItem.adjustment.amount);
				adjustedUnitPrice = ((100 - discountPercentage) / 100) * rateCard[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName];
			} else if (
				quoteItem.adjustment.amount
				&& quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]
			) {
				discountPercentage = parseFloat(quoteItem.adjustment.amount);
				adjustedUnitPrice = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]);
			}

			if (!rateCard) {
				quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName] = null;
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
				quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName] = null;
				quoteItem.adjustment.amount = null;
				quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = null;
			} else {
				if (quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName] === PRICE_METHOD.NON_BILLABLE) {
					adjustedUnitPrice = 0;
					quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = 0;
					quoteItem.adjustment.amount = 0;
				}

				const marginPercent = quoteAncillaries.percentDifference(
					adjustedUnitPrice,
					parseFloat(rateCard[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]),
				);

				quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName] = parseFloat(rateCard[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName]);
				quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName] = parseFloat(rateCard[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]);
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = adjustedUnitPrice;
				quoteItem.adjustment.amount = discountPercentage;
				quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = marginPercent;
			}

			// reallocate the period quantity given the billing selection
			if (quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName] !== RECURRING_VALUE.CUSTOM) {
				const periodAllocation = await this.getPeriodAllocation(quoteItem);
				const periodKeys = Object.keys(periodAllocation);
				for (let i = 0; i < periodKeys.length; i++) {
					const periodKey = periodKeys[i];
					quoteItem.periodValueMap[periodKey] = periodAllocation[periodKey];
				}
			}
		}
	}

	async getPeriodAllocation(quoteItem) {
		const periods = await this.getQuotePeriods();
		const quoteTemplate = await this.getQuoteTemplate();

		const {
			quoteTimePeriod,
		} = quoteTemplate;

		const priceMethod = quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName];
		const markdownPercent = quoteItem.quoteItemSO[QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName];
		const frequency = quoteItem.quoteItemSO[QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName];
		const unitPrice = quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName];
		let unitFrequency = UNIT_FREQUENCY[quoteTimePeriod] ?.[frequency];
		const allocation = {};
		if (frequency === RECURRING_VALUE.PROJECT_END) {
			unitFrequency = periods.length;
		} else if (frequency === RECURRING_VALUE.PROJECT_START) {
			// set unit frequency to > than the number of periods to prevent cells from being populated in the loop below
			unitFrequency = periods.length + 1;
		}

		let perUnitQuantity = 0;
		let i = 0;
		for (; i < periods.length; i++) {
			if (priceMethod === PRICE_METHOD.FLAT_PRICE) {
				if (
					frequency === RECURRING_VALUE.PROJECT_END
					|| frequency === RECURRING_VALUE.PROJECT_START
				) {
					perUnitQuantity = 1;
				} else {
					perUnitQuantity += 1;
				}
			} else if (priceMethod === PRICE_METHOD.PER_HEAD) {
				perUnitQuantity += await this.getPeriodQuantity(i + 1);
			} else if (priceMethod) {
				const periodSum = await this.getPeriodSum(i + 1, priceMethod);
				const markDownFactor = markdownPercent ? markdownPercent / 100 : 0;
				perUnitQuantity += (periodSum * markDownFactor) / unitPrice;
			}

			if ((i + 1) % unitFrequency === 0) {
				allocation[`${i + 1}`.padStart(3, '0')] = perUnitQuantity;
				perUnitQuantity = 0;
			} else {
				// Not allocated for this unit frequency
				allocation[`${i + 1}`.padStart(3, '0')] = 0;
			}
		}

		// For project start we want to apply the sum total to the first cell
		if (frequency === RECURRING_VALUE.PROJECT_START) {
			allocation['001'] = perUnitQuantity;
		} else if (i % unitFrequency !== 0) {
			allocation[`${i}`.padStart(3, '0')] = perUnitQuantity;
		}

		return allocation;
	}

	async getPeriodQuantity(periodNumber) {
		const quoteItemDOs = await this.getMainQuoteItems();
		const periodToken = `${periodNumber}`.padStart(3, '0');
		let totalQuantity = 0;
		for (let i = 0; i < quoteItemDOs.length; i++) {
			const quoteItemDO = quoteItemDOs[i];

			const {
				periodValueMap,
			} = quoteItemDO;

			const periodQty = periodValueMap[periodToken] || 0;
			totalQuantity += periodQty;
		}

		return totalQuantity;
	}

	async getPeriodSum(periodNumber, unitOfMeasure) {
		const periods = await this.getQuotePeriods();
		const quoteItemDOs = await this.getMainQuoteItems();
		const period = periods[periodNumber - 1];
		let totalPerUnitSum = 0;
		for (let i = 0; i < quoteItemDOs.length; i++) {
			const quoteItemDO = quoteItemDOs[i];

			const {
				quoteItemSO,
				periodValueMap,
			} = quoteItemDO;

			const periodQty = periodValueMap[`${periodNumber}`.padStart(3, '0')] || 0;
			let perUnitValue;
			switch (unitOfMeasure) {
				case PRICE_METHOD.PERCENTAGE_OF_COST:
					perUnitValue = quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName] || 0;
					break;
				case PRICE_METHOD.PERCENTAGE_OF_REVENUE:
					perUnitValue = quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] || 0;
					break;
				default:
					perUnitValue = 1;
			}

			totalPerUnitSum += periodQty * perUnitValue * period.term;
		}

		return totalPerUnitSum;
	}

	async getMainQuoteItems() {
		if (!this.mainItems) {
			const quoteItems = await getQuoteItemsForQuote({
				quoteId: this.recordId,
			});

			this.mainItems = JSON.parse(quoteItems).filter((item) => item.isMiscellaneous !== true);
		}

		return this.mainItems;
	}

	getRowItem(row) {
		return this.rowItems[row];
	}

	async setProductId(row) {
		const quoteItem = this.getRowItem(row);
		if (quoteItem.ProductName) {
			const quoteProducts = await this.getProducts();
			for (let i = 0; i < quoteProducts.length; i++) {
				const quoteProduct = quoteProducts[i];
				if (quoteProduct.name === quoteItem.ProductName) {
					quoteItem.productId = quoteProduct.id;
					break;
				}
			}
		} else if (quoteItem.productId) {
			quoteItem.productId = null;
		}
	}

	async setRateCard(row) {
		const quoteItem = await this.getRowItem(row);
		if (quoteItem.productId) {
			const rateCards = await this.getRateCardsFor(quoteItem.productId);
			if (rateCards.length) {
				quoteItem.rateCardItemId = rateCards[0].Id;
			}
		}
	}

	async getRateCardsFor(productId) {
		let rateCards = this.rateCardsForProduct[productId];
		if (!rateCards) {
			rateCards = await getRateCardItemsForProduct({
				quoteId: this.recordId,
				productId,
			});
			this.rateCardsForProduct[productId] = JSON.parse(rateCards).map(
				(rateCard) => rateCard.fieldValueMap,
			);
		}

		return this.rateCardsForProduct[productId];
	}

	async getColumnHeaders() {
		const periodGroups = await this.getPeriodGroups();

		return [
			[{
				label: '',
				colspan: 9,
			},
			...Object.keys(periodGroups).map((groupId) => {
				const periodGroup = periodGroups[groupId];
				return {
					label: `${periodGroup[0].periodGroupName}`,
					colspan: periodGroup.length + 1,
				};
			}),
			],
			[
				LABEL_ANCILLARY,
				LABEL_FREQUENCY,
				LABEL_PRICE_METHOD,
				LABEL_PRICE_METHOD_MARKDOWN,
				`${LABEL_STD_RATE} (USD)`,
				`${LABEL_STD_COST} (USD)`,
				LABEL_DISCOUNT_PERCENT,
				LABEL_QUOTED_RATE,
				LABEL_MARGIN_PERCENT,
				...[].concat(
					...Object.keys(periodGroups).map((periodGroupId) => {
						const periodColumns = periodGroups[periodGroupId].map((period) => period.name);
						periodColumns.push(LABEL_TOTAL_AMOUNT);
						return periodColumns;
					}),
				),
				LABEL_GRAND_TOTAL,
			],
		];
	}

	async getProductNames() {
		const products = await this.getProducts();

		const filteredProductList = products
			.filter((product) => product.isMiscellaneous === true)
			.map((product) => product.name);

		filteredProductList.unshift(null);
		return filteredProductList;
	}

	async getProductsById() {
		if (!this.productsById) {
			const products = await this.getProducts();
			this.productsById = {};
			products.forEach((product) => {
				this.productsById[product.id] = product;
			});
		}

		return this.productsById;
	}

	async getProducts() {
		if (!this.products) {
			const products = await getAllProductsForQuote({
				quoteId: this.recordId,
			});

			this.products = await JSON.parse(products);
		}

		return this.products;
	}

	async getColumnMetadata() {
		if (!this.columnMetadata) {
			this.columnMetadata = [{
				data: 'ProductName',
				type: 'dropdown',
				source: await this.getProductNames(),
				isAddonColumn: true,
			},
			{
				data: QUOTE_ITEM_FREQUENCY_FIELD.fieldApiName,
				type: 'dropdown',
				source: await this.getFrequencyLOV(),
			},
			{
				data: QUOTE_ITEM_PRICE_METHOD_FIELD.fieldApiName,
				type: 'dropdown',
				source: quoteAncillaries.getPriceMethodLOV(),
			},
			{
				data: QUOTE_ITEM_PRICE_METHOD_MARKDOWN_FIELD.fieldApiName,
				type: 'numeric',
				numericFormat: {
					pattern: '0,0.00',
					culture: 'en-US',
				},
			},
			{
				data: QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName,
				type: 'numeric',
				numericFormat: {
					pattern: '$0,0.00',
					culture: 'en-US',
				},
			},
			{
				data: QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName,
				type: 'numeric',
				numericFormat: {
					pattern: '$0,0.00',
					culture: 'en-US',
				},
			},
			{
				data: 'baseAdjustmentAmount',
				apiName: 'baseAdjustmentAmount',
				type: 'numeric',
				numericFormat: {
					pattern: '0,0.00',
					culture: 'en-US',
				},
			},
			{
				data: QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName,
				apiName: QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName,
				type: 'numeric',
				numericFormat: {
					pattern: '$0,0.00',
					culture: 'en-US',
				},
			},
			{
				data: QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName,
				apiName: QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName,
				type: 'numeric',
				numericFormat: {
					pattern: '0,0.00',
					culture: 'en-US',
				},
				readOnly: true,
			},
			];
			const periodGroups = await this.getPeriodGroups();
			let periodCounter = 0;

			Object.keys(periodGroups).forEach((periodGroupId) => {
				const periodsForGroup = periodGroups[periodGroupId];
				for (let i = 0; i < periodsForGroup.length; i++) {
					this.columnMetadata.push({
						data: `${periodCounter + 1}`.padStart(3, '0'),
						type: 'numeric',
						numericFormat: {
							pattern: '0,0.000',
							culture: 'en-US',
						},
						isPeriod: true,
					});
					periodCounter += 1;
				}

				this.columnMetadata.push({
					data: `NamedRange__${periodGroupId}__mdt`,
					type: 'numeric',
					readOnly: true,
					isTotal: true,
					numericFormat: {
						pattern: '$0,0.00',
						culture: 'en-US',
					},
				});
			});

			this.columnMetadata.push({
				data: 'NamedRange__GrandTotal__mdt',
				type: 'numeric',
				readOnly: true,
				isTotal: true,
				numericFormat: {
					pattern: '$0,0.00',
					culture: 'en-US',
				},
			});
		}

		return this.columnMetadata;
	}

	async getQuoteTemplate() {
		if (!this.quoteTemplate) {
			const quoteTemplate = await getQuoteTemplate({
				quoteId: this.recordId,
			});

			this.quoteTemplate = JSON.parse(quoteTemplate);
		}

		return this.quoteTemplate;
	}

	async getQuotePeriods() {
		const quoteTemplate = await this.getQuoteTemplate();
		return quoteTemplate.quotePeriodList;
	}

	async getPeriodGroups() {
		if (!this.periodGroups) {
			const periods = await this.getQuotePeriods();
			this.periodGroups = {};

			for (let i = 0; i < periods.length; i++) {
				const period = periods[i];
				let periodsForGroup = this.periodGroups[period.periodGroupId];
				if (!periodsForGroup) {
					periodsForGroup = [];
					this.periodGroups[period.periodGroupId] = periodsForGroup;
				}

				periodsForGroup.push(period);
			}
		}

		return this.periodGroups;
	}

	async getColumnsByName() {
		if (!this.columnsByName) {
			this.columnsByName = {};
			const columns = await this.getColumnMetadata();
			for (let i = 0; i < columns.length; i++) {
				const column = columns[i];
				this.columnsByName[column.data] = column;
			}
		}

		return this.columnsByName;
	}
}
