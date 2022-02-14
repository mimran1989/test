import {
	LightningElement, api, track, wire,
} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import baseJS from '@salesforce/resourceUrl/Provus';
import { isEmpty, isNullOrUndefined, componentNamespace } from 'c/util';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import NamespacePrefix from '@salesforce/apex/SystemUtility.getNamespacePrefix';

import commitChanges from '@salesforce/apex/QuoteCollaborationController.commitChanges';
import mergeSections from '@salesforce/apex/QuoteCollaborationController.mergeSections';
import revokeSections from '@salesforce/apex/QuoteCollaborationController.revokeSections';
import getAllProductsForQuote from '@salesforce/apex/QuoteConfiguratorController.getAllProductsForQuote';
import getQuoteItemsForQuote from '@salesforce/apex/QuoteConfiguratorController.getQuoteItemsForQuote';
import getQuoteTemplate from '@salesforce/apex/QuoteConfiguratorController.getQuoteTemplate';
import getRateCardItemsForProduct from '@salesforce/apex/QuoteConfiguratorController.getAllRateCardItemsForProduct';
import getProjectPhasesForQuote from '@salesforce/apex/QuoteConfiguratorController.getProjectPhasesForQuote';
import getQuoteSectionsForQuote from '@salesforce/apex/QuoteConfiguratorController.getQuoteSectionsForQuote';
import getNamedRangesForQuote from '@salesforce/apex/QuoteConfiguratorController.getNamedRangesForQuote';
import getCollaborationRequestsForQuote from '@salesforce/apex/QuoteCollaborationController.getCollaborationRequestsForQuote';
import { reduceErrors } from 'c/sparkUtils';

// labels
import LABEL_ADD_RESOURCE from '@salesforce/label/c.AddResource';
import LABEL_COLLABORATION_COMMITTED from '@salesforce/label/c.CollaborationCommitted';
import LABEL_COLLABORATION_MERGED from '@salesforce/label/c.CollaborationMerged';
import LABEL_COMMIT from '@salesforce/label/c.Commit';
import LABEL_DEFAULT_SECTION from '@salesforce/label/c.DefaultSection';
import LABEL_DISCOUNT_PERCENT from '@salesforce/label/c.DiscountPercent';
import LABEL_EDIT_RESOURCE from '@salesforce/label/c.EditResource';
import LABEL_EDIT_SECTION from '@salesforce/label/c.EditSection';
import LABEL_GRAND_TOTAL from '@salesforce/label/c.GrandTotal';
import LABEL_HIDE_METRICS from '@salesforce/label/c.HideMetrics';
import LABEL_HIDE_PRICING_ATTRIBUTES from '@salesforce/label/c.HidePricingAttributes';
import LABEL_HIDE_QUOTE_ITEMS from '@salesforce/label/c.HideQuoteItems';
import LABEL_HIDE_RATE_ATTRIBUTES from '@salesforce/label/c.HideRateAttributes';
import LABEL_HIDE_TOTALS from '@salesforce/label/c.HideTotals';
import LABEL_MARGIN_ADJUSTMENT from '@salesforce/label/c.MarginAdjustment';
import LABEL_MERGE from '@salesforce/label/c.Merge';
import LABEL_REALIGN_RESOURCE from '@salesforce/label/c.RealignResource';
import LABEL_REVENUE_ADJUSTMENT from '@salesforce/label/c.RevenueAdjustment';
import LABEL_ROLE from '@salesforce/label/c.Role';
import LABEL_SECTION from '@salesforce/label/c.Section';
import LABEL_SHOW_METRICS from '@salesforce/label/c.ShowMetrics';
import LABEL_SHOW_PRICING_ATTRIBUTES from '@salesforce/label/c.ShowPricingAttributes';
import LABEL_SHOW_QUOTE_ITEMS from '@salesforce/label/c.ShowQuoteItems';
import LABEL_SHOW_RATE_ATTRIBUTES from '@salesforce/label/c.ShowRateAttributes';
import LABEL_SHOW_TOTALS from '@salesforce/label/c.ShowTotals';
import LABEL_TOTAL from '@salesforce/label/c.Total';

// schema
import QUOTE_OBJECT from '@salesforce/schema/Quote__c';
import QUOTE_ITEM_OBJECT from '@salesforce/schema/QuoteItem__c';
import RATE_CARD_ITEM_OBJECT from '@salesforce/schema/RateCardItem__c';
import RATE_CARD_ITEM_PRICE_UOM_FIELD from '@salesforce/schema/RateCardItem__c.PriceUOM__c';
import RATE_CARD_ITEM_PRODUCT_FIELD from '@salesforce/schema/RateCardItem__c.ProductId__c';

import COLLABORATOR_USER_ID_FIELD from '@salesforce/schema/CollaborationRequest__c.CollaboratorUserId__c';
import STATUS_FIELD from '@salesforce/schema/CollaborationRequest__c.Status__c';
import SECTION_ID_FIELD from '@salesforce/schema/CollaborationRequest__c.SectionId__c';
import DERIVED_FROM_ID_FIELD from '@salesforce/schema/QuoteSection__c.DerivedFromId__c';

import QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD from '@salesforce/schema/QuoteItem__c.LocationDisplayName__c';
import QUOTE_ITEM_UNIT_PRICE_FIELD from '@salesforce/schema/QuoteItem__c.UnitPrice__c';
import QUOTE_ITEM_UNIT_COST_FIELD from '@salesforce/schema/QuoteItem__c.UnitCost__c';
import QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD from '@salesforce/schema/QuoteItem__c.AdjustedUnitPrice__c';
import QUOTE_ITEM_LOCATION_COUNTRY_FIELD from '@salesforce/schema/QuoteItem__c.LocationCountry__c';
import QUOTE_ITEM_QUANTITY_FIELD from '@salesforce/schema/QuoteItem__c.Quantity__c';
import QUOTE_ITEM_MARGIN_PERCENT_FIELD from '@salesforce/schema/QuoteItem__c.MarginPercent__c';
import QUOTE_ITEM_NETEXTENDEDAMOUNT_FIELD from '@salesforce/schema/QuoteItem__c.NetExtendedAmount__c';
import QUOTE_ITEM_NETEXTENDEDCOST_FIELD from '@salesforce/schema/QuoteItem__c.NetExtendedCost__c';
import QUOTE_ITEM_LINE_TYPE_FIELD from '@salesforce/schema/QuoteItem__c.LineType__c';
import QUOTE_ITEM_SKILL_LEVEL_FIELD from '@salesforce/schema/QuoteItem__c.SkillLevel__c';
import QUOTE_ITEM_ROLE_NAME_OVERRIDE_FIELD from '@salesforce/schema/QuoteItem__c.RoleNameOverride__c';
import QUOTE_ITEM_NONBILLABLE_FIELD from '@salesforce/schema/QuoteItem__c.NonBillable__c';

import log from 'c/log';
import LinkedList from 'c/linkedList';
import {
	AdjustmentType, RateCardItem, Quote,
	OBSERVER_NAME_SFDC, ScheduleSettingFields, ContextMenuActions, ColumnGroup, CollaborationRequest,
	RecordType,
} from 'c/constantUtil';
import ContextMenu from './contextMenu';

export default class QuoteConfigurator extends LightningElement {
	@api recordId;
	@track isNameModalOpen = false;
	@track isMetricsAvailable = false;
	@wire(NamespacePrefix) nsPrefix;
	hideResourceRole = true;
	rateCardId;
	group;
	practice;
	namespace;

	render = Date.now();

	currencyISOCode;
	currencyConversionRatio;

	ComponentId = 'quoteGrid';

	rows = new LinkedList();
	grid;
	loading = true;
	quoteProducts;
	productsById = {};
	rateCardItems = {};
	columnMetadata;
	rowMetadata = [];

	onMessage;

	gridURL = `${baseJS}/grid/index.html`;
	periods = [];
	periodsByGroup;
	periodGroups = {};
	periodsBySequence = {};
	baseItemSequenceNumber = 0;
	baseSectionSequenceNumber = 0;

	quoteTimePeriod;
	sectionHierarchy;
	selectedRange;
	dialogActionLabel;
	dialogInputTitle;
	dialogInputPlaceholder;
	dialogInitialValue;
	loaded = false;
	quoteItems = {};
	quoteItemsByLineSeq;
	sections = {};
	rootItems = [];
	renderingGrid = false;
	createScenarioProp = {
		isQuickAction: false,
		isCreate: false,
		adjustmentOptions: [
			{ label: LABEL_REVENUE_ADJUSTMENT, value: AdjustmentType.REVENUE_ADJUSTMENT },
			{ label: LABEL_MARGIN_ADJUSTMENT, value: AdjustmentType.MARGIN_ADJUSTMENT },
			{ label: LABEL_REALIGN_RESOURCE, value: AdjustmentType.REALIGN_RESOURCE },
		],
	};

	collaborationRequests = [];

	periodNamedRanges = {};
	quoteItemNamedRanges = {};
	quoteItemPeriodGroupNamedRanges = {};
	namedRanges = {};
	disableAdjustment = false;
	_gridUpdateChannel;
	_componentState;
	_quoteService;
	_columnsByName;
	_phases = [];
	_phasesById = {};
	_phaseNamedRanges = {};

	initPromise;
	disableButton = true;

	@track
	primaryActions;

	@track
	viewSettings = {
		quoteItems: {
			label: LABEL_HIDE_QUOTE_ITEMS,
			isVisible: true,
		},
		totals: {
			label: LABEL_HIDE_TOTALS,
			isVisible: true,
		},
		rateAttributes: {
			label: LABEL_HIDE_RATE_ATTRIBUTES,
			isVisible: true,
		},
		pricingAttributes: {
			label: LABEL_HIDE_PRICING_ATTRIBUTES,
			isVisible: true,
		},
		metrics: {
			label: LABEL_SHOW_METRICS,
			isVisible: false,
		},
	};

	get quoteRecordId() {
		return this.recordId;
	}

	groupedTotals = {};

	disableSections() {
		return !this.sectionHierarchy;
	}

	publishGridTotalChange() {
		const payload = Object.values(this.groupedTotals);
		this._gridUpdateChannel.publish({ key: 'totalschange', value: payload });
	}

	handleStateReport(event) {
		const { reporter, status } = event.detail.value;
		if (reporter === 'quoteMetrics') {
			this.viewSettings.metrics.isVisible = status.visible;
			this.isMetricsAvailable = true;
		}
	}

	handleDeselect() {
		this.grid.deselectCell();
	}

	handleStatusRequest() {
		const payload = {
			reporter: this.ComponentId,
			status: {
				visible: !this.isHidden,
			},
		};

		this._componentState.publish({ key: 'report', value: payload });
	}

	async handleInvite() {
		await this.reloadCollaborationRequests();
		this.refreshGrid();
	}

	@wire(getObjectInfo, { objectApiName: QUOTE_OBJECT })
	quoteSchema;

	constructor() {
		super();
		const self = this;

		const commit = {
			get enabled() { return self.hasOutstandingRequests(); },
			get visible() { return self.isCollaborationQuote(); },
			get showEnabled() { return this.visible && this.enabled; },
			get showDisabled() { return this.visible && !this.enabled; },
			label: LABEL_COMMIT,
			dataId: 'button-commit',
			handler: self.handleCommit,
		};

		const merge = {
			enabled: false,
			visible: false,
			get showEnabled() { return this.visible && this.enabled; },
			get showDisabled() { return this.visible && !this.enabled; },
			label: LABEL_MERGE,
			dataId: 'button-merge',
			handler: self.handleQuoteMerge,
		};

		this.actionsMap = {
			commit,
			merge,
		};

		this.primaryActions = [
			commit,
			merge,
		];
	}

	get channel() {
		let channel;
		if (this.nsPrefix.data !== undefined) {
			channel = `${this.nsPrefix.data}QuoteUpdate__e`;
		}

		return channel;
	}

	connectedCallback() {
		const component = this;
		this.namespace = componentNamespace(this);
		this.onMessage = (() => async() => {
			await component.reloadCollaborationRequests();

			if (this.hasRequestsToMerge()) {
				component.actionsMap.merge.visible = component.actionsMap.merge.enabled; // show only when enabled
			}

			await this.refreshGrid();
			component.rerender();
		})();
	}

	async renderedCallback() {
		if (!this.loaded) {
			this.loaded = true;
			this._gridUpdateChannel = this.template.querySelector('.grid-update');
			this._componentState = this.template.querySelector('.component-state');
			this._quoteService = this.template.querySelector('c-quote-service');

			// request the visibility of the connected components
			this._componentState.publish({ key: 'status', value: { receiver: null } });

			await loadScript(this, `${baseJS}/grid/index.js`);
			await loadScript(this, `${baseJS}/data/index.js`);

			if (!this.initPromise) {
				this.initPromise = this.loadData(this.recordId);
			}
		}

		this.loading = false;
	}

	async initializeFrame() {
		if (!this.initPromise) {
			this.initPromise = this.loadData(this.recordId);
		}

		const data = await this.initPromise;
		this.initPromise = null;

		const container = this.template.querySelector('iframe');

		const {
			options, metadata, marginPercent, totalAmount, isScenarioPricePending, hasAddOns,
		} = data;

		this.grid = await Provus.Grid.forFrame(container, this.origin);
		this.grid.onMovePeriods((...args) => this.onMovePeriods(...args));

		await this.grid.init(options);

		await this.initializeCells(metadata, true, isScenarioPricePending, hasAddOns);

		if (isScenarioPricePending === true) {
			if (totalAmount === null && marginPercent !== null) {
				await this.adjustQuoteMargin(marginPercent);
			} else if (marginPercent === null && totalAmount !== null) {
				await this.adjustQuoteRevenue(totalAmount);
			}
		}

		// TODO -- optimize for the scenario use case
		await this.updateSectionTotals();
		await this.updatePeriodGroupTotals();

		if (Object.keys(this.quoteItems).length > 0) {
			this.baseItemSequenceNumber = Math.max(
				...Object.values(this.quoteItems)
					.map((item) => item.lineSequence),
			) || this.baseItemSequenceNumber;
		}

		if (Object.keys(this.sections).length > 0) {
			this.baseSectionSequenceNumber = Math.max(
				...Object.values(this.sections)
					.map((section) => section.sequence),
			) || this.baseSectionSequenceNumber;
		}
	}

	findSectionFor(sectionId) {
		return Object.values(this.sections).find((nextSection) => nextSection.elementDO.id === sectionId);
	}

	async addRowsToSection(rowIdx, newChildItems) {
		// if rowIdx is zero then the assumption is we don't need to reparent anything and no targetMeta is needed
		const targetMeta = await this.grid.getCellMeta(rowIdx - 1, 0); // the highlighted row is above the row index
		const targetRow = this.sections[targetMeta.$id] || this.quoteItems[targetMeta.$id];
		const parentSection = this.sections[targetMeta.$id] || targetRow?.parent;

		// item no longer belongs to a section
		newChildItems.forEach((nextItem) => {
			if (parentSection) {
				nextItem.setParent(parentSection);
			} else {
				nextItem.parent?.removeChild(nextItem);
			}
		});

		this.assignChildren();
		const columns = this.buildColumnMetadata();
		const { data, metadata } = this.buildRows();
		const mergeCells = this.buildMergeCells(metadata);
		const cellOptions = this.buildCellOptions(metadata);

		this.renderingGrid = true;
		await this.grid.updateSettings({
			cell: cellOptions,
			columns,
			data,
			mergeCells,
			nestedHeaders: this.getColumnHeaders(), // nestedRows: true,
		});

		await this.initializeCells(metadata, true);

		if (parentSection) {
			this.updateSectionTotals();
			this.updatePeriodGroupTotals();
		}

		this.renderingGrid = false;
		await this.toggleTotalAmount();
		// quote attribute issue fix
		this.viewSettings.rateAttributes.isVisible = false;
		await this.handleToggleRateAttributes();

		this.viewSettings.pricingAttributes.isVisible = false;
		await this.handleTogglePricingAttributes();

		this.viewSettings.quoteItems.isVisible = false;
		await this.handleToggleQuoteItems();
	}

	async refreshGrid() {
		const columns = this.buildColumnMetadata();
		const { data, metadata } = this.buildRows();
		const mergeCells = this.buildMergeCells(metadata);
		const cellOptions = this.buildCellOptions(metadata);

		this.renderingGrid = true;
		await this.grid.updateSettings({
			cell: cellOptions,
			columns,
			data,
			mergeCells,
			nestedHeaders: this.getColumnHeaders(), // nestedRows: true,
		});

		await this.initializeCells(metadata, true);
		this.renderingGrid = false;
	}

	newQuoteItem(quoteItemDO = this.newQuoteItemDO()) {
		const quoteItem = Provus.QuoteItem.for(quoteItemDO);
		this.quoteItems[quoteItem.$id] = quoteItem;
		this.quoteItemsByLineSeq[quoteItem.lineSequence] = quoteItem;

		const { sectionId } = quoteItem.elementDO.quoteItemSO;
		if (sectionId) {
			const section = this.findSectionFor(sectionId);
			if (section) {
				section.addQuoteItem(quoteItem);
			}
		}

		return quoteItem;
	}

	async afterCreateRow(createdAt, numberOfRows) {
		await this.addRowsToSection(createdAt, this.spliceNewRows(createdAt, [...new Array(numberOfRows)]));
		this._quoteService.saveSections();
	}

	spliceNewRows(at, rateCardItems = []) {
		const newItems = [];
		this.rowMetadata.splice(
			at,
			0,
			...rateCardItems.map((row, index) => {
				const quoteItem = this.newQuoteItem(this.newQuoteItemDO(row));
				newItems.push(quoteItem);

				this.grid.setCellMeta(at + index, 0, '$id', quoteItem.$id);
				return quoteItem.metadata();
			}),
		);

		return newItems;
	}

	async onMovePeriods(movedColumns, targetColumn) {
		if (movedColumns[0] !== targetColumn) {
			const lastRow = (await this.grid.countRows()) - 1;
			// get phase of the target column
			const { phase: targetPhase } = await this.grid.getCellMeta(lastRow, targetColumn);
			const targetPhaseMO = this._phasesById[targetPhase.$id];
			let isMoveable = true;
			for (let i = 0; i < movedColumns.length; i++) {
				const movedColumn = movedColumns[i];
				const { phase: movedPhase } = await this.grid.getCellMeta(lastRow, movedColumn);
				if (movedPhase) {
					const movedPhaseMO = this._phasesById[movedPhase.$id];
					if (movedPhaseMO === targetPhaseMO) {
						// cannot move within the same phase
						isMoveable = false;
						break;
					}
				}
			}

			if (isMoveable) {
				let updatedPhases = {};
				const movedRangeStart = movedColumns[0];
				const movedRangeEnd = movedColumns[movedColumns.length - 1];
				let rightToLeft = true;
				if (movedRangeStart > targetPhaseMO.endCol) {
					targetPhaseMO.endCol = movedColumns[movedColumns.length - 1];
					updatedPhases[targetPhaseMO.$id] = targetPhaseMO;
				} else if (movedRangeEnd < targetPhaseMO.endCol) {
					rightToLeft = false;
					[targetPhaseMO.startCol] = movedColumns;
					updatedPhases[targetPhaseMO.$id] = targetPhaseMO;
				}

				for (let i = 0; i < movedColumns.length; i++) {
					const movedColumn = movedColumns[i];
					const { phase: movedPhase } = await this.grid.getCellMeta(lastRow, movedColumn);
					if (movedPhase) {
						const movedPhaseMO = this._phasesById[movedPhase.$id];
						if (rightToLeft && movedColumn >= movedPhaseMO.startCol) {
							movedPhaseMO.startCol += 1;
							updatedPhases[movedPhaseMO.$id] = movedPhaseMO;
						} else if (!rightToLeft && movedColumn <= movedPhaseMO.endCol) {
							movedPhaseMO.endCol = movedColumn - 1;
							updatedPhases[movedPhaseMO.$id] = movedPhaseMO;
						}
					}
				}

				updatedPhases = Object.values(updatedPhases);

				for (let i = 0; i < updatedPhases.length; i++) {
					const updatedPhase = updatedPhases[i];
					const { startCol, endCol } = updatedPhase;
					const startColumnMeta = this.columnMetadata[startCol].data;
					const endColumnMeta = this.columnMetadata[endCol].data;
					const startPeriod = this.periods[Number(startColumnMeta) - 1];
					const endPeriod = this.periods[Number(endColumnMeta) - 1];

					updatedPhase.startDate = startPeriod?.startDate;
					updatedPhase.endDate = endPeriod?.endDate;
				}

				this._phases = this._phases.filter((phase) => phase.numberOfPeriods() > 0);

				for (let i = 0; i < movedColumns.length; i++) {
					const movedColumn = movedColumns[i];
					this.grid.setCellMeta(lastRow, movedColumn, 'phase', { $id: targetPhaseMO.$id });
				}

				await this.grid.updateSettings({
					nestedHeaders: this.getColumnHeaders(),
				});

				this._quoteService.savePhases();
			}
		}
	}

	addRowStyles(cellMetadata, rowIdx) {
		const styleMetaPromises = [];
		const hasSections = Object.values(this.sections).length > 0;

		const {
			isSectionFooter, isSectionHeader, isQuantityFooter, isAmountFooter,
		} = cellMetadata;

		if (hasSections) {
			if (!isSectionFooter && !isSectionHeader && !isQuantityFooter && !isAmountFooter) {
				styleMetaPromises.push(
					this.grid.setCellMeta(rowIdx, 0, 'className', 'sectionChildSectionColumn'),
				);
			}
		}

		return styleMetaPromises;
	}

	async repriceQuoteGrid() {
		if (this.rowMetadata.length || this._phases.length) {
			const rowCount = await this.grid.countRows();
			if (this.rowMetadata.length) {
				const rowsWhichNeedTotalsUpdate = [];
				const setMetadata = [];
				const totalsRowIdx = rowCount - 2;
				for (let i = 0; i < this.rowMetadata.length; i++) {
					const rowMeta = this.rowMetadata[i];

					const {
						isAmountFooter, isQuantityFooter, isSectionFooter, isSectionHeader,
					} = rowMeta;

					setMetadata.push(this.grid.setCellMetaObject(i, 0, rowMeta));

					if (!isSectionFooter && !isSectionHeader && !isAmountFooter && !isQuantityFooter) {
						setMetadata.push(this.setAvailablePracticeAndSkill(i), this.setPricePoints(i));

						if (i < totalsRowIdx) {
							rowsWhichNeedTotalsUpdate.push(i);
						}
					}
				}

				if (rowsWhichNeedTotalsUpdate.length) {
					await Promise.all(setMetadata).then(() => this.updateTotalsForRows(rowsWhichNeedTotalsUpdate));
				}
			}
		}
	}

	async initializeCells(cellMetadata, bypassQuoteTotals, isAdjustedScenario, hasAddOns) {
		if (cellMetadata.length || this._phases.length) {
			const rowCount = await this.grid.countRows();
			if (cellMetadata.length) {
				const { rowsWhichNeedTotalsUpdate, setMetadata } = await this.getRowsForReprice(cellMetadata, rowCount);
				if (rowsWhichNeedTotalsUpdate.length) {
					await Promise.all(setMetadata).then(() => this.updateTotalsForRows(rowsWhichNeedTotalsUpdate));
				}

				// refresh the charts and other related components
				this.publishGridTotalChange();

				const columnNames = {};
				this.columnMetadata.forEach((column) => {
					columnNames[column.data] = true;
				});

				await this.updateColumnsTotals(
					columnNames,
					bypassQuoteTotals,
					isAdjustedScenario,
					hasAddOns,
				);
			}

			// set phase metadata
			const lastRow = rowCount - 1;
			this._phases.forEach((phase) => {
				for (let i = phase.startCol; i < phase.endCol + 1; i++) {
					this.grid.setCellMeta(lastRow, i, 'phase', { $id: phase.$id });
				}
			});
		}
	}

	async getRowsForReprice(cellMetadata, rowCount) {
		const rowsWhichNeedTotalsUpdate = [];
		const setMetadata = [];
		const totalsRowIdx = rowCount - 2;
		for (let i = 0; i < cellMetadata.length; i++) {
			const rowMeta = cellMetadata[i];

			const {
				isAmountFooter, isQuantityFooter, isSectionFooter, isSectionHeader,
			} = rowMeta;

			setMetadata.push(this.grid.setCellMetaObject(i, 0, rowMeta));
			setMetadata.push(...this.addRowStyles(rowMeta, i));

			if (!isSectionFooter && !isSectionHeader && !isAmountFooter && !isQuantityFooter) {
				setMetadata.push(this.setAvailablePracticeAndSkill(i), this.setPricePoints(i));

				if (i < totalsRowIdx) {
					rowsWhichNeedTotalsUpdate.push(i);
				}
			} else {
				for (let j = 0; j < this.columnMetadata.length; j++) {
					setMetadata.push(this.grid.setCellMetaObject(i, j, cellMetadata[i]));
				}
			}
		}

		return {
			rowsWhichNeedTotalsUpdate,
			setMetadata,
		};
	}

	async initializeCellTotals() {
		const rowCount = await this.grid.countRows();
		const totalsRowIdx = rowCount - 2;
		const rowsWhichNeedTotalsUpdate = [];
		for (let i = 0; i < rowCount.length; i++) {
			this.setAvailablePracticeAndSkill(i);
			this.setPricePoints(i);

			if (i < totalsRowIdx) {
				rowsWhichNeedTotalsUpdate.push(i);
			}
		}

		if (rowsWhichNeedTotalsUpdate.length) {
			this.updateTotalsForRows(rowsWhichNeedTotalsUpdate);
		}

		const columnNames = {};
		this.columnMetadata.forEach((column) => {
			columnNames[column.data] = true;
		});

		await this.updateColumnsTotals(columnNames);
		await this.updatePeriodGroupTotals();
	}

	async onChange(changes, context) {
		const isSetPricePoints = context === 'setPricePoints';
		if (!isSetPricePoints && this.loaded && !this.renderingGrid) {
			if (changes) {
				const totalsRowIdx = (await this.grid.countRows()) - 2;
				const updateGrid = [];

				await this.grid.suspendRender();
				const changedRows = {};
				const modifiedColumns = {};
				const quoteItemsByRowIdx = {};
				for (let i = 0; i < changes.length; i++) {
					const [row, prop, oldValue, newValue] = changes[i];
					if (totalsRowIdx > row) {
						// ignore updates to the totals row
						if (oldValue !== newValue) {
							const { isSectionFooter, isSectionHeader } = await this.grid.getCellMeta(row, 0);
							const { readOnly } = this.getColumnMetadata(prop);
							if (!isSectionFooter && !isSectionHeader && !readOnly) {
								let quoteItem = quoteItemsByRowIdx[row];
								if (!quoteItem) {
									quoteItem = await this.getQuoteItemForRow(row);

									if (!quoteItem) {
										quoteItem = Provus.QuoteItem.for(this.newQuoteItemDO());

										this.quoteItems[quoteItem.$id] = quoteItem;
										this.quoteItemsByLineSeq[quoteItem.lineSequence] = quoteItem;
										await this.grid.setCellMeta(row, 0, '$id', quoteItem.$id);
									}

									quoteItemsByRowIdx[row] = quoteItem;
								}

								const columnMetadata = this.getColumnMetadata(prop);
								if (columnMetadata.isPeriod) {
									quoteItem.periodValueMap[prop] = newValue;
								} else if (prop === QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName) {
									quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = newValue;
									quoteItem.adjustment.amount = null;
									quoteItem.adjustment.type = null;
								} else if (prop === 'baseAdjustmentAmount') {
									quoteItem.adjustment.amount = newValue;
									quoteItem.adjustment.type = '% Discount';
									quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
								} else if (prop.indexOf('__mdt') < 0) {
									quoteItem.quoteItemSO[prop] = newValue;
								}

								changedRows[row] = true;
								// checks whether the old value is set or not
								modifiedColumns[prop] = !!oldValue;
							}
						}
					}
				}

				Object.keys(changedRows).forEach((row) => {
					const rowIdx = Number(row);

					updateGrid.push(
						this.setAvailablePracticeAndSkill(rowIdx).then(() => this.updateRateCardItemAttributes(rowIdx)),
						this.setPricePoints(rowIdx).then(() => this.updateTotalsFor(rowIdx)),
					);
				});

				if (Object.keys(changedRows).length) {
					await Promise.all(updateGrid);
					this.publishGridTotalChange();
					await this.updateSectionTotals();

					if (modifiedColumns[QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName]) {
						await this.recomputeColumnTotals();
					} else {
						await this.updateColumnsTotals(modifiedColumns);
					}

					await this.updatePeriodGroupTotals();
					this._quoteService.saveLines().catch((e) => {
						log('Failed to save lines ');
						log(e);
					});
				}

				this.grid.resumeRender();
			}
		}
	}

	async updateRateCardItemAttributes(row) {
		const columnsToUpdate = [];
		const quoteItem = await this.getQuoteItemForRow(row);
		const rateCardAttributes = this.getRateCardAttributes();
		rateCardAttributes.forEach((rateCardAttribute) => {
			const { fieldName } = rateCardAttribute;
			columnsToUpdate.push([row, fieldName, quoteItem.quoteItemSO[fieldName]]);
		});

		this.grid.setDataAtRowProp(columnsToUpdate);
	}

	newQuoteItemDO(rateCardItem) {
		const quoteItemSO = {};
		quoteItemSO[QUOTE_ITEM_LINE_TYPE_FIELD.fieldApiName] = 'Resource';

		const adjustment = {};

		const quoteItemDO = {
			rateCardItemId: rateCardItem?.Id,
			productId: rateCardItem && rateCardItem[RATE_CARD_ITEM_PRODUCT_FIELD.fieldApiName],
			lineSequence: this.getNextItemSequenceNumber(),
			periodValueMap: {},
			quoteItemSO,
			adjustment,
		};

		if (rateCardItem) {
			const rateCardAttributes = this.getRateCardAttributes();
			rateCardAttributes.forEach((rateCardAttribute) => {
				const { fieldName } = rateCardAttribute;
				quoteItemSO[fieldName] = rateCardItem[fieldName];
			});
		}

		return quoteItemDO;
	}

	async updateQuoteTotal(deltaPrice, deltaQty, deltaCost) {
		if (deltaPrice !== 0 || deltaQty !== 0 || deltaCost !== 0) {
			const rowCount = await this.grid.countRows();
			if (!this.quoteNamedRange) {
				this.quoteNamedRange = QuoteConfigurator.newNamedRange({
					name: 'Labor Amount',
					quoteId: this.recordId,
					type: 'Quote Labor',
				});
			}

			if (!this.quoteTotalNamedRange) {
				this.quoteTotalNamedRange = QuoteConfigurator.newNamedRange({
					name: 'Quote Totals',
					quoteId: this.recordId,
					type: 'Quote',
				});
			}

			const { relatedTotal } = this.quoteNamedRange;
			relatedTotal.totalAmount += deltaPrice;
			relatedTotal.totalCost += deltaCost;
			relatedTotal.totalQuantity += deltaQty;
			relatedTotal.marginPercent = QuoteConfigurator.marginPercentage(
				relatedTotal.totalAmount,
				relatedTotal.totalCost,
			);

			const { relatedTotal: quoteTotalRelatedTotal } = this.quoteTotalNamedRange;
			quoteTotalRelatedTotal.totalAmount += deltaPrice;
			quoteTotalRelatedTotal.totalCost += deltaCost;
			quoteTotalRelatedTotal.totalQuantity += deltaQty;
			quoteTotalRelatedTotal.marginPercent = QuoteConfigurator.marginPercentage(
				quoteTotalRelatedTotal.totalAmount,
				quoteTotalRelatedTotal.totalCost,
			);

			this.grid.setDataAtRowProp([
				[rowCount - 1, 'NamedRange__GrandTotal__mdt', relatedTotal.totalAmount],
				[rowCount - 2, 'NamedRange__GrandTotal__mdt', relatedTotal.totalQuantity],
			]);

			this._quoteService.saveNamedRanges();
		}
	}

	static marginPercentage(revenue, cost) {
		if (revenue === 0 && cost > 0) {
			return -100;
		}

		const relativeDifference = revenue - cost || 0;
		return relativeDifference === 0 ? 0 : (relativeDifference / revenue) * 100;
	}

	async updateColumnsTotals(modifiedColumns, bypassGrandTotals, isAdjustedScenario, hasAddOns) {
		const columnTotalUpdates = {};
		const modifiedColumnNames = Object.keys(modifiedColumns);

		const isPriceModified = modifiedColumnNames.indexOf('baseAdjustmentAmount') > -1
			|| modifiedColumnNames.indexOf(QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName) > -1;

		if (isPriceModified === true) {
			const periodGroupIds = Object.keys(this.periodsByGroup);
			let periodColIdx = this.periodColumnsOffset();
			for (let i = 0; i < periodGroupIds.length; i++) {
				const periods = this.periodsByGroup[periodGroupIds[i]];
				for (let j = 0; j < periods.length; j++) {
					columnTotalUpdates[periodColIdx] = this.updateColumnTotal(
						this.columnMetadata[periodColIdx].data,
						periodColIdx,
					);
					periodColIdx += 1;
				}

				// Add one for the period group totals column
				periodColIdx += 1;
			}
		} else {
			for (let i = 0; i < modifiedColumnNames.length; i++) {
				const columnAPIName = modifiedColumnNames[i];
				// eslint-disable-next-line no-await-in-loop
				const colIdx = await this.grid.propToCol(columnAPIName);
				if (colIdx >= this.periodColumnsOffset()) {
					columnTotalUpdates[colIdx] = this.updateColumnTotal(columnAPIName, colIdx);
				}
			}
		}

		let result;
		const updateResults = Object.values(columnTotalUpdates);
		if (updateResults.length) {
			const columnsToUpdate = await Promise.all(updateResults);
			const newValues = [];
			let deltaPrice = 0;
			let deltaQty = 0;
			let deltaCost = 0;
			for (let i = 0; i < Object.keys(columnTotalUpdates).length; i++) {
				const { columnUpdates, delta } = columnsToUpdate[i];
				newValues.push(...columnUpdates);
				deltaPrice += delta.TotalPrice;
				deltaQty += delta.HeadCount;
				deltaCost += delta.TotalCost;
			}

			result = this.grid.setDataAtRowProp(newValues);

			if (!isAdjustedScenario) {
				if (bypassGrandTotals !== true) {
					this.updateQuoteTotal(deltaPrice, deltaQty, deltaCost);
				} else if (this.quoteNamedRange && hasAddOns !== true) {
					const { relatedTotal } = this.quoteNamedRange;
					const previousQty = relatedTotal.totalQuantity;
					const previousTotal = relatedTotal.totalAmount;
					const previousCost = relatedTotal.totalCost;
					this.updateQuoteTotal(
						deltaPrice - previousTotal,
						deltaQty - previousQty,
						deltaCost - previousCost,
					);
				}
			}
		}

		return result;
	}

	async updatePhaseTotals() {
		const phaseTotals = {};
		const lastRowIdx = (await this.grid.countRows()) - 1;
		for (let i = 0; i < this.columnMetadata.length; i++) {
			const { isPeriod } = this.columnMetadata[i];
			if (isPeriod) {
				const { phase } = await this.grid.getCellMeta(lastRowIdx, i);
				if (phase) {
					const phaseMO = this._phasesById[phase.$id];
					if (phaseMO.isPersisted()) {
						let totalsForPhase = phaseTotals[phase.$id];
						if (!totalsForPhase) {
							totalsForPhase = {
								totalCost: 0,
								marginPercent: 0,
								totalAmount: 0,
								totalQuantity: 0,
							};

							phaseTotals[phaseMO.$id] = totalsForPhase;
						}

						const periodTotal = (await this.grid.getDataAtCell(lastRowIdx, i)) || 0;
						const periodQty = (await this.grid.getDataAtCell(lastRowIdx - 1, i)) || 0;
						const periodCost = (await this.grid.getCellMeta(lastRowIdx - 1, i)).TotalCost || 0;

						totalsForPhase.totalAmount += periodTotal;
						totalsForPhase.totalCost += periodCost;
						totalsForPhase.totalQuantity += periodQty;
						totalsForPhase.marginPercent = QuoteConfigurator.marginPercentage(periodTotal, periodCost);
					}
				}
			}
		}

		const phaseIdsToUpdate = Object.keys(phaseTotals);
		for (let i = 0; i < phaseIdsToUpdate.length; i++) {
			const phaseTxnId = phaseIdsToUpdate[i];
			const phase = this._phasesById[phaseTxnId];
			const totalsForPhase = phaseTotals[phaseTxnId];
			let phaseNamedRange = this._phaseNamedRanges[phase.id];
			if (!phaseNamedRange) {
				phaseNamedRange = QuoteConfigurator.newNamedRange({
					name: `Phase: ${phase.name}`,
					quoteId: this.recordId,
					projectPhaseId: phase.id,
					type: 'Project Phase',
				});
			}

			const { relatedTotal } = phaseNamedRange;
			relatedTotal.totalAmount = totalsForPhase.totalAmount;
			relatedTotal.totalQuantity = totalsForPhase.totalQuantity;
			relatedTotal.totalCost = totalsForPhase.totalCost;
			relatedTotal.marginPercent = QuoteConfigurator.marginPercentage(relatedTotal.totalAmount, relatedTotal.totalCost);

			this._quoteService.saveNamedRanges();
		}
	}
	async updateColumnTotal(columnAPIName, colIdx) {
		const rowCount = (await this.grid.countRows()) - 2;
		let columnTotal = 0;
		let headCountTotal = 0;
		let costTotal = 0;
		const columnUpdates = [];
		for (let i = 0; i < rowCount; i++) {
			const {
				isSectionHeader, isSectionFooter, HeadCount, TotalPrice, TotalCost,
			} = await this.grid.getCellMeta(i, colIdx);

			if (!isSectionHeader && !isSectionFooter) {
				headCountTotal += HeadCount || 0;
				columnTotal += TotalPrice || 0;
				costTotal += TotalCost || 0;
			}
		}

		const previousTotalAmount = (await this.grid.getDataAtRowProp(rowCount + 1, columnAPIName)) || 0;
		const previousTotalQty = (await this.grid.getDataAtRowProp(rowCount, columnAPIName)) || 0;
		const previousTotalCost = (await this.grid.getCellMeta(rowCount, colIdx)).TotalCost || 0;

		await this.grid.setCellMeta(rowCount, colIdx, 'TotalCost', costTotal);
		columnUpdates.push(
			[rowCount + 1, columnAPIName, columnTotal],
			[rowCount, columnAPIName, headCountTotal],
		);

		return {
			columnUpdates,
			delta: {
				TotalPrice: columnTotal - previousTotalAmount,
				HeadCount: headCountTotal - previousTotalQty,
				TotalCost: costTotal - previousTotalCost,
			},
		};
	}

	getRateCardAttributes() {
		return this._quoteFields.filter((quoteField) => quoteField.sourceObject === RATE_CARD_ITEM_OBJECT.objectApiName);
	}

	async getSelectedRateCard(quoteItem) {
		const { productId } = quoteItem;
		let productRateCards = [];
		if (productId) {
			productRateCards = await this.getRateCardItemsFor(productId);
		}

		const attributes = this.getRateCardAttributes();
		let selectedRateCard;
		if (productRateCards.length > 0) {
			if (attributes.length === 0) {
				// Pick the first product rate card if there are no attributes
				[selectedRateCard] = productRateCards;
			} else {
				selectedRateCard = productRateCards.find(
					(item) => {
						let isValid = true;
						for (let i = 0; i < attributes.length; i++) {
							const { fieldName } = attributes[i];
							const rateCardItemValue = item[fieldName];
							const quoteItemValue = quoteItem.quoteItemSO[fieldName];
							if (rateCardItemValue !== (quoteItemValue || null)) {
								isValid = false;
								break;
							}
						}

						return isValid;
					},
				);
			}
		}

		return selectedRateCard;
	}

	async setPricePoints(row, reset) {
		let quotedRate = 0;
		const quoteItem = await this.getQuoteItemForRow(row);
		if (reset) {
			quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
			quoteItem.adjustment.amount = null;
			quoteItem.adjustment.type = null;
		}

		const selectedRateCardItem = await this.getSelectedRateCard(quoteItem);
		// If rate card changes, wipe out any possible adjustments
		if (selectedRateCardItem?.Id !== quoteItem.rateCardItemId) {
			quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
			quoteItem.adjustment.amount = null;
		}

		quoteItem.rateCardItemId = selectedRateCardItem ? selectedRateCardItem.Id : null;

		if (selectedRateCardItem) {
			let unitPrice = parseFloat(selectedRateCardItem[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName]) * this.currencyConversionRatio;
			let unitCost = parseFloat(selectedRateCardItem[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]) * this.currencyConversionRatio;
			const priceUom = selectedRateCardItem[RATE_CARD_ITEM_PRICE_UOM_FIELD.fieldApiName];
			// convert unit price and cost to hourly UOM
			let hourlyRateConversionFactor = 1;
			switch (priceUom) {
				case RateCardItem.PriceUom.DAILY:
					hourlyRateConversionFactor = this._scheduleSettings.standardDayHours;
					break;
				case RateCardItem.PriceUom.WEEKLY:
					hourlyRateConversionFactor = this._scheduleSettings.standardWeekHours;
					break;
				case RateCardItem.PriceUom.MONTHLY:
					hourlyRateConversionFactor = this._scheduleSettings.standardMonthHours;
					break;
				case RateCardItem.PriceUom.YEARLY:
					hourlyRateConversionFactor = this._scheduleSettings.standardYearHours;
					break;
				default: break;
			}

			// convert unit price and cost to hourly UOM
			const unitPricePerHour = unitPrice / hourlyRateConversionFactor;
			const unitCostPerHour = unitCost / hourlyRateConversionFactor;
			let numberOfHoursForTimePeriod;
			switch (this.quoteTimePeriod) {
				case Quote.TimePeriod.DAYS:
					numberOfHoursForTimePeriod = this._scheduleSettings.standardDayHours;
					break;
				case Quote.TimePeriod.WEEKS:
					numberOfHoursForTimePeriod = this._scheduleSettings.standardWeekHours;
					break;
				case Quote.TimePeriod.MONTHS:
					numberOfHoursForTimePeriod = this._scheduleSettings.standardMonthHours;
					break;
				case Quote.TimePeriod.QUARTERS:
					numberOfHoursForTimePeriod = this._scheduleSettings.standardMonthHours * 3;
					break;
				default: // do nothing
					break;
			}

			// convert unit price and cost to hourly UOM
			unitPrice = unitPricePerHour * numberOfHoursForTimePeriod;
			unitCost = unitCostPerHour * numberOfHoursForTimePeriod;
			quotedRate = unitPrice;

			let discountPercentage = null;
			if (Number.isNaN(parseFloat(quoteItem.adjustment.amount))) {
				quoteItem.adjustment.amount = null;
			}

			const nonBillable = quoteItem.quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName];
			const adjustedUnitPrice = quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName];
			const adjustedUnitPriceIsEmpty = QuoteConfigurator.isNullOrUndefined(adjustedUnitPrice);
			const baseAdjustmentAmountIsEmpty = QuoteConfigurator.isNullOrUndefined(quoteItem.adjustment.amount);
			// The user has changed either the discount or the quoted rate, recalculate using the given input value
			if (nonBillable) {
				quotedRate = 0;
			} else if (!adjustedUnitPriceIsEmpty && baseAdjustmentAmountIsEmpty) {
				quotedRate = parseFloat(adjustedUnitPrice);
				discountPercentage = QuoteConfigurator.marginPercentage(unitPrice, quotedRate);
				discountPercentage = discountPercentage === 0 ? null : discountPercentage;
			} else if (!baseAdjustmentAmountIsEmpty && adjustedUnitPriceIsEmpty) {
				discountPercentage = parseFloat(quoteItem.adjustment.amount);
				quotedRate = ((100 - discountPercentage) / 100) * unitPrice;
			} else if (!baseAdjustmentAmountIsEmpty && adjustedUnitPrice !== null) {
				discountPercentage = parseFloat(quoteItem.adjustment.amount);
				quotedRate = parseFloat(adjustedUnitPrice);
			}

			let marginPercent = null;
			if (unitCost !== null && quotedRate !== null) {
				marginPercent = QuoteConfigurator.marginPercentage(quotedRate, unitCost);
			}

			quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = marginPercent;
			quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName] = selectedRateCardItem[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName];
			quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName] = unitPrice;

			if (nonBillable === true) { // when non-billable blank out adjusted unit price field
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = 0;
			} else {
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = quotedRate;
				quoteItem.adjustment.amount = discountPercentage;
			}

			quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName] = unitCost;
		} else {
			quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName] = null;
			quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName] = null;
			quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
			quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName] = null;
			quoteItem.adjustment.amount = null;
			quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = null;
		}

		const data = [
			[row, QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName]],
			[row, QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]],
			[row, QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]],
			[row, 'baseAdjustmentAmount', quoteItem.adjustment.amount],
			[row, QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName, quoteItem.quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName]],
		];

		this.grid.setDataAtRowProp(data, 'setPricePoints');
	}

	static isNullOrUndefined(obj) {
		return obj === null || typeof obj === 'undefined';
	}

	async getRateCardItemsFor(productId) {
		if (!this.rateCardItems[productId]) {
			this.rateCardItems[productId] = JSON.parse(
				await getRateCardItemsForProduct({
					quoteId: this.recordId,
					productId,
				}),
			).map((item) => item.fieldValueMap);
		}

		return this.rateCardItems[productId];
	}

	async getQuoteItemForRow(row) {
		const { $id } = await this.grid.getCellMeta(row, 0);
		return this.quoteItems[$id];
	}

	getPropIdx(propName) {
		return this.columnMetadata.findIndex((item) => item.data === propName);
	}

	getSelectedRateCardAttributes(quoteItem) {
		const rateCardAttributes = this.getRateCardAttributes();
		const selectedAttributes = [];
		for (let i = 0; i < rateCardAttributes.length; i++) {
			const { fieldName } = rateCardAttributes[i];
			const attributeValue = quoteItem[fieldName];
			if (!isNullOrUndefined(attributeValue)) {
				selectedAttributes.push(fieldName);
			}
		}

		return selectedAttributes;
	}

	async setAvailablePracticeAndSkill(row) {
		const quoteItem = await this.getQuoteItemForRow(row);
		const rateCardAttributes = this.getRateCardAttributes();
		const { productId } = quoteItem;
		const selectableValues = {};
		if (!productId) {
			// If no product is selected, then all values are selectable
			for (let i = 0; i < rateCardAttributes.length; i++) {
				const { fieldName, dataType, pickListValues } = rateCardAttributes[i];
				const isPicklist = dataType === 'PICKLIST';
				const optionsForAttribute = { '': true };
				if (isPicklist) {
					for (let j = 0; j < pickListValues.length; j++) {
						const picklistValue = pickListValues[j];
						optionsForAttribute[picklistValue] = true;
					}
				}

				selectableValues[fieldName] = optionsForAttribute;
			}
		} else {
			let validRateCards = await this.getRateCardItemsFor(productId);
			if (rateCardAttributes.length > 0) {
				validRateCards = validRateCards.filter((item) => {
					let matches = true;
					for (let i = 0; i < rateCardAttributes.length; i++) {
						const { fieldName } = rateCardAttributes[i];
						const attributeValue = quoteItem.quoteItemSO[fieldName] || '';
						matches = matches
							&& (attributeValue === ''
								|| (item[fieldName] || '') === attributeValue);
					}

					return matches;
				});

				for (let i = 0; i < rateCardAttributes.length; i++) {
					const { fieldName } = rateCardAttributes[i];
					const fieldMeta = this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, fieldName);
					let optionsForAttribute = selectableValues[fieldName];
					if (!optionsForAttribute) {
						optionsForAttribute = {};
						selectableValues[fieldName] = optionsForAttribute;
					}

					if (!fieldMeta || fieldMeta.dataType === 'PICKLIST') {
						optionsForAttribute[''] = true;
					}
				}
			}

			validRateCards.forEach((rateCard) => {
				for (let i = 0; i < rateCardAttributes.length; i++) {
					const { fieldName } = rateCardAttributes[i];
					const columnsMetadata = this.getColumnMetadata(fieldName);
					const optionsForAttribute = selectableValues[fieldName];
					const rateCardAttributeValue = rateCard[fieldName];
					const isPicklist = columnsMetadata.type === 'PICKLIST';
					if (!isPicklist || columnsMetadata.source.indexOf(rateCardAttributeValue) > -1) {
						optionsForAttribute[rateCardAttributeValue] = true;
					}
				}
			});
		}

		const attributesToUpdate = Object.keys(selectableValues);
		for (let i = 0; i < attributesToUpdate.length; i++) {
			const attributeName = attributesToUpdate[i];
			const selectableOptions = selectableValues[attributeName];
			const attributeColIdx = this.getPropIdx(attributeName);
			// Assumed that all atributes are displayed as a picklist
			await this.grid.setCellMeta(row, attributeColIdx, 'source', Object.keys(selectableOptions)
				.sort());
		}
	}

	getRateCardItemAttributeColumnMeta() {
		const columns = [];
		for (let i = 0; i < this._quoteFields.length; i++) {
			const fieldMetadata = this._quoteFields[i];

			const {
				dataType, fieldName, fieldLabel, sourceObject,
			} = fieldMetadata;

			if (sourceObject === RATE_CARD_ITEM_OBJECT.objectApiName) {
				const column = {
					group: ColumnGroup.RATE_ATTRIBUTE,
					data: fieldName,
					apiName: fieldName,
					type: 'text',
					label: fieldLabel,
					readOnly: true,
				};

				if (dataType === 'PICKLIST') {
					column.source = fieldMetadata.pickListValues;
				} else if (dataType === 'CURRENCY') {
					column.type = 'numeric';
					column.numericFormat = {
						pattern: '$0,0.00',
						culture: 'en-US',
					};
				}

				columns.push(column);
			}
		}

		return columns;
	}

	getFieldMeta(forObject, forField) {
		if (!this._fieldsByTypeByName) {
			this._fieldsByTypeByName = {};

			for (let i = 0; i < this._quoteFields.length; i++) {
				const fieldMeta = this._quoteFields[i];
				const { sourceObject, fieldName } = fieldMeta;
				let fieldsForObject = this._fieldsByTypeByName[sourceObject];
				if (!fieldsForObject) {
					fieldsForObject = {};
					this._fieldsByTypeByName[sourceObject] = fieldsForObject;
				}

				fieldsForObject[fieldName] = fieldMeta;
			}
		}

		return this._fieldsByTypeByName[forObject] && this._fieldsByTypeByName[forObject][forField];
	}

	getPricingColumnMetadata() {
		return [{
			group: ColumnGroup.PRICING_ATTRIBUTE,
			data: QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName,
			apiName: QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName,
			type: 'numeric',
			label: this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName).fieldLabel,
			numericFormat: {
				pattern: '$0,0.00',
				culture: 'en-US',
			},
			readOnly: true,
		},
		{
			group: ColumnGroup.PRICING_ATTRIBUTE,
			data: QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName,
			apiName: QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName,
			type: 'numeric',
			label: this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName).fieldLabel,
			numericFormat: {
				pattern: '$0,0.00',
				culture: 'en-US',
			},
			readOnly: true,
		},
		{
			group: ColumnGroup.PRICING_ATTRIBUTE,
			data: 'baseAdjustmentAmount',
			apiName: 'baseAdjustmentAmount',
			label: LABEL_DISCOUNT_PERCENT,
			type: 'numeric',
			numericFormat: {
				pattern: '0,0.00',
				culture: 'en-US',
			},
		},
		{
			group: ColumnGroup.PRICING_ATTRIBUTE,
			data: QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName,
			apiName: QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName,
			type: 'numeric',
			label: this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName).fieldLabel,
			numericFormat: {
				pattern: '$0,0.00',
				culture: 'en-US',
			},
		},
		{
			group: ColumnGroup.PRICING_ATTRIBUTE,
			data: QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName,
			apiName: QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName,
			label: this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName).fieldLabel,
			type: 'numeric',
			numericFormat: {
				pattern: '0,0.00',
				culture: 'en-US',
			},
			readOnly: true,
		}];
	}

	getPeriodColumnMetadata() {
		const periodColumnMetadata = [];
		let periodCounter = 0;

		Object.keys(this.periodsByGroup).forEach((periodGroupId) => {
			const { name: periodGroupName } = this.periodGroups[periodGroupId];
			const periods = this.periodsByGroup[periodGroupId];
			for (let i = 0; i < periods.length; i++) {
				const period = periods[i];
				periodColumnMetadata.push({
					data: `${periodCounter + 1}`.padStart(3, '0'),
					type: 'numeric',
					isPeriod: true,
					id: period.id,
					label: period.name,
				});
				periodCounter += 1;
			}

			periodColumnMetadata.push({
				data: `NamedRange__${periodGroupId}__mdt`,
				type: 'numeric',
				readOnly: true,
				isTotal: true,
				label: `${periodGroupName} ${LABEL_TOTAL}`,
				numericFormat: {
					pattern: '$0,0.00',
					culture: 'en-US',
				},
			});
		});

		return periodColumnMetadata;
	}

	getColumnMetadata(columnName) {
		if (!this._columnsByName) {
			this._columnsByName = {};

			for (let i = 0; i < this.columnMetadata.length; i++) {
				const columnMeta = this.columnMetadata[i];
				this._columnsByName[columnMeta.data] = columnMeta;
			}
		}

		return this._columnsByName[columnName];
	}

	buildColumnMetadata() {
		this.columnMetadata = [];

		if (Object.values(this.sections).length) {
			this.columnMetadata.push({
				data: 'sectionName',
				renderer: 'sectionName',
				label: LABEL_SECTION,
				readOnly: true,
			});
		}

		this.columnMetadata.push({
			data: 'productName',
			type: 'text',
			label: LABEL_ROLE,
			isRoleColumn: true,
			readOnly: true,
		});

		this.columnMetadata.push(...this.getRateCardItemAttributeColumnMeta());
		this.columnMetadata.push(...this.getPricingColumnMetadata());
		// divider between attributes and periods
		this.columnMetadata.push({
			data: 'Empty__mdt',
			readOnly: true,
			label: '',
		});

		this.columnMetadata.push(...this.getPeriodColumnMetadata());
		this.columnMetadata.push({
			data: 'NamedRange__GrandTotal__mdt',
			type: 'numeric',
			readOnly: true,
			isTotal: true,
			label: LABEL_GRAND_TOTAL,
			numericFormat: {
				pattern: '$0,0.00',
				culture: 'en-US',
			},
		});

		return this.columnMetadata;
	}

	static padColumns(columnToPad, totalLength) {
		const columns = columnToPad;
		let totalSpan = 0;

		columns.forEach((column) => {
			if (typeof column === 'string') {
				totalSpan += 1;
			} else {
				totalSpan += column.colspan;
			}
		});

		const remainingColSpan = totalLength - totalSpan;
		if (remainingColSpan) {
			if (remainingColSpan !== 1) {
				const lastEntry = columns[columns.length - 1];
				if (typeof lastEntry === 'string') {
					columns[columns.length - 1] = {
						label: '',
						colspan: 1 + (remainingColSpan - 1),
					};
				} else {
					lastEntry.colspan += remainingColSpan - 1;
				}
			}

			columns.push({ label: '', colspan: 1 }); // blank entry for totals column
		}

		return columns;
	}

	periodColumnsOffset() {
		if (this._periodColumnsOffset === null || this._periodColumnsOffset === undefined) {
			let i = 0;
			for (; i < this.columnMetadata.length; i++) {
				const { isPeriod } = this.columnMetadata[i];
				if (isPeriod === true) {
					break;
				}
			}

			this._periodColumnsOffset = i;
		}

		return this._periodColumnsOffset;
	}

	getColumnHeaders() {
		const hasSections = Object.values(this.sections).length > 0;
		const lastRow = [...this.columnMetadata.map((meta) => meta.label)];
		const sortedPeriodGroups = [];
		this.periods.forEach((period) => {
			if (sortedPeriodGroups.indexOf(period.periodGroupId) < 0) {
				sortedPeriodGroups.push(period.periodGroupId);
			}
		});

		const periodRow = QuoteConfigurator.padColumns(
			[
				{ label: '', colspan: this.periodColumnsOffset() },
				...sortedPeriodGroups.map((periodGroupId) => {
					const { name } = this.periodGroups[periodGroupId];
					return {
						label: name,
						colspan: this.periodsByGroup[periodGroupId].length + 1,
					};
				}),
			],
			lastRow.length,
		);

		const headerRows = [periodRow];
		const phaseHeaders = this.getPhaseHeaders();
		if (phaseHeaders.length) {
			headerRows.push(
				QuoteConfigurator.padColumns(
					[
						{ label: '', colspan: 3 + (hasSections ? 1 : 0) },
						{ label: this.quoteTimePeriod, colspan: 2 },
						{ label: '', colspan: 4 },
						...phaseHeaders,
						'',
					],
					lastRow.length,
				),
			);
		}

		headerRows.push(lastRow);

		return headerRows;
	}

	async performNameModalAction() {
		const { start } = this.selectedRange;
		const sectionName = this.template.querySelector('.nameInput');
		switch (this.modalAction) {
			case 'create_section':
				if (!sectionName.value) {
					return;
				}

				this.createSection(start.row + 1, sectionName.value);
				break;
			case 'rename_role':
				this.renameRole();
				break;
			case 'edit_section':
				this.renameSection();
				break;
			default:
				this.createOrUpdatePhase();
		}
	}

	async renameRole() {
		try {
			const { start } = this.selectedRange;
			const selectedRow = this.rowMetadata[start.row];
			const newResourceName = this.template.querySelector('.nameInput').value;
			this.isNameModalOpen = false;

			if (newResourceName && selectedRow?.productId) {
				this.updateRoleDisplayNames(start.row, newResourceName);
			}
		} catch (e) {
			this.toastError(e);
		}
	}

	async renameSection() {
		const { start } = this.selectedRange;
		const selectedRow = this.rowMetadata[start.row];
		const newSectionName = this.template.querySelector('.nameInput').value;
		const oldName = this.sections[selectedRow.$id].elementDO.name;
		this.isNameModalOpen = false;

		if (newSectionName !== oldName) {
			this.sections[selectedRow.$id].elementDO.name = newSectionName;
			const sectionHeaderData = await this.grid.getDataAtCell(start.row, 0);
			// 1.2.[regex matches this empty space]Section Name
			const spaceMatch = /\s/;
			const match = sectionHeaderData.match(spaceMatch);
			this.grid.setDataAtCell(start.row, 0, `${sectionHeaderData.substring(0, match.index)} ${newSectionName}`);

			try {
				await this._quoteService.saveSections();
			} catch (e) {
				// in case of error revert back to original name
				this.sections[selectedRow.$id].elementDO.name = oldName;
				this.grid.setDataAtCell(start.row, 0, oldName);
				this.toastError(e);
			}
		}
	}

	async batchRender(callback) {
		await this.grid.suspendRender();
		callback();
		this.grid.resumeRender();
	}

	async updateRoleDisplayNames(rowIdx, newValue) {
		const roleNameColumnIndex = Object.keys(this.sections).length > 0 ? 1 : 0; // column index is pushed over when sections exist, otherwise the zero-index column
		const rowMeta = this.rowMetadata[rowIdx];
		const product = this.productsById[rowMeta.productId];
		const quoteItem = this.quoteItems[rowMeta.$id];
		quoteItem.quoteItemSO[QUOTE_ITEM_ROLE_NAME_OVERRIDE_FIELD.fieldApiName] = newValue;
		this.grid.setDataAtCell(rowIdx, roleNameColumnIndex, `${newValue} (${product.name})`);
		this._quoteService.saveLines();
	}

	getRowItems() {
		return this.rowMetadata
			.filter(QuoteConfigurator.isQuoteItem)
			.map(({ $id }) => this.quoteItems[$id]);
	}

	getSortedRowItems() {
		return this.rowMetadata
			.filter(QuoteConfigurator.isQuoteItem)
			.map(({ $id }) => this.quoteItems[$id])
			.sort((a, b) => (a.elementDO.lineSequence > b.elementDO.lineSequence ? 1 : -1));
	}

	getQuoteItemsRowIndices() {
		const rowIndices = [];
		for (let i = 0; i < this.rowMetadata.length; i++) {
			const rowMeta = this.rowMetadata[i];
			if (QuoteConfigurator.isQuoteItem(rowMeta)) {
				rowIndices.push(i);
			}
		}

		return rowIndices;
	}

	columnIndicesFor(group) {
		const columnIndices = [];
		for (let i = 0; i < this.columnMetadata.length; i++) {
			const column = this.columnMetadata[i];
			if (column.group === group) {
				columnIndices.push(i);
			}
		}

		return columnIndices;
	}

	getRowItem(meta) {
		return QuoteConfigurator.isQuoteItem(meta) ? this.quoteItems[meta.$id] : null;
	}

	static isQuoteItem(meta) {
		return !meta.isSectionHeader && !meta.isSectionFooter && !meta.isQuantityFooter && !meta.isAmountFooter;
	}

	newSection(at, name) {
		const newSection = Provus.Section.for(this.newSectionDO());
		newSection.name = name;
		newSection.quoteId = this.recordId;
		newSection.startRow = at;
		this.sections[newSection.$id] = newSection;
		this.rowMetadata.splice(at, 0, newSection.metadata());
		return newSection;
	}

	newSectionDO() {
		return {
			...Provus.Section.newDO({}),
			sequence: this.getNextSectionSequenceNumber(),
			quoteId: this.recordId,
		};
	}

	createSectionRelationship(child, parent) {
		const from = child;
		const to = parent;
		from.elementDO.parentSectionId = to.elementDO.id;
		to.childSections.unshift(from);
		from.setParent(to);
		return this;
	}

	async createSection(at, name) {
		const newSection = this.newSection(at, name);
		if (this.sectionHierarchy === 'Nested') {
			const targetMeta = await this.grid.getCellMeta(at, 0);
			const targetRow = this.sections[targetMeta.$id] || this.quoteItems[targetMeta.$id];
			const parentSection = targetRow?.parent;
			if (parentSection) {
				newSection.setParent(parentSection);
			}
		}

		this.assignChildren();
		const sections = Object.values(this.sections).sort(Provus.Section.ascendingBySequence);
		if (sections.length) {
			const lastSection = sections[sections.length - 1];
			const lastSectionRowNumber = this.findSectionRowNumberFor(lastSection);
			if (lastSectionRowNumber + lastSection.quoteItems.length < newSection.startRow) {
				newSection.startRow = lastSectionRowNumber + lastSection.quoteItems.length + 3;
			}
		}

		if (!Object.keys(this.sections).length) {
			this._periodColumnsOffset = undefined; // force recalc
		}

		// rebuild the column metadata
		const columns = this.buildColumnMetadata();
		const { data, metadata } = this.buildRows();
		const mergeCells = this.buildMergeCells(metadata);
		const cellOptions = this.buildCellOptions(metadata);

		this.isNameModalOpen = false;
		this.selectedRange = null;

		await this.grid.updateSettings({
			cell: cellOptions,
			data,
			columns,
			mergeCells,
			fixedColumnsLeft: 2,
			nestedHeaders: this.getColumnHeaders(),
		});

		await this.initializeCells(metadata, true);

		this.updateSectionTotals();
		this.updatePeriodGroupTotals();
		this._quoteService.saveSections();
	}

	buildSectionRowData() {
		const self = this;
		const newRows = [];
		const rootItems = this.rootItems.sort(Provus.Section.ascendingByDisplaySequence);
		const lockedQuoteSectionIds = [];
		const collaborationRequestsMap = {};
		this.rowMetadata = [];
		this.collaborationRequests.forEach((collabRequest) => {
			if (this.isSectionLocked(collabRequest)) {
				lockedQuoteSectionIds.push(collabRequest[SECTION_ID_FIELD.fieldApiName]);
				collaborationRequestsMap[collabRequest[SECTION_ID_FIELD.fieldApiName]] = collabRequest;
			}
		});

		let nextIndex = 0;
		rootItems.forEach((nextChild) => {
			if (nextChild.$type === Provus.Section.TYPE) {
				buildSectionTree(nextChild, nextIndex);
				nextIndex += 1;
			} else {
				newRows.push(...self.buildQuoteItemRowData([nextChild]));
				self.rowMetadata.push(nextChild.metadata());
			}
		});

		function buildSectionTree(nextSection, index, parentHeading = '') {
			const section = nextSection;
			section.setLocked(lockedQuoteSectionIds.includes(section.id));
			section.setRevocable(lockedQuoteSectionIds.includes(section.id));

			const sectionNumber = `${parentHeading}${index + 1}.`;
			let sectionName = `${sectionNumber} ${section.name}`;
			const collaboratorUserRFieldName = COLLABORATOR_USER_ID_FIELD.fieldApiName.replace('__c', '__r');
			if (lockedQuoteSectionIds.includes(section.id)) {
				sectionName += ` - ${collaborationRequestsMap[section.id][STATUS_FIELD.fieldApiName].toString()}: 
				${collaborationRequestsMap[section.id][collaboratorUserRFieldName].Name.toString()}`;
			}

			const headerRow = self.buildSectionRow(section);
			headerRow.sectionName = sectionName;
			newRows.push(headerRow);
			self.rowMetadata.push(section.metadata());

			if (nextSection.children.length > 0) {
				let nextChildIndex = 0;
				nextSection.children.forEach((nextChild) => {
					if (nextChild.$type === Provus.Section.TYPE) {
						buildSectionTree(nextChild, nextChildIndex, `${sectionNumber}`);
						nextChildIndex += 1;
					} else {
						newRows.push(...self.buildQuoteItemRowData([nextChild]));
						self.rowMetadata.push(nextChild.metadata());
					}
				});
			}

			// newRows.push(...self.buildSectionFooter(section));
		}

		return newRows;
	}

	buildSectionFooter(section) {
		const headCountFooter = {
			canAddRowAbove: true,
			canAddRowBelow: false,
		};

		headCountFooter[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = `${section.name} Total Person ${this.quoteTimePeriod}`;

		const amountFooter = {
			canAddRowAbove: false,
			canAddRowBelow: true,
		};

		amountFooter[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = `${section.name} ${LABEL_TOTAL}`;

		this.rowMetadata.push(
			{
				isSectionFooter: true,
				isQuantityFooter: true,
				readOnly: true,
				className: 'sectionFooter',
			},
			{
				isSectionFooter: true,
				isAmountFooter: true,
				readOnly: true,
				className: 'sectionFooter',
			},
		);

		return [headCountFooter, amountFooter];
	}

	/**
	 * Section is locked in the following collaboration scenarios:
	 * Collaboration Quote - Status is Merged or Ready to Merge
	 * Main Quote - Status is Accepted, Ready to Merge, or Assigned
	 * @param {object} request
	 * @returns {boolean}
	 */
	isSectionLocked(request) {
		if (this.isCollaborationQuote()) {
			return request[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.MERGED
				|| request[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.READY_TO_MERGE;
		}

		return request[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.ACCEPTED
			|| request[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.READY_TO_MERGE
			|| request[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.ASSIGNED;
	}

	buildSectionRow(section) {
		const headerRow = {};
		for (let i = 0; i < this.columnMetadata.length; i++) {
			const columnName = this.columnMetadata[i].data;
			headerRow[columnName] = null;
		}

		headerRow.isSectionLocked = section?.isLocked();
		headerRow.isRevocable = section?.isRevocable();
		headerRow.canAddRowAbove = true;
		headerRow.canAddRowBelow = !section?.isLocked();
		headerRow.$treeLevel = section?.$treeLevel || 0;

		return headerRow;
	}

	buildCellOptions(rowMetadata) {
		const cellOptions = [];
		const periodOffset = this.periodColumnsOffset();
		rowMetadata.forEach((rowMeta, rowIdx) => {
			const { isAmountFooter, isQuantityFooter, $id } = rowMeta;
			const quoteItem = this.quoteItems[$id];
			if (isAmountFooter) {
				cellOptions.push({
					row: rowIdx,
					col: periodOffset - 2,
					readOnly: true,
					type: 'text',
				});

				for (let i = periodOffset; i < this.columnMetadata.length; i++) {
					cellOptions.push({
						row: rowIdx,
						col: i,
						numericFormat: {
							pattern: '$0,0.00',
							culture: 'en-US',
						},
						type: 'numeric',
					});
				}
			} else if (isQuantityFooter) {
				const periodsByGroup = Object.values(this.periodsByGroup);
				let periodCounter = 0;
				for (let i = 0; i < periodsByGroup.length; i++) {
					const columnIdx = periodOffset + periodCounter + periodsByGroup[i].length + i;
					cellOptions.push({
						row: rowIdx,
						col: columnIdx,
						numericFormat: {
							pattern: '0.00',
							culture: 'en-US',
						},
					});

					periodCounter += periodsByGroup[i].length;
				}

				cellOptions.push({
					row: rowIdx,
					col: this.columnMetadata.length - 1,
					numericFormat: {
						pattern: '0.00',
						culture: 'en-US',
					},
				});
			} else if (quoteItem?.parent?.isLocked()) {
				for (let i = 0; i < this.columnMetadata.length; i++) {
					cellOptions.push({
						row: rowIdx,
						col: i,
						readOnly: true,
					});
				}
			}
		});

		// Make sure the dropdown toggle is hidden for the last 2 rows
		for (let i = 1; i < 3; i++) {
			cellOptions.push({
				row: rowMetadata.length - i,
				col: 0,
				type: 'text',
			});
		}

		return cellOptions;
	}

	buildMergeCells(rowMetadata) {
		const mergeCells = [];
		const periodOffset = this.periodColumnsOffset();
		rowMetadata.slice(0, rowMetadata.length - 2).forEach((rowMeta, rowIdx) => {
			const { isSectionFooter, isSectionHeader } = rowMeta;
			if (isSectionFooter || isSectionHeader) {
				mergeCells.push({
					row: rowIdx,
					col: 0,
					rowspan: 1,
					colspan: isSectionFooter ? periodOffset - 2 : this.columnMetadata.length,
				});
			}
		});

		mergeCells.push(
			{
				row: rowMetadata.length - 2,
				col: 0,
				rowspan: 1,
				colspan: periodOffset - 2,
			},
			{
				row: rowMetadata.length - 1,
				col: 0,
				rowspan: 1,
				colspan: periodOffset - 2,
			},
		);

		return mergeCells;
	}

	buildRows() {
		const data = this.buildSectionRowData();
		// totals row
		let quoteTotalAmount = 0;
		let quoteTotalQty = 0;
		if (this.quoteNamedRange) {
			const { totalAmount, totalQuantity } = this.quoteNamedRange.relatedTotal;
			quoteTotalAmount = totalAmount;
			quoteTotalQty = totalQuantity;
		}

		const headCountFooter = {
			NamedRange__GrandTotal__mdt: quoteTotalQty,
			canAddRowAbove: true,
			canAddRowBelow: false,
		};

		headCountFooter[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = `Total Person ${this.quoteTimePeriod}`;

		const amountFooter = {
			NamedRange__GrandTotal__mdt: quoteTotalAmount,
			canAddRowAbove: false,
			canAddRowBelow: false,
		};

		amountFooter[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = 'Total Amount';

		data.push(
			headCountFooter,
			amountFooter,
		);

		this.rowMetadata.push(
			{ isQuantityFooter: true, readOnly: true, className: 'quantityFooter' },
			{ isAmountFooter: true, readOnly: true },
		);

		return {
			data,
			metadata: this.rowMetadata,
		};
	}

	buildQuoteItemRowData(rowItems) {
		return rowItems.map((item) => {
			const product = this.productsById[item.productId];
			const isSectionLocked = item.parent?.isLocked();
			const overrideRoleName = item.quoteItemSO[QUOTE_ITEM_ROLE_NAME_OVERRIDE_FIELD.fieldApiName];

			return {
				...item.quoteItemSO,
				...item.periodValueMap,
				isSectionLocked,
				isQuoteItem: true,
				baseAdjustmentAmount: item.adjustment.amount,
				productName: overrideRoleName ? `${overrideRoleName} (${product.name})` : product?.name,
				canAddRowAbove: !isSectionLocked,
				canAddRowBelow: !isSectionLocked,
			};
		});
	}

	async calculateRowTotals(startRow, colIdx, numberOfRows) {
		let totalPrice = 0;
		let totalHeadCount = 0;
		for (let rowIdx = startRow, rowCount = 0; rowCount < numberOfRows; rowCount++) {
			const { HeadCount, TotalPrice } = await this.grid.getCellMeta(rowIdx, colIdx);
			totalPrice += TotalPrice || 0;
			totalHeadCount += HeadCount || 0;
			rowIdx += 1;
		}

		return {
			HeadCount: totalHeadCount,
			TotalPrice: totalPrice,
		};
	}

	/**
	 * Finds the section row number for the given section
	 * using rowMetadata. Row numbers start from 1.
	 * @param {object} section
	 * @returns {number}
	 */
	findSectionRowNumberFor(section) {
		return this.rowMetadata.findIndex((row) => row.$id === section.$id) + 1;
	}

	async updateSectionTotals() {
		const isDisabled = true; // disabled for now
		if (isDisabled) {
			return;
		}

		const columnUpdates = [];
		const sections = Object.values(this.sections).sort(Provus.Section.ascendingBySequence);
		if (sections.length) {
			for (let i = 0; i < sections.length; i++) {
				const section = sections[i];
				for (
					let colIdx = this.periodColumnsOffset();
					colIdx < this.columnMetadata.length;
					colIdx++
				) {
					const sectionRowNumber = this.findSectionRowNumberFor(section);
					const sectionQuoteItemCount = section.quoteItems.length;

					const { HeadCount, TotalPrice } = await this.calculateRowTotals(
						sectionRowNumber,
						colIdx,
						sectionQuoteItemCount,
					);

					columnUpdates.push(
						[sectionRowNumber + sectionQuoteItemCount, colIdx, HeadCount],
						[sectionRowNumber + sectionQuoteItemCount + 1, colIdx, TotalPrice],
					);
				}
			}

			const rowCount = await this.grid.countRows();
			const lastSection = sections[sections.length - 1];
			const lastSectionRowNumber = this.findSectionRowNumberFor(lastSection);
			const endSlice = lastSectionRowNumber + lastSection.quoteItems.length + 3;
			for (let colIdx = this.periodColumnsOffset(); colIdx < this.columnMetadata.length; colIdx++) {
				const { HeadCount, TotalPrice } = await this.calculateRowTotals(
					endSlice,
					colIdx,
					rowCount - endSlice - 5,
				);

				columnUpdates.push([rowCount - 4, colIdx, TotalPrice], [rowCount - 5, colIdx, HeadCount]);
			}

			if (columnUpdates.length) {
				this.grid.setDataAtCell(columnUpdates);
			}
		}
	}

	validateDialogInput(event) {
		const textInput = event.detail.value.trim();
		this.disableButton = textInput.length === 0;
	}

	async createOrUpdatePhase() {
		const { start } = this.selectedRange;
		const lastRowIdx = (await this.grid.countRows()) - 1;
		const { phase } = await this.grid.getCellMeta(lastRowIdx, start.col);
		if (phase) {
			await this.updatePhase(phase.$id);
		} else {
			await this.createPhase();
		}

		this.isNameModalOpen = false;
		this.selectedRange = null;

		this.grid.updateSettings({
			nestedHeaders: this.getColumnHeaders(),
		});

		this._quoteService.savePhases();
	}

	updatePhase(phaseId) {
		const contextPhase = this._phasesById[phaseId];
		const phaseNameInput = this.template.querySelector('.nameInput');

		contextPhase.name = phaseNameInput.value;
		contextPhase.parentProjectName = phaseNameInput.value;
		this._quoteService.savePhases();
	}

	async createPhase() {
		const { start, end } = this.selectedRange;
		const { col: startCol } = start;
		const { col: endCol } = end;
		const phaseName = this.template.querySelector('.nameInput').value;
		const startColumnMeta = this.columnMetadata[startCol].data;
		const endColumnMeta = this.columnMetadata[endCol].data;
		const startPeriod = this.periods[Number(startColumnMeta) - 1];
		const endPeriod = this.periods[Number(endColumnMeta) - 1];
		let sequence = 1;
		if (this._phases.length !== 0) {
			sequence = this._phases[this._phases.length - 1].sequence + 1;
		}

		const phase = Provus.Phase.for(
			Provus.Phase.newDO({
				name: phaseName,
				quoteId: this.recordId,
				sequence,
				startDate: startPeriod.startDate,
				endDate: endPeriod.endDate,
				parentProjectName: phaseName,
			}),
		);

		phase.periodGroupId = endPeriod.periodGroupId;
		phase.startCol = startCol;
		phase.endCol = endCol;

		for (let i = startCol; i < endCol + 1; i++) {
			const periodNumber = this.columnMetadata[i].data;
			const period = this.periods[Number(periodNumber) - 1];
			phase.quotePeriodIdList.push(period.id);
		}

		this._phasesById[phase.$id] = phase;
		this._phases.push(phase);

		// mark as ready to insert
		phase.insert();

		const lastRow = (await this.grid.countRows()) - 1;
		for (let i = startCol; i < endCol + 1; i++) {
			this.grid.setCellMeta(lastRow, i, 'phase', { $id: phase.$id });
		}

		await this._quoteService.savePhases();
		this.updatePhaseTotals();
	}

	rebuildPhases(phaseMOs) {
		const periodById = {};
		this.periods.forEach((period) => {
			periodById[period.id] = period;
		});

		const columnIdxByPeriodId = {};
		for (let i = 0; i < this.columnMetadata.length; i++) {
			const meta = this.columnMetadata[i];
			if (meta.isPeriod === true) {
				columnIdxByPeriodId[meta.id] = i;
			}
		}

		this._phases = Provus.Phases.for(phaseMOs);

		for (let i = 0; i < this._phases.length; i++) {
			const phaseMO = this._phases[i];
			let startCol = null;
			let endCol = null;
			let startPeriod;

			phaseMO.quotePeriodIdList.forEach((periodId) => {
				const periodIdx = columnIdxByPeriodId[periodId];
				if (startCol === null || startCol > periodIdx) {
					startCol = periodIdx;
					startPeriod = periodById[periodId];
				}

				if (endCol === null || endCol < periodIdx) {
					endCol = periodIdx;
				}
			});

			phaseMO.startCol = startCol;
			phaseMO.endCol = endCol;
			phaseMO.periodGroupId = startPeriod && startPeriod.periodGroupId;
			this._phasesById[phaseMO.$id] = phaseMO;
		}

		return this._phases;
	}

	openNameModal(action, phaseRange) {
		this.isNameModalOpen = true;
		this.modalAction = action;
		[this.selectedRange] = phaseRange;
		this.grid.deselectCell();

		this.dialogInputTitle = 'Enter a name';
		this.dialogInputPlaceholder = 'Enter a name...';
		this.dialogInitialValue = '';

		// set action button label
		switch (action) {
			case 'create_section':
				this.dialogActionLabel = 'Create Section';
				break;
			case 'rename_phase':
				this.dialogActionLabel = 'Rename Phase';
				break;
			case 'create_phase':
				this.dialogActionLabel = 'Create Phase';
				break;
			case 'rename_role':
				this.dialogActionLabel = 'Rename Resource Role';
				break;

			case 'edit_section': {
				const { start } = this.selectedRange;
				const selectedRow = this.rowMetadata[start.row];
				this.dialogInitialValue = this.sections[selectedRow.$id].elementDO.name;
				this.dialogActionLabel = LABEL_EDIT_SECTION;
				break;
			}

			default:
				this.dialogActionLabel = 'Create Phase';
		}
	}

	closeNameModal() {
		this.isNameModalOpen = false;
	}

	getPhaseHeaders() {
		const phaseHeaders = [];
		if (this._phases.length) {
			const periodGroups = [];
			const phasesByGroup = {};
			const periodGroupSpan = {};
			const periodGroupStart = {};
			this._phases.forEach((phase) => {
				let groupSpanCount = periodGroupSpan[phase.periodGroupId];
				if (typeof groupSpanCount === 'undefined') {
					groupSpanCount = 0;
					phasesByGroup[phase.periodGroupId] = {};
				}

				phasesByGroup[phase.periodGroupId][phase.startCol] = phase;
				groupSpanCount += phase.numberOfPeriods();

				periodGroupSpan[phase.periodGroupId] = groupSpanCount;
			});

			this.periods.forEach((period, index) => {
				const touchedPeriodGroup = periodGroups.indexOf(period.periodGroupId) > -1;
				if (!touchedPeriodGroup) {
					for (let i = this.periodColumnsOffset(); i < this.columnMetadata.length; i++) {
						const periodNumber = Number(this.columnMetadata[i].data);
						if (periodNumber === index + 1) {
							periodGroupStart[period.periodGroupId] = i;
							break;
						}
					}

					periodGroups.push(period.periodGroupId);
				}
			});

			periodGroups.forEach((groupId) => {
				const phasesForGroup = phasesByGroup[groupId];
				if (phasesForGroup) {
					// build headers in order ascending order by start column
					const phaseTokens = Object.keys(phasesForGroup).sort((a, b) => (Number(a) < Number(b) ? -1 : 1));

					phaseTokens.forEach((token, index) => {
						const phase = phasesForGroup[token];
						let gap = 0;
						if (index !== 0) {
							const prevPhase = phasesForGroup[phaseTokens[index - 1]];
							gap = phase.startCol - prevPhase.endCol - 1;
						} else if (periodGroupStart[groupId] < phase.startCol) {
							gap = phase.startCol - periodGroupStart[groupId];
						}

						if (gap > 0) {
							periodGroupSpan[groupId] += gap;
							// Add an empty phase header to fill the gap between group starts
							phaseHeaders.push({
								label: '',
								colspan: gap,
							});
						}

						phaseHeaders.push({
							label: `${phase.name}`,
							colspan: phase.numberOfPeriods(),
						});
					});
				}

				// Add a blank header row from the last period end up to the end of the period group
				const remainingPeriodGroupLen = this.periodsByGroup[groupId].length - (periodGroupSpan[groupId] || 0) + 1;

				phaseHeaders.push({
					label: '',
					colspan: remainingPeriodGroupLen,
				});
			});
		}

		return phaseHeaders;
	}

	rebuildNamedRanges(namedRangeDOs, quoteItems) {
		if (namedRangeDOs && namedRangeDOs.length) {
			Provus.NamedRanges.for(namedRangeDOs).forEach((namedRange) => {
				this.namedRanges[namedRange.$id] = namedRange;

				const contextQuoteItem = quoteItems[namedRange.quoteItemId];
				const quoteItemTxnId = contextQuoteItem && contextQuoteItem.$id;
				switch (namedRange.type) {
					case 'Quote Item':
						this.quoteItemNamedRanges[quoteItemTxnId] = namedRange;
						break;
					case 'Quote Item Period Group':
						if (!this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId]) {
							this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId] = {};
						}

						this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId][namedRange.quotePeriodGroupId] = namedRange;
						break;
					case 'Quote Labor':
						this.quoteNamedRange = namedRange;
						break;
					case 'Quote':
						this.quoteTotalNamedRange = namedRange;
						break;
					case 'Project Phase':
						this._phaseNamedRanges[namedRange.projectPhaseId] = namedRange;
						break;
					default:
						break;
				}
			});
		}
	}

	/**
	 * Reloads the collaboration requests for this quote from the server.
	 * @returns {Promise<void>}
	 */
	async reloadCollaborationRequests() {
		const requests = await getCollaborationRequestsForQuote({ quoteId: this.recordId });
		this.collaborationRequests = JSON.parse(requests);
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

	async executeAndDisplayErrors(fn, args) {
		let result;
		try {
			result = await fn(args);
		} catch (e) {
			this.toastError(e);
		}

		return result;
	}

	async loadData(quoteId) {
		const self = this;

		const [quote, products, items, phases, sections, totals, collabRequests] = await Promise.all([
			this.executeAndDisplayErrors(getQuoteTemplate, { quoteId }),
			this.executeAndDisplayErrors(getAllProductsForQuote, { quoteId }),
			this.executeAndDisplayErrors(getQuoteItemsForQuote, { quoteId }),
			this.executeAndDisplayErrors(getProjectPhasesForQuote, { quoteId }),
			this.executeAndDisplayErrors(getQuoteSectionsForQuote, { quoteId }),
			this.executeAndDisplayErrors(getNamedRangesForQuote, { quoteId }),
			this.executeAndDisplayErrors(getCollaborationRequestsForQuote, { quoteId }),
		]);

		const {
			fieldsList = [],
			hasAddOns,
			isScenarioPricePending,
			marginPercent,
			quotePeriodList: periods,
			quoteTimePeriod,
			totalAmount,
			recordType,
			scheduleSettings,
			sectionHierarchy,
			practiceName,
			groupName,
			rateCardId,
			currencyFields,
		} = JSON.parse(quote);

		this.currencyISOCode = currencyFields.currencyISOCode;
		this.currencyConversionRatio = currencyFields.currencyConversionRatio;
		this.practice = practiceName;
		this.group = groupName;
		this.rateCardId = rateCardId;
		this.collaborationRequests = JSON.parse(collabRequests);
		this.recordType = recordType;
		this.sectionHierarchy = sectionHierarchy;
		this._scheduleSettings = {
			standardDayHours: parseInt(scheduleSettings.standardDayHours, 10),
			standardWeekHours: parseInt(scheduleSettings.standardWeekHours, 10),
			standardMonthHours: parseInt(scheduleSettings.standardMonthHours, 10),
			standardYearHours: parseInt(scheduleSettings.standardYearHours, 10),
		};
		this._quoteFields = fieldsList;
		this.quoteTimePeriod = quoteTimePeriod;
		this.periods = periods;
		this.quoteProducts = JSON.parse(products).filter(
			(product) => product.isMiscellaneous !== true,
		);
		this.quoteProducts.forEach((product) => {
			this.productsById[product.id] = product;
		});

		this.quoteItems = {};
		this.quoteItemsByLineSeq = {};
		const quoteItemsById = {};
		Provus.QuoteItems.for(JSON.parse(items))
			.filter((item) => item.isMiscellaneous !== true)
			.forEach((item) => {
				this.quoteItems[item.$id] = item;
				quoteItemsById[item.id] = item;
				this.quoteItemsByLineSeq[item.lineSequence] = item;

				if (!item.sectionId) {
					this.rootItems.push(item);
				}
			});

		let nextDisplaySequence = 1;
		Provus.Sections.for(JSON.parse(sections)).forEach(associateQuoteItems);

		function associateQuoteItems(section) {
			if (!section.parent) {
				const contextSection = section;
				self.rootItems.push(section);
				contextSection.elementDO.displaySequence = nextDisplaySequence;
				nextDisplaySequence += 1;
			}

			self.sections[section.$id] = section;

			if (section.quoteItemIdList || section.childSections) {
				// will be null if there are no children in this section
				const childItems = section.quoteItemIdList
					? section.quoteItemIdList
						.map((itemId) => quoteItemsById[itemId])
						.filter((item) => !!item)
					: [];

				section.spliceQuoteItems(0, 0, ...childItems);
			}

			if (section.children.length > 0) {
				section.children.forEach((nextChild) => {
					if (nextChild.$type === Provus.Section.TYPE) {
						associateQuoteItems(nextChild);
					}
				});
			}
		}

		// ensure a quote item/section when loading an empty/new quote
		if (this.rootItems.length === 0) {
			// set first row/cell as default selection for starting place
			const defaultSelectionRange = [{
				start: { row: 0, col: 0 },
				end: { row: 0, col: 0 },
			}];

			if (this.sectionHierarchy) {
				// allow cancellation of add resource role dialog
				this.handleOpenRoleDialog(ContextMenuActions.ROW_BELOW, defaultSelectionRange);
				this.rootItems.push(this.newSection(0, LABEL_DEFAULT_SECTION));
			} else {
				// disable cancellation of add resource dialog
				this.handleOpenRoleDialog(ContextMenuActions.ROW_BELOW, defaultSelectionRange, { showCloseButton: false });
			}
		}

		this.periodsByGroup = {};
		this.periodGroups = {};
		this.periodsBySequence = {};
		periods.forEach((period) => {
			let periodsForGroup = this.periodsByGroup[period.periodGroupId];
			if (!periodsForGroup) {
				periodsForGroup = [];
				this.periodsByGroup[period.periodGroupId] = periodsForGroup;
			}

			periodsForGroup.push(period);
			this.periodGroups[period.periodGroupId] = {
				name: period.periodGroupName,
			};
			this.periodsBySequence[period.sequence] = period.term;
		});

		const columns = this.buildColumnMetadata();
		this.rebuildNamedRanges(JSON.parse(totals), quoteItemsById);
		const { data, metadata } = this.buildRows();
		this.rebuildPhases(JSON.parse(phases));

		const locationMeta = this.getFieldMeta(QUOTE_ITEM_OBJECT.objectApiName, QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName);
		this.groupedTotals[QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName] = {
			marginPercent: {},
			totalAmount: {},
			totalCost: {},
			totalQuantity: {},
			field: QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName,
			label: locationMeta.fieldLabel,
		};

		const gridOptions = {
			colWidth: [200],
			className: 'slds-table',
			afterCreateRow: (...args) => this.afterCreateRow(...args),
			manualRowMove: true,
			startRows: 1,
			minSpareRows: 0,
			licenseKey: 'non-commercial-and-evaluation',
			data: data.length ? data : null,
			collapsibleColumns: false,
			columns,
			fixedColumnsLeft: Object.keys(this.sections).length > 0 ? 2 : 1,
			fixedRowsBottom: 2,
			colHeaders: true,
			rowHeaders: true,
			mergeCells: this.buildMergeCells(metadata),
			cell: this.buildCellOptions(metadata),
			contextMenu: new ContextMenu(this),
			afterChange: (...args) => this.onChange(...args),
			beforeRemoveRow: (...args) => this.onRemoveRows(...args),
			nestedHeaders: this.getColumnHeaders(),
			manualColumnFreeze: true,
			search: true,
			manualColumnMove: true,
			afterRowMove: (...args) => this.onRowMove(...args),
			beforeRowMove: Provus.Grid.IFrameFnFor(beforeRowMove),
			beforeColumnMove: Provus.Grid.IFrameFnFor(onColumnDrag),
			beforeOnCellMouseOver: Provus.Grid.IFrameFnFor(function onMouseOver(event, coords) {
				function checkDropArea(hot, targetCoordinates) {
					return function onMouseMove(mouseEvent) {
						const selectedRange = hot.getSelectedRange();
						if (selectedRange && selectedRange.length) {
							const { from, to } = selectedRange[0];
							const moveColumnPlugin = hot.getPlugin('ManualColumnMove');
							moveColumnPlugin.backlight._element.style.removeProperty('background');
							moveColumnPlugin.backlight._element.style.removeProperty('opacity');
							moveColumnPlugin.guideline._element.style.background = 'transparent';

							if (
								targetCoordinates.row >= -1
								&& targetCoordinates.col > -1
								&& (targetCoordinates.col > from.col || targetCoordinates.col < to.col)
							) {
								const lastRow = hot.countRows() - 1;
								const { phase } = hot.getCellMeta(lastRow, targetCoordinates.col);
								if (phase) {
									const targetCell = mouseEvent.target;
									const pointerOffset = mouseEvent.offsetX;
									const leftToRight = targetCoordinates.col > from.col;
									const triggerPosition = targetCell.offsetWidth / 2;
									// log(`targetCell offsetWidth: ${targetCell.offsetWidth}`);
									// log(`pointerOffset: ${pointerOffset}`);
									// log(`triggerPosition: ${triggerPosition}`);
									// log(`leftToRight: ${leftToRight}`);
									if (
										(!leftToRight && pointerOffset <= triggerPosition)
										|| (leftToRight && pointerOffset >= triggerPosition)
									) {
										moveColumnPlugin.backlight._element.style.background = 'green';
										moveColumnPlugin.backlight._element.style.opacity = '50%';
									}
								}
							}
						}
					};
				}

				if (Provus.Grid.MouseOverTarget !== event.target) {
					if (Provus.Grid.MouseOverTarget) {
						// drop old listener
						Provus.Grid.MouseOverTarget.removeEventListener(
							'mousemove',
							Provus.Grid.checkDropArea,
						);
						delete Provus.Grid.checkDropArea;
					}

					// attach new listener
					Provus.Grid.checkDropArea = checkDropArea(this, coords);
					Provus.Grid.MouseOverTarget = event.target;
					Provus.Grid.MouseOverTarget.addEventListener('mousemove', Provus.Grid.checkDropArea);
				}
			}),
			hiddenRows: {
				rows: [],
			},
			hiddenColumns: {
				columns: [],
			},
		};

		if (this.isCollaborationQuote() && !this.hasOutstandingRequests()) {
			gridOptions.readOnly = true;
			gridOptions.contextMenu = false;
			gridOptions.disableVisualSelection = true;
			gridOptions.manualColumnResize = false;
			gridOptions.manualRowResize = false;
			gridOptions.comments = false;
		}

		if (!this.isCollaborationQuote()) {
			this.actionsMap.merge.enabled = true;

			if (this.hasRequestsToMerge()) {
				this.actionsMap.merge.visible = true;
			}
		}

		this.rerender();

		return {
			options: gridOptions,
			metadata,
			isScenarioPricePending,
			totalAmount,
			marginPercent,
			hasAddOns,
		};
	}

	async updateTotalsFor(row) {
		return this.updateTotalsForRows([row]);
	}

	onRemoveRows(startIdx, numberOfRows, deletedRows) {
		const deletePromises = [];
		for (let i = 0; i < deletedRows.length; i++) {
			const row = deletedRows[i];
			const { $id } = this.rowMetadata[row];
			const quoteItem = this.quoteItems[$id];
			if (quoteItem && !isEmpty(quoteItem.id)) {
				deletePromises.push(this._quoteService.deleteQuoteItem(quoteItem));
				delete this.quoteItems[$id];
			}

			delete this.rowMetadata[row];

			if (quoteItem.parent) {
				quoteItem.parent.removeChild(quoteItem);
			}
		}

		if (Object.keys(this.quoteItems).length === 0
				&& !this.sectionHierarchy) {
			const defaultSelectionRange = [{
				start: { row: 0, col: 0 },
				end: { row: 0, col: 0 },
			}];

			this.handleOpenRoleDialog(ContextMenuActions.ROW_BELOW, defaultSelectionRange, { showCloseButton: false });
		}

		this.rowMetadata = this.rowMetadata.filter((element) => !!element);
		this.recomputeColumnTotals();
		this.updatePeriodGroupTotals();
		return Promise.all(deletePromises).catch((e) => {
			log('Failed to delete line items.');
			log(e);
		});
	}

	static newNamedRange(initialProperties) {
		return Provus.NamedRange.for(Provus.NamedRange.newDO(initialProperties));
	}

	async updatePeriodGroupTotals() {
		const rowCount = await this.grid.countRows();
		const periodGroupIds = Object.keys(this.periodsByGroup);
		const updateColumns = [];
		let totalColIdx = this.periodColumnsOffset();
		for (let groupIdx = 0; groupIdx < periodGroupIds.length; groupIdx++) {
			let totalPrice = 0;
			let totalQty = 0;

			totalColIdx += this.periodsByGroup[periodGroupIds[groupIdx]].length;

			for (let row = 0; row < rowCount; row++) {
				const { TotalPrice, HeadCount } = await this.grid.getCellMeta(row, totalColIdx);
				totalPrice += TotalPrice || 0;
				totalQty += HeadCount || 0;
			}

			updateColumns.push(
				[rowCount - 1, totalColIdx, totalPrice],
				[rowCount - 2, totalColIdx, totalQty],
			);

			totalColIdx += 1;
		}

		if (updateColumns.length) {
			await this.grid.setDataAtCell(updateColumns);
		}
	}

	async updateTotalsForRows(rows) {
		const totalUpdates = [];
		const groupedTotals = Object.values(this.groupedTotals);
		for (let i = 0; i < rows.length; i++) {
			const row = await this.grid.toPhysicalRow(rows[i]);
			// eslint-disable-next-line no-await-in-loop
			const { $id: quoteItemTxnId, id: quoteItemId, quoteItemSO } = await this.getQuoteItemForRow(row);
			const rowDetails = await this.getDataAtRow(row);
			const { periods } = rowDetails;
			const totalsForGroup = {};
			let grandTotal = 0;
			let grandTotalQty = 0;
			let grandTotalCost = 0;
			let periodCounter = 0;
			let columnCounter = 0;
			const periodGroupIds = Object.keys(this.periodsByGroup);
			const priceFieldIdx = this.columnMetadata.findIndex((colMeta) => colMeta.data === QUOTE_ITEM_UNIT_PRICE_FIELD.fieldApiName);
			const baseAdjustmentAmountFieldIdx = this.columnMetadata.findIndex((colMeta) => colMeta.data === 'baseAdjustmentAmount');
			for (let groupIdx = 0; groupIdx < periodGroupIds.length; groupIdx++) {
				const periodGroupId = periodGroupIds[groupIdx];
				const periodGroupName = this.periodGroups[periodGroupId].name;
				const groupStart = `${periodCounter + 1}`.padStart(3, '0');
				let groupTotal = 0;
				let groupTotalQty = 0;
				let groupTotalCost = 0;
				for (let j = 0; j < this.periodsByGroup[periodGroupId].length; j++) {
					const periodMetadata = this.periodsByGroup[periodGroupId][j];
					const periodNumber = `${periodCounter + 1}`.padStart(3, '0');
					const periodValue = periods[periodNumber] || 0;
					let unitPrice = rowDetails[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName];
					if (quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName]) {
						unitPrice = 0;
						this.grid.setCellMeta(row, priceFieldIdx, 'className', 'strike-out');
						this.grid.setCellMeta(row, baseAdjustmentAmountFieldIdx, 'className', 'strike-out');
					} else {
						this.grid.removeCellMeta(row, priceFieldIdx, 'className');
						this.grid.removeCellMeta(row, baseAdjustmentAmountFieldIdx, 'className');
					}

					const periodPrice = periodMetadata.term * periodValue * unitPrice;
					const periodCost = periodMetadata.term * periodValue * rowDetails[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName];
					const currentCol = this.periodColumnsOffset() + columnCounter;
					this.grid.setCellMeta(
						row,
						currentCol,
						'TotalPrice',
						periodPrice,
					);

					this.grid.setCellMeta(
						row,
						currentCol,
						'HeadCount',
						periodValue,
					);

					this.grid.setCellMeta(
						row,
						currentCol,
						'TotalCost',
						periodCost,
					);

					groupTotalCost += periodCost;
					groupTotal += periodPrice;
					groupTotalQty += periodValue;

					periodCounter += 1;
					columnCounter += 1;
				}

				let namedRangesForItem = this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId];
				if (!namedRangesForItem) {
					namedRangesForItem = {};
					this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId] = namedRangesForItem;
				}

				let namedRangeForGroup = namedRangesForItem[periodGroupId];
				if (!namedRangeForGroup) {
					namedRangeForGroup = QuoteConfigurator.newNamedRange({
						quoteId: this.recordId,
						quotePeriodGroupId: periodGroupId,
						type: 'Quote Item Period Group',
					});

					this.quoteItemPeriodGroupNamedRanges[quoteItemTxnId][periodGroupId] = namedRangeForGroup;
					this.namedRanges[namedRangeForGroup.$id] = namedRangeForGroup;
				}

				// set total value
				const { relatedTotal } = namedRangeForGroup;
				relatedTotal.totalAmount = groupTotal;
				relatedTotal.totalQuantity = groupTotalQty;
				relatedTotal.totalCost = groupTotalCost;
				relatedTotal.marginPercent = QuoteConfigurator.marginPercentage(groupTotal, groupTotalCost);
				namedRangeForGroup.name = `Row: ${row}, Period Group: ${periodGroupName}`;
				namedRangeForGroup.quoteItemId = quoteItemId;

				const periodGroupColumnName = `NamedRange__${periodGroupId.replace(/\s+/g, '')}__mdt`;
				// set cell range
				namedRangeForGroup.range(
					{
						row,
						colProp: groupStart,
					},
					{
						row,
						colProp: `${periodCounter - 1}`.padStart(3, '0'),
					},
					{
						totalAmount: {
							row: i,
							colProp: periodGroupColumnName,
						},
					},
				);

				const groupTotalColumn = this.periodColumnsOffset() + (periodCounter + (groupIdx + 1) - 1);
				this.grid.setCellMeta(row, groupTotalColumn, 'TotalPrice', groupTotal);
				this.grid.setCellMeta(row, groupTotalColumn, 'HeadCount', groupTotalQty);
				this.grid.setCellMeta(row, groupTotalColumn, 'TotalCost', groupTotalCost);

				totalsForGroup[`NamedRange__${periodGroupId.replace(/\s+/g, '')}__mdt`] = groupTotal;
				grandTotal += groupTotal;
				grandTotalQty += groupTotalQty;
				grandTotalCost += groupTotalCost;
				columnCounter += 1;
			}

			Object.keys(totalsForGroup).forEach((groupToken) => {
				const computedTotal = totalsForGroup[groupToken];
				totalUpdates.push([row, groupToken, computedTotal]);
			});

			let namedRangeForItem = this.quoteItemNamedRanges[quoteItemTxnId];
			if (!namedRangeForItem) {
				namedRangeForItem = QuoteConfigurator.newNamedRange({
					quoteId: this.recordId,
					quoteItemId,
					type: 'Quote Item',
				});

				this.quoteItemNamedRanges[quoteItemTxnId] = namedRangeForItem;
				this.namedRanges[namedRangeForItem.$id] = namedRangeForItem;
			}

			namedRangeForItem.name = `Row: ${row}`;
			namedRangeForItem.quoteItemId = quoteItemId;
			namedRangeForItem.relatedTotal.totalAmount = grandTotal;
			namedRangeForItem.relatedTotal.totalQuantity = grandTotalQty;
			namedRangeForItem.relatedTotal.totalCost = grandTotalCost;
			namedRangeForItem.relatedTotal.marginPercent = QuoteConfigurator.marginPercentage(grandTotal, grandTotalCost);

			quoteItemSO[QUOTE_ITEM_QUANTITY_FIELD.fieldApiName] = namedRangeForItem.relatedTotal.totalQuantity;
			quoteItemSO[QUOTE_ITEM_NETEXTENDEDAMOUNT_FIELD.fieldApiName] = namedRangeForItem.relatedTotal.totalAmount;
			quoteItemSO[QUOTE_ITEM_NETEXTENDEDCOST_FIELD.fieldApiName] = namedRangeForItem.relatedTotal.totalCost;
			quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = namedRangeForItem.relatedTotal.marginPercent;

			namedRangeForItem.range(
				{ row },
				{ row },
				{
					totalAmount: {
						row,
						colProp: 'NamedRange__GrandTotal__mdt',
					},
				},
			);

			totalUpdates.push([row, 'NamedRange__GrandTotal__mdt', grandTotal]);

			// set cell meta for the grand totals
			const {
				TotalPrice: previousAmt,
				HeadCount: previousQty,
				TotalCost: previousCost,
			} = await this.grid.getCellMeta(row, this.columnMetadata.length - 1);

			this.grid.setCellMeta(row, this.columnMetadata.length - 1, 'TotalPrice', grandTotal);
			this.grid.setCellMeta(row, this.columnMetadata.length - 1, 'HeadCount', grandTotalQty);
			this.grid.setCellMeta(row, this.columnMetadata.length - 1, 'TotalCost', grandTotalCost);

			quoteItemSO[QUOTE_ITEM_MARGIN_PERCENT_FIELD.fieldApiName] = QuoteConfigurator.marginPercentage(
				grandTotal,
				grandTotalCost,
			);

			for (let j = 0; j < groupedTotals.length; j++) {
				const groupedTotal = groupedTotals[j];
				const columnValue = quoteItemSO[groupedTotal.field];
				const totalTypes = Object.keys(groupedTotal);
				for (let p = 0; p < totalTypes.length; p++) {
					const totalType = totalTypes[p];
					if (totalType !== 'field' && totalType !== 'label') {
						switch (totalType) {
							case 'totalAmount':
								if (!groupedTotal[totalType][columnValue]) {
									groupedTotal[totalType][columnValue] = 0;
								}

								groupedTotal[totalType][columnValue] += grandTotal - (previousAmt || 0);
								break;
							case 'totalCost':
								if (!groupedTotal[totalType][columnValue]) {
									groupedTotal[totalType][columnValue] = 0;
								}

								groupedTotal[totalType][columnValue] += grandTotalCost - (previousCost || 0);
								break;
							case 'totalQuantity':
								if (!groupedTotal[totalType][columnValue]) {
									groupedTotal[totalType][columnValue] = 0;
								}

								groupedTotal[totalType][columnValue] += grandTotalQty - (previousQty || 0);
								break;
							default:
								break;
						}
					}
				}
			}
		}

		this.grid.setDataAtRowProp(totalUpdates);
		await this._quoteService.saveLines();
		this._quoteService.saveNamedRanges().catch((e) => {
			log('failed to save named ranges');
			log(e);
		});
	}

	getNextItemSequenceNumber() {
		this.baseItemSequenceNumber += 1;
		return this.baseItemSequenceNumber;
	}

	getNextSectionSequenceNumber() {
		this.baseSectionSequenceNumber += 1;
		return this.baseSectionSequenceNumber;
	}

	async getDataAtRow(rowIdx) {
		const gridArray = await this.grid.getDataAtRow(rowIdx);

		const rowData = {
			periods: {},
		};

		gridArray.forEach((gridValue, index) => {
			const columnMetadata = this.columnMetadata[index];
			const apiName = columnMetadata.data;
			if (index < this.periodColumnsOffset()
			) {
				rowData[columnMetadata.data] = gridValue;
			} else if (apiName.indexOf('__mdt') < 0) {
				if (!Number.isNaN(Number(apiName))) {
					rowData.periods[apiName] = gridValue;
				}
			}
		});

		return rowData;
	}

	async onRowMove(movedRows, finalIndex) {
		const movedItemRows = this.rowMetadata
			.splice(movedRows[0], movedRows.length);

		const movedItemRowData = movedItemRows.map(({ $id }) => this.quoteItems[$id]);
		movedItemRowData.forEach((nextItem) => {
			if (nextItem.parent) {
				nextItem.parent.removeChild(nextItem);
			}
		});

		this.rowMetadata.splice(finalIndex, 0, ...movedItemRows);

		await this.addRowsToSection(finalIndex, movedItemRowData);
		this._quoteService.saveSections();

		return false;
	}

	handleToggleTotalAmount() {
		const toggledVisible = !this.viewSettings.totals.isVisible;
		this.viewSettings.totals.isVisible = toggledVisible;
		this.viewSettings.totals.label = toggledVisible ? LABEL_HIDE_TOTALS : LABEL_SHOW_TOTALS;
		this.toggleTotalAmount();
	}

	handleToggleQuoteItems() {
		const toggledVisible = !this.viewSettings.quoteItems.isVisible;
		this.viewSettings.quoteItems.isVisible = toggledVisible;
		this.viewSettings.quoteItems.label = toggledVisible ? LABEL_HIDE_QUOTE_ITEMS : LABEL_SHOW_QUOTE_ITEMS;

		const quoteRowIndices = this.getQuoteItemsRowIndices();
		this.setRowColumnVisible(quoteRowIndices, [], toggledVisible);
	}

	handleToggleRateAttributes() {
		const toggledVisible = !this.viewSettings.rateAttributes.isVisible;
		this.viewSettings.rateAttributes.isVisible = toggledVisible;
		this.viewSettings.rateAttributes.label = toggledVisible ? LABEL_HIDE_RATE_ATTRIBUTES : LABEL_SHOW_RATE_ATTRIBUTES;
		this.setRowColumnVisible([], this.columnIndicesFor(ColumnGroup.RATE_ATTRIBUTE), toggledVisible);
	}

	handleTogglePricingAttributes() {
		const toggledVisible = !this.viewSettings.pricingAttributes.isVisible;
		this.viewSettings.pricingAttributes.isVisible = toggledVisible;
		this.viewSettings.pricingAttributes.label = toggledVisible ? LABEL_HIDE_PRICING_ATTRIBUTES : LABEL_SHOW_PRICING_ATTRIBUTES;
		this.setRowColumnVisible([], this.columnIndicesFor(ColumnGroup.PRICING_ATTRIBUTE), toggledVisible);
	}

	toggleMetrics() {
		const toggledVisible = !this.viewSettings.metrics.isVisible;
		this.viewSettings.metrics.isVisible = toggledVisible;
		this.viewSettings.metrics.label = toggledVisible ? LABEL_HIDE_METRICS : LABEL_SHOW_METRICS;

		const action = toggledVisible ? 'show' : 'hide';
		const payload = { receiver: 'quoteMetrics' };
		this._componentState.publish({ key: action, value: payload });
	}

	handleConversionRateFactorChange(event) {
		const { reporter, rateOverrideValues } = event.detail.value;
		if (reporter === 'rateConversionFactors') {
			const overrideValues = JSON.parse(rateOverrideValues);
			for (let i = 0; i < overrideValues.length; i++) {
				const overrideValue = overrideValues[i];
				let resultingVal;
				if (overrideValue.fieldValue && overrideValue.fieldValue.length > 0) {
					resultingVal = Number.parseInt(overrideValue.fieldValue, 10);
				} else {
					resultingVal = Number.parseInt(overrideValue.defaultFieldValue, 10);
				}

				if (overrideValue.fieldApiName.includes(ScheduleSettingFields.STANDARD_DAY_HOURS)) {
					this._scheduleSettings.standardDayHours = resultingVal;
				} else if (overrideValue.fieldApiName.includes(ScheduleSettingFields.STANDARD_WEEK_HOURS)) {
					this._scheduleSettings.standardWeekHours = resultingVal;
				} else if (overrideValue.fieldApiName.includes(ScheduleSettingFields.STANDARD_MONTH_HOURS)) {
					this._scheduleSettings.standardMonthHours = resultingVal;
				} else if (overrideValue.fieldApiName.includes(ScheduleSettingFields.STANDARD_YEAR_HOURS)) {
					this._scheduleSettings.standardYearHours = resultingVal;
				}
			}

			this.resetAndReprice();
		}
	}

	async toggleTotalAmount() {
		const rows = await this.getTotalRows();
		const cols = this.getTotalCols();
		this.setRowColumnVisible(rows, cols, this.viewSettings.totals.isVisible);
	}

	async getTotalRows() {
		const rowCount = await this.grid.countRows();
		const quoteItemsCount = Object.keys(this.quoteItems).length;
		const rows = [];
		let quoteItemRow = -3;
		let quoteItemsCountTmp = 0;
		Object.keys(this.sections).forEach((section) => {
			const sectionQuoteItemsCount = this.sections[section].quoteItems.length;
			quoteItemRow += sectionQuoteItemsCount + 3;
			quoteItemsCountTmp += sectionQuoteItemsCount;
			// head count and total rows of the section
			rows.push(quoteItemRow + 1, quoteItemRow + 2);
		});

		// ungrouped items
		if (quoteItemsCount > quoteItemsCountTmp) {
			quoteItemRow += quoteItemsCount - quoteItemsCountTmp + 3;
			rows.push(quoteItemRow + 1, quoteItemRow + 2);
		}

		for (let row = rowCount - 3; row < rowCount; row++) {
			// Column total of Head count and Amount
			rows.push(row);
		}

		return rows;
	}

	getTotalCols() {
		const periodColOffset = this.periodColumnsOffset();
		const cols = [];
		let colStart = periodColOffset - 1;
		Object.keys(this.periodsByGroup).forEach((group) => {
			colStart += this.periodsByGroup[group].length + 1;
			cols.push(colStart);
		});
		cols.push(cols[cols.length - 1] + 1);
		return cols;
	}

	async setRowColumnVisible(
		rows = [],
		cols = [],
		isVisible,
	) {
		let methodNameRow = 'showRows';
		let methodNameCol = 'showColumns';
		if (!isVisible) {
			methodNameRow = 'hideRows';
			methodNameCol = 'hideColumns';
		}

		// hide the total rows
		if (rows.length) {
			await this.grid.invokeMethods({
				methodName: 'getPlugin',
				args: ['hiddenRows'],
				then: {
					methodName: methodNameRow,
					args: [rows],
				},
			});
		}

		if (cols.length) {
			await this.grid.invokeMethods({
				methodName: 'getPlugin',
				args: ['HiddenColumns'],
				then: {
					methodName: methodNameCol,
					args: [cols],
				},
			});
		}

		this.grid.render();
	}

	/**
	 * Launches add/edit resrouce role dialog
	 *
	 * @param action
	 * @param selectedRange
	 * @param options
	 */
	async handleOpenRoleDialog(action, selectedRange, options) {
		let headerLabel = LABEL_ADD_RESOURCE;
		let quoteItem;
		this.modalAction = action;
		[this.selectedRange] = selectedRange;
		const showCloseButton = !(options && options.showCloseButton === false);
		const { start } = this.selectedRange;
		if (action === 'edit_row') {
			headerLabel = LABEL_EDIT_RESOURCE;
			quoteItem = await this.getQuoteItemForRow(start.row);
		}

		const dialogServicePayload = {
			method: 'bodyModalLarge',
			config: {
				auraId: 'resource-role-dialog',
				headerLabel,
				showCloseButton,
				component: `${this.namespace}:resourceRoleDialog`,
				componentParams: {
					quote: this.recordId,
					group: this.group,
					practice: this.practice,
					rateCard: this.rateCardId,
					selectedRole: quoteItem?.productId,
					rateCardItemId: quoteItem?.rateCardItemId,
					showCloseButton,
				},
			},
		};

		this._componentState.dialogService(dialogServicePayload);
	}

	/**
	 * Handles resource role selected event from resource role dialog once user has accepted a selection
	 * @param event
	 * @returns {Promise<void>}
	 */
	async handleRoleSelected(event) {
		const { start } = this.selectedRange;
		switch (this.modalAction) {
			case ContextMenuActions.ROW_BELOW:
				await this.addRowsToSection(start.row + 1, this.spliceNewRows(start.row + 1, [event.detail.value]));
				this._quoteService.saveSections();
				break;

			case ContextMenuActions.EDIT_ROW: {
				await this.changeResourceRole(start.row, event.detail.value);
				await this.refreshGrid();
				await this.updateTotalsFor(start.row);
				await this.recomputeColumnTotals();
				await this.updateSectionTotals();
				await this.updatePeriodGroupTotals();

				this._quoteService.saveLines().catch((e) => {
					log('Failed to save lines ');
					log(e);
				});
				break;
			}

			default:
		}
	}

	/**
	 * toggles billable/non-billable for current row
	 *
	 * @param action
	 * @param selectedRange
	 */
	async handleToggleBilling(action, selectedRange) {
		[this.selectedRange] = selectedRange;
		const { start } = this.selectedRange;
		const { row } = start;
		const targetMeta = await this.grid.getCellMeta(row, 0);
		const quoteItem = this.quoteItems[targetMeta.$id];
		if (action === 'toggle_billable') {
			quoteItem.quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName] = false;
			quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
			this.grid.setSourceDataAtCell(row, QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName, false);
		} else {
			quoteItem.quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName] = true;
			this.grid.setSourceDataAtCell(row, QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName, true);
		}

		try {
			await this.repriceQuoteGrid(); // calls updateTotalsForRows and saves quote items
		} catch (e) {
			// in case of error revert non-billable flag
			const revertedNonBillableVal = !quoteItem.quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName];
			quoteItem.quoteItemSO[QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName] = revertedNonBillableVal;
			this.grid.setSourceDataAtCell(row, QUOTE_ITEM_NONBILLABLE_FIELD.fieldApiName, revertedNonBillableVal);
			this.toastError(e);
		}

		await this.recomputeColumnTotals(); // calculate each period column's Total Amount
		await this.updateSectionTotals();
		await this.updatePeriodGroupTotals();
	}

	async changeResourceRole(row, rateCardItem) {
		const targetMeta = await this.grid.getCellMeta(row, 0);
		const targetRow = this.quoteItems[targetMeta.$id];

		targetRow.elementDO.rateCardItemId = rateCardItem.Id;
		targetRow.elementDO.productId = rateCardItem[RATE_CARD_ITEM_PRODUCT_FIELD.fieldApiName];

		const rateCardAttributes = this.getRateCardAttributes();
		rateCardAttributes.forEach((rateCardAttribute) => {
			const { fieldName } = rateCardAttribute;
			targetRow.elementDO.quoteItemSO[fieldName] = rateCardItem[fieldName];
		});

		await this.setPricePoints(row, true);
	}

	handleRealignResource() {
		this.realignResource();
	}

	async realignResource() {
		const locationIdx = this.getPropIdx(QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName);

		const realignLocationMap = {
			// from: to
			'United States': 'India',
		};

		const columnUpdates = [];
		for (let rowIdx = 0; rowIdx < this.rowMetadata.length; rowIdx++) {
			const quoteItem = this.getRowItem(this.rowMetadata[rowIdx]);
			if (quoteItem) {
				const prevLocation = quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName]; // TODO: Remove hard coding
				const locationCountry = realignLocationMap[prevLocation];

				const rateCardItem = await this.findFirstValidRateCardItem(
					quoteItem.productId,
					quoteItem.quoteItemSO[QUOTE_ITEM_SKILL_LEVEL_FIELD.fieldApiName],
					locationCountry,
				);

				if (rateCardItem && rateCardItem.Id !== quoteItem.rateCardItemId) {
					quoteItem.rateCardItemId = rateCardItem.Id;
					quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName] = rateCardItem[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName];
					quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName] = rateCardItem[QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName];
					quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
					quoteItem.adjustment.amount = null;
					columnUpdates.push([rowIdx, locationIdx, quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_DISPLAY_NAME_FIELD.fieldApiName]]);
				}
			}
		}

		if (columnUpdates.length) {
			await this.grid.setDataAtCell(columnUpdates);

			const evt = new ShowToastEvent({
				title: 'Pricing is optimized',
				variant: 'success',
			});

			this.dispatchEvent(evt);
		} else {
			const evt = new ShowToastEvent({
				title: 'Pricing is already optimized',
				variant: 'success',
			});

			this.dispatchEvent(evt);
		}
	}

	async findFirstValidRateCardItem(productId, skillLevel, locationCountry) {
		const rateCardItems = await this.getRateCardItemsFor(productId);
		let rateCardItem;
		if (rateCardItems?.length) {
			rateCardItem = rateCardItems.find(
				(item) => item[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName] === (locationCountry || null)
					&& item[QUOTE_ITEM_SKILL_LEVEL_FIELD.fieldApiName] === (skillLevel || null),
			);
		}

		return rateCardItem;
	}

	async recomputeColumnTotals() {
		const columnNames = {};
		this.columnMetadata.forEach((column) => {
			if (column.isPeriod) {
				columnNames[column.data] = true;
			}
		});
		await this.updateColumnsTotals(columnNames, false);
	}

	async handleRevenueAdjustment(value) {
		this.adjustQuoteRevenue(value);
	}

	async handleMarginAdjustment(value) {
		this.adjustQuoteMargin(value);
	}

	async adjustQuoteMargin(margin) {
		const grandUnitCost = await this.getOriginalGrantTotalByColumn(QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName);
		const revenue = grandUnitCost / (1 - margin / 100);
		this.adjustQuoteRevenue(revenue);
	}

	async adjustQuoteRevenue(revenue) {
		const grandTotal = await this.getOriginalGrantTotalByColumn(QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName, true);
		const newAmountDiff = revenue - grandTotal;
		const { relatedTotal } = this.quoteNamedRange;
		const prevTotalAmount = relatedTotal.totalAmount;
		let adjustedUnitPriceTotal = 0;
		const remainderLines = [];
		const adjustedRows = [];
		for (let rowIdx = 0; rowIdx < this.rowMetadata.length; rowIdx++) {
			const { $id, lineSequence } = this.rowMetadata[rowIdx];
			if (lineSequence) {
				const quoteItem = this.quoteItems[$id];
				const unitPrice = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]) || 0;
				const unitCost = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_UNIT_COST_FIELD.fieldApiName]) || 0;
				const headCount = await this.getRowHeadTermCalculation(rowIdx) || 0;
				const totalAmount = unitPrice * headCount;
				if (headCount > 0) {
					const revPercentage = (totalAmount / grandTotal) * 100;
					let adjustedUnitPrice = unitPrice + (revPercentage * newAmountDiff) / 100 / headCount;
					let priceFloor = adjustedUnitPrice;
					const product = this.productsById[quoteItem.productId];
					let hasPriceRule = false;
					if (product?.name === 'DevOps Specialist') {
						priceFloor = 11000;
						hasPriceRule = true;
					}

					if (quoteItem.quoteItemSO[QUOTE_ITEM_LOCATION_COUNTRY_FIELD.fieldApiName] === 'United States') {
						const newCap = unitCost / (1 - 0.2);
						if (newCap > priceFloor) {
							priceFloor = newCap;
						}

						hasPriceRule = true;
					}

					if ((product?.name || '').includes('Architect')) {
						const newCap = unitCost / (1 - 0.3);
						if (newCap > priceFloor) {
							priceFloor = newCap;
						}

						hasPriceRule = true;
					}

					if (priceFloor > adjustedUnitPrice) {
						adjustedUnitPrice = priceFloor;
					}

					if (!hasPriceRule) {
						remainderLines.push({ quoteItem, revPercentage, headCount });
					}

					if (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] !== adjustedUnitPrice) {
						quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = adjustedUnitPrice;
						quoteItem.adjustment.amount = null;
					}

					adjustedRows.push(rowIdx);
					adjustedUnitPriceTotal += adjustedUnitPrice * headCount;
				}
			}
		}

		const remainder = revenue - adjustedUnitPriceTotal;
		if (remainder !== 0 && remainderLines.length > 0) {
			await this.spreadRemainder(revenue, adjustedUnitPriceTotal, remainderLines);
		}

		for (let i = 0; i < adjustedRows.length; i++) {
			const rowIdx = adjustedRows[i];
			await this.setPricePoints(rowIdx);
			await this.updateTotalsFor(rowIdx);
		}

		await this.recomputeColumnTotals();
		await this.updateSectionTotals();
		await this.updatePeriodGroupTotals();

		if (relatedTotal.totalAmount !== prevTotalAmount) {
			const evt = new ShowToastEvent({
				title: `Pricing is updated from $${prevTotalAmount.toFixed(
					2,
				)} to $${relatedTotal.totalAmount.toFixed(2)}`,
				variant: 'success',
			});

			this.dispatchEvent(evt);
		}

		this._quoteService.saveLines().catch((e) => {
			log('Failed to save lines ');
			log(e);
		});
	}

	async spreadRemainder(adjustmentTarget, adjustedAmount, rowsToAdjust = [], iterationCount = 0) {
		// const remainder = revenue - adjustedUnitPriceTotal;
		const abovePriceFloor = [];
		let totalAdjustment = adjustedAmount;
		const adjustmentAmount = adjustmentTarget - adjustedAmount;
		for (let i = 0; i < rowsToAdjust.length; i++) {
			const { headCount, quoteItem, revPercentage } = rowsToAdjust[i];
			const unitPrice = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]);

			const additionalAdjustment = Math.round(
				unitPrice + (revPercentage * adjustmentAmount) / 100 / headCount,
			);

			if (additionalAdjustment !== 0) {
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = additionalAdjustment;

				if (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] < 0) {
					quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = 0;
				} else {
					abovePriceFloor.push(rowsToAdjust[i]);
				}

				quoteItem.adjustment.amount = null;
				totalAdjustment += (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] - unitPrice) * headCount;
			}
		}

		// final iteration, attempt to spread evenly amongst remaining lines
		if (iterationCount === 40) {
			for (let i = 0; i < rowsToAdjust.length; i++) {
				const { headCount, quoteItem } = rowsToAdjust[i];
				const unitPrice = parseFloat(quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName]);
				const remainderToAdjust = adjustmentTarget - totalAdjustment;
				if (remainderToAdjust !== 0) {
					quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] += remainderToAdjust / headCount;
					quoteItem.adjustment.amount = null;

					if (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] < 0) {
						quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = 0;
					}

					totalAdjustment += (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] - unitPrice) * headCount;
				}
			}
		} else {
			const remainder = adjustmentTarget - adjustedAmount;
			if (remainder !== 0 && iterationCount < 40 && abovePriceFloor.length > 0) {
				if (abovePriceFloor.length === 1) {
					const { headCount, quoteItem } = abovePriceFloor[0];
					quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = remainder / headCount;

					if (quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] < 0) {
						quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = 0;
						quoteItem.adjustment.amount = null;
					}
				}

				await this.spreadRemainder(adjustmentTarget, totalAdjustment, abovePriceFloor, iterationCount + 1);
			}
		}
	}
	async getRowHeadTermCalculation(rowIdx) {
		let headCount = 0;
		for (let colIdx = 0; colIdx < this.columnMetadata.length; colIdx++) {
			if (this.columnMetadata[colIdx].isPeriod) {
				let term = 1;
				const colSequence = parseInt(this.columnMetadata[colIdx].data, 10);
				if (this.periodsBySequence[colSequence]) {
					term = this.periodsBySequence[colSequence];
				}

				const cellHeadCount = await this.grid.getDataAtRowProp(
					rowIdx,
					this.columnMetadata[colIdx].data,
				);

				headCount += term * cellHeadCount;
			}
		}

		return headCount;
	}

	async handleRevertMarginRevenue() {
		const { relatedTotal } = this.quoteNamedRange;
		const prevTotalAmount = relatedTotal.totalAmount;
		for (let rowIdx = 0; rowIdx < this.rowMetadata.length; rowIdx++) {
			if (this.rowMetadata[rowIdx].lineSequence) {
				const quoteItem = await this.getQuoteItemForRow(rowIdx);
				quoteItem.quoteItemSO[QUOTE_ITEM_ADJUSTED_UNIT_PRICE_FIELD.fieldApiName] = null;
				quoteItem.adjustment.amount = null;

				await this.setPricePoints(rowIdx);
				await this.updateTotalsFor(rowIdx);
			}
		}

		await this.recomputeColumnTotals();
		await this.updateSectionTotals();
		await this.updatePeriodGroupTotals();

		this._quoteService.saveLines()
			.then(() => {
				if (relatedTotal.totalAmount !== prevTotalAmount) {
					const evt = new ShowToastEvent({
						title: `Pricing is reverted. It is updated from $${prevTotalAmount.toFixed(
							2,
						)} to $${relatedTotal.totalAmount.toFixed(2)}`,
						variant: 'success',
					});

					this.dispatchEvent(evt);
				}
			})
			.catch((e) => {
				log('Failed to save lines ');
				log(e);
			});
	}

	async getOriginalGrantTotalByColumn(columnName, baseAdjustment = false) {
		let grantTotal = 0;
		for (let rowIdx = 0; rowIdx < this.rowMetadata.length; rowIdx++) {
			if (this.rowMetadata[rowIdx].lineSequence) {
				const unitPrice = await this.grid.getDataAtRowProp(rowIdx, columnName);

				const baseAdjustmentAmount = await this.grid.getDataAtRowProp(
					rowIdx,
					'baseAdjustmentAmount',
				);

				const headCount = await this.getRowHeadTermCalculation(rowIdx);
				if (baseAdjustment && baseAdjustmentAmount) {
					grantTotal += unitPrice * ((100 - baseAdjustmentAmount) / 100) * headCount;
				} else {
					grantTotal += unitPrice * headCount;
				}
			}
		}

		return grantTotal;
	}

	async handleOpenAdjustment() {
		await this.grid.deselectCell();
		this.disableAdjustment = false;

		if (!this._modal) {
			this._modal = this.template.querySelector('c-modal');
		}

		this._modal.show();
	}

	handleCloseModal() {
		if (!this._modal) {
			this._modal = this.template.querySelector('c-modal');
		}

		this._modal.hide();
	}

	handleAdjustment() {
		const createScenario = this.template.querySelector('c-create-scenario');
		if (!createScenario) {
			return;
		}

		const adjustment = createScenario.getAdjustment();
		const adjustmentVal = parseInt(adjustment.value, 10);
		if (!adjustmentVal && adjustment.type !== AdjustmentType.REALIGN_RESOURCE) {
			createScenario.validate();
			return;
		}

		this.disableAdjustment = true;

		switch (adjustment.type) {
			case AdjustmentType.REVENUE_ADJUSTMENT:
				this.handleRevenueAdjustment(adjustmentVal);
				break;
			case AdjustmentType.MARGIN_ADJUSTMENT:
				this.handleMarginAdjustment(adjustmentVal);
				break;
			case AdjustmentType.REALIGN_RESOURCE:
				this.handleRealignResource();
				break;
			default:
				break;
		}

		this.handleCloseModal();
	}

	async handleQuoteMerge() {
		const collabSectionIds = this.collaborationRequests.map((nextRequest) => nextRequest[SECTION_ID_FIELD.fieldApiName]);
		if (collabSectionIds.length === 0) {
			return;
		}

		let results;
		try {
			results = await mergeSections({
				quoteId: this.recordId,
				sectionIds: collabSectionIds,
			});
		} catch (e) {
			this._componentState.notifySingleError('Failed to merge sections', e);
			return;
		}

		for (let i = 0; i < this.collaborationRequests.length; i++) {
			this.collaborationRequests[i][STATUS_FIELD.fieldApiName] = CollaborationRequest.Status.MERGED;
		}

		if (results) {
			this.mergeCollaboratedQuoteItems(JSON.parse(results), collabSectionIds);
		}

		this.actionsMap.merge.enabled = false;
		await this.refreshGrid();
		this.rerender();

		const evt = new ShowToastEvent({
			title: LABEL_COLLABORATION_MERGED,
			variant: 'success',
		});

		this.dispatchEvent(evt);
	}

	mergeCollaboratedQuoteItems(resultQuoteItems, collabSectionIds) {
		const sections = collabSectionIds.map((nextSectionId) => this.findSectionFor(nextSectionId));
		const sectionItemsById = new Map();
		sections.forEach((nextSection) => {
			nextSection.quoteItems.forEach((nextItem) => {
				sectionItemsById.set(nextItem.elementDO.id, nextItem);
			});
		});

		this._quoteService.mergeItemsBy(
			resultQuoteItems,
			(item) => item.id,
			Object.fromEntries(sectionItemsById),
		);

		this.processItemChanges(resultQuoteItems, sectionItemsById);
	}

	/**
	 * Processes the quote item additions and removals of the collaboration merge.
	 * @param {QuoteItemDTO[]} resultQuoteItems
	 * @param {Object}sectionItemsById
	 */
	processItemChanges(resultQuoteItems, sectionItemsById) {
		const quoteItemsById = new Map();
		Object.values(this.quoteItems).forEach((nextItem) => {
			quoteItemsById.set(nextItem.id, nextItem);
		});

		resultQuoteItems.forEach((nextItem) => {
			const quoteItem = quoteItemsById.get(nextItem.id);
			if (quoteItem) {
				sectionItemsById.delete(quoteItem.id);
			} else {
				const newQuoteItem = this.newQuoteItem(nextItem);
				const section = this.findSectionFor(newQuoteItem.sectionId);
				section.addQuoteItem(newQuoteItem);
			}
		});

		// any remaining items in the map signifies that the server
		// no longer has this item and should be deleted
		sectionItemsById.forEach((item) => {
			if (item.parent) {
				item.parent.removeChild(item);
				item.commit(OBSERVER_NAME_SFDC); // clear from dirty observers to avoid future updates
			}

			const quoteItem = quoteItemsById.get(item.id);
			delete this.quoteItems[quoteItem.$id];
		});
	}

	/**
	 * Commits the current collaboration quote.
	 */
	handleCommit() {
		this.disableGrid();

		for (let i = 0; i < this.collaborationRequests.length; i++) {
			this.collaborationRequests[i][STATUS_FIELD.fieldApiName] = CollaborationRequest.Status.READY_TO_MERGE;
		}

		this.rerender();

		const sectionRFieldName = SECTION_ID_FIELD.fieldApiName.replace('__c', '__r');
		const targetSectionIds = this.collaborationRequests.map((nextRequest) => nextRequest[SECTION_ID_FIELD.fieldApiName]);
		targetSectionIds.push(...this.collaborationRequests.map((nextRequest) => nextRequest[sectionRFieldName][DERIVED_FROM_ID_FIELD.fieldApiName]));

		try {
			commitChanges({ quoteId: this.recordId, sectionIds: targetSectionIds.filter((x) => x) });
		} catch (e) {
			this._componentState.notifySingleError('Failed to commit changes', e);
			return;
		}

		const evt = new ShowToastEvent({
			title: LABEL_COLLABORATION_COMMITTED,
			variant: 'success',
		});

		this.dispatchEvent(evt);
	}

	/**
	 * Disables all interaction with the grid.
	 */
	disableGrid() {
		this.grid.updateSettings({
			readOnly: true, // make table cells read-only
			contextMenu: false, // disable context menu to change things
			disableVisualSelection: true, // prevent user from visually selecting
			manualColumnResize: false, // prevent dragging to resize columns
			manualRowResize: false, // prevent dragging to resize rows
			comments: false, // prevent editing of comments
		});
	}

	/**
	 * Returns true if there are outstanding collaboration requests, that is, if any request
	 * tied to this quote is not yet Ready to Merge.
	 * @returns {boolean} True, if there are outstanding requests, false otherwise
	 */
	hasOutstandingRequests() {
		return this.collaborationRequests
			.some((nextRequest) => nextRequest[STATUS_FIELD.fieldApiName] !== CollaborationRequest.Status.READY_TO_MERGE);
	}

	/**
	 * Returns true if there are any Ready to Merge collaboration requests.
	 * @returns {boolean} True, if there are any collaborations to merge, false otherwise
	 */
	hasRequestsToMerge() {
		return this.collaborationRequests
			.some((nextRequest) => nextRequest[STATUS_FIELD.fieldApiName] === CollaborationRequest.Status.READY_TO_MERGE);
	}

	/**
	 * Returns true if the quote is a collaboration quote.
	 * @returns {boolean} True if collaboration quote, false otherwise
	 */
	isCollaborationQuote() {
		return this.recordType === RecordType.COLLABORATION;
	}

	/**
	 * Forces a DOM rerender.
	 */
	rerender() {
		this.render = Date.now();
	}

	resetAndReprice() {
		for (let i = 0; i < this.rowMetadata.length; i++) {
			const meta = this.rowMetadata[i];
			if (!meta.isSectionHeader && !meta.isSectionFooter) {
				this.setPricePoints(i, true).then(() => this.updateTotalsFor(i));
			}
		}
	}

	async handleRevoke(action, phaseRange) {
		const { start } = phaseRange[0];
		const sectionMeta = await this.grid.getCellMeta(start.row, 0);
		try {
			await revokeSections({
				quoteId: this.recordId,
				sectionIds: [this.sections[sectionMeta.$id].id],
			});
		} catch (e) {
			this._componentState.notifySingleError('Failed to revoke section', e);
			return;
		}

		await this.reloadCollaborationRequests();
		this.refreshGrid();
	}

	assignChildren() {
		const newRoots = [];
		let nextSequence = 1;
		this.rowMetadata.forEach((nextItem) => {
			const item = this.quoteItems[nextItem.$id] || this.sections[nextItem.$id];
			if (item?.$treeLevel === 0) {
				item.displaySequence = nextSequence;
				nextSequence += 1;
				newRoots.push(item);
			}
		});

		this.rootItems = newRoots;

		let contextSection;
		let newChildren = [];
		// read through the metadata and reparent quote items below every section
		this.rowMetadata.forEach((nextItem) => {
			const item = this.quoteItems[nextItem.$id] || this.sections[nextItem.$id];
			if (item?.$type === Provus.Section.TYPE) {
				contextSection?.setChildren(newChildren);
				contextSection = item;
				newChildren = [];
			} else if (item?.$type === Provus.QuoteItem.TYPE) {
				newChildren.push(item);
			}
		});

		// last section
		contextSection?.setChildren(newChildren);
	}
}

function onColumnDrag(movedColumns, dropIndex) {
	const lastRow = this.countRows() - 1;
	const { phase: dropPhase } = this.getCellMeta(lastRow, dropIndex);
	if (dropPhase) {
		window.top.postMessage(
			{
				action: 'move-periods',
				data: JSON.stringify([movedColumns, dropIndex]),
			},
			'*',
		);
	}

	return false;
}

function beforeRowMove(movedRows, finalIndex) {
	if (movedRows[0] === finalIndex) {
		return false;
	}

	if (finalIndex === 0 && !this.getSourceDataAtRow(finalIndex).isQuoteItem) { // quote item cannot be moved above the first section header
		return false;
	}

	for (let i = 0; i < movedRows.length; i++) {
		if (!this.getSourceDataAtRow(movedRows[i]).isQuoteItem) {
			return false;
		}
	}

	return undefined;
}
