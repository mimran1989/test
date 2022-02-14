import { api, LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import baseJS from '@salesforce/resourceUrl/Provus';
import { isEmpty } from 'c/util';

import commitNamedRanges from '@salesforce/apex/QuoteConfiguratorController.commitNamedRanges'; // named range and quote
import commitProjectPhases from '@salesforce/apex/QuoteConfiguratorController.commitProjectPhases';
import commitQuoteItems from '@salesforce/apex/QuoteConfiguratorController.commitQuoteItems'; // quote item
import commitQuoteSections from '@salesforce/apex/QuoteConfiguratorController.commitQuoteSections'; // quote item and section
// import log from 'c/log';

const OBJECT_TYPE_NAMED_RANGE = 'NamedRange';
const OBJECT_TYPE_QUOTE_ITEM = 'QuoteItem';
const OBJECT_TYPE_PROJECT_PHASE = 'ProjectPhase';
const OBJECT_TYPE_QUOTE = 'Quote';
const OBJECT_TYPE_SECTION = 'Section';
const OBSERVER_NAME_SFDC = 'SFDC';

export default class QuoteService extends LightningElement {
	@api quote;

	_actionQueue;
	_messageService;
	_pendingDeleteQuoteItems = {};
	totalState;

	async connectedCallback() {
		await Promise.all([
			loadScript(this, `${baseJS}/data/index.js`),
			loadScript(this, `${baseJS}/queue/index.js`),
		]);

		this.createActionQueue();
		Provus.Sync.forType(OBJECT_TYPE_NAMED_RANGE).watch(OBSERVER_NAME_SFDC);
		Provus.Sync.forType(OBJECT_TYPE_QUOTE_ITEM).watch(OBSERVER_NAME_SFDC);
		Provus.Sync.forType(OBJECT_TYPE_SECTION).watch(OBSERVER_NAME_SFDC);
		Provus.Sync.forType(OBJECT_TYPE_QUOTE).watch(OBSERVER_NAME_SFDC);
		Provus.Sync.forType(OBJECT_TYPE_PROJECT_PHASE).watch(OBSERVER_NAME_SFDC);
		this.totalState = this.template.querySelector('.quote-config-total-state');
	}

	static copyDO(elementDO) {
		return { ...elementDO };
	}

	createActionQueue() {
		this._actionQueue = new Provus.Queue();
		this._actionQueue.registerActions([
			{
				actionName: 'saveSections',
				priority: 1,
				fn: async() => this.qSaveSections(),
			},
			{
				actionName: 'saveLines',
				priority: 2,
				fn: () => this.qSaveLines(),
			},
			{
				actionName: 'deleteLines',
				priority: 2,
				fn: () => this.qDeleteItems(),
			},
			{
				actionName: 'saveNamedRanges',
				priority: 3,
				fn: async() => this.qSaveNamedRanges(),
			},
			{
				actionName: 'savePhases',
				priority: 3,
				fn: async() => this.qSavePhases(),
			},
		]);

		return this._actionQueue;
	}

	@api
	async deleteQuoteItem(item) {
		this._pendingDeleteQuoteItems[item.$id] = item;
		return this.scheduleAction('deleteLines');
	}

	@api
	mergeItemsBy(itemDOs, byTokenFn, items) {
		itemDOs.forEach((itemDO) => {
			const item = items[byTokenFn(itemDO)];
			if (item) {
				item.merge(itemDO, OBSERVER_NAME_SFDC);
			} else {
				// log('UI Item is missing during merge.');
			}
		});

		return this;
	}

	@api
	async saveLines() {
		return this.scheduleAction('saveLines');
	}

	@api
	async saveNamedRanges() {
		return this.scheduleAction('saveNamedRanges');
	}

	@api
	async savePhases() {
		return this.scheduleAction('savePhases');
	}

	@api
	saveSections() {
		return this.scheduleAction(['saveLines', 'saveSections']);
	}

	async scheduleAction(actions) {
		return this._actionQueue.scheduleAction(actions);
	}

	async qDeleteItems() {
		const deleteRequests = [];
		Object.values(this._pendingDeleteQuoteItems).forEach((quoteItem) => {
			const isPersisted = !isEmpty(quoteItem.elementDO.id);
			if (isPersisted) {
				const deleteDO = QuoteService.copyDO(quoteItem.elementDO);
				deleteDO.operationType = 'delete';
				deleteRequests.push(deleteDO);
			}

			delete this._pendingDeleteQuoteItems[quoteItem.$id];
		});

		if (deleteRequests.length) {
			await commitQuoteItems({
				quoteItemsColData: JSON.stringify(deleteRequests),
				quoteId: this.quote,
			});
		}
	}

	async qSaveTotals() {
		await this.totalState.getNamedRangeTotalDetails(this.quote);
		await this.totalState.saveTotals();
	}

	async qSaveLines() {
		const changedItems = Provus.Sync.forType(OBJECT_TYPE_QUOTE_ITEM).getChanges(OBSERVER_NAME_SFDC);
		const updateRequests = [];
		const contextQuoteItems = {};
		Object.keys(changedItems).forEach((objectId) => {
			const { element: quoteItem } = changedItems[objectId];
			const updateDO = QuoteService.copyDO(quoteItem.elementDO);
			const isPersisted = !isEmpty(updateDO.id);

			updateDO.operationType = isPersisted ? 'update' : 'insert';

			updateRequests.push(updateDO);
			contextQuoteItems[
				`${quoteItem.elementDO.lineSequence}${!!quoteItem.elementDO.isMiscellaneous}`
			] = quoteItem;
			quoteItem.commit(OBSERVER_NAME_SFDC);
		});

		if (updateRequests.length) {
			let results;
			try {
				results = await commitQuoteItems({
					quoteItemsColData: JSON.stringify(updateRequests),
					quoteId: this.quote,
				});
			} catch (e) {
				const errorMessage = `Failed to save quote items: ${e.body.message}`;
				throw new Error(errorMessage);
			}

			if (results) {
				this.mergeItemsBy(
					JSON.parse(results),
					(item) => `${item.lineSequence}${!!item.isMiscellaneous}`,
					contextQuoteItems,
				);
			}
		}
	}

	// eslint-disable-next-line max-lines-per-function
	async qSavePhases() {
		const changedPhases = Provus.Sync.forType(OBJECT_TYPE_PROJECT_PHASE)
			.getChanges(OBSERVER_NAME_SFDC);

		const phasesToUpsert = [];
		const contextPhases = {};

		Object.keys(changedPhases)
			.forEach((phaseId) => {
				const { element: phase, fields } = changedPhases[phaseId];
				const elementDO = QuoteService.copyDO(phase.elementDO);
				const isPersisted = phase.isPersisted();
				const isDeleted = phase.numberOfPeriods() === 0;
				if (!isPersisted && !isDeleted) {
					elementDO.operationType = 'insert';
				} else if (isDeleted) {
					elementDO.operationType = 'delete';
				} else {
					elementDO.operationType = 'update';
				}

				contextPhases[elementDO.sequence] = phase;
				phasesToUpsert.push(elementDO);

				if (fields.length > 0) {
					phase.commit(OBSERVER_NAME_SFDC);
				}
			});

		if (phasesToUpsert.length) {
			let results;
			try {
				results = await commitProjectPhases({
					projectPhaseColData: JSON.stringify(phasesToUpsert),
					quoteId: this.quote,
				});

				if (results) {
					this.mergeItemsBy(
						JSON.parse(results),
						(item) => item.sequence,
						contextPhases,
					);
				}
			} catch (e) {
				const errorMessage = `Failed to save phases: ${e.body.message}`;
				throw new Error(errorMessage);
			}
		}
	}

	// eslint-disable-next-line max-lines-per-function
	async qSaveNamedRanges() {
		const changedNamedRanges = Provus.Sync.forType(OBJECT_TYPE_NAMED_RANGE).getChanges(OBSERVER_NAME_SFDC);
		const namedRangesToUpsert = [];
		const contextNamedRanges = {};
		Object.keys(changedNamedRanges).forEach((namedRangeId) => {
			const { element: namedRange } = changedNamedRanges[namedRangeId];
			const elementDO = QuoteService.copyDO(namedRange.elementDO);
			const isPersisted = !isEmpty(elementDO.namedRangeId);
			let rangeToken = elementDO.type;
			if (elementDO.rangeSpec) {
				const rangeSpec = JSON.parse(elementDO.rangeSpec);
				if (rangeSpec.range) {
					rangeToken += JSON.stringify(rangeSpec.range);
				}
			}

			if (!isPersisted) {
				elementDO.operationType = 'insert';
				elementDO.relatedTotal.operationType = 'insert';
			} else {
				elementDO.operationType = 'update';
				elementDO.relatedTotal.operationType = 'update';
			}

			contextNamedRanges[rangeToken] = namedRange;
			namedRangesToUpsert.push(elementDO);
			namedRange.commit(OBSERVER_NAME_SFDC);
		});

		if (namedRangesToUpsert.length) {
			let results;
			try {
				results = await commitNamedRanges({
					quoteId: this.quote,
					namedRangeColData: JSON.stringify(namedRangesToUpsert),
				});
				await this.qSaveTotals();
			} catch (e) {
				const errorMessage = `Failed to save names ranges: ${e.body.message}`;
				throw new Error(errorMessage);
			}

			if (results) {
				QuoteService.refreshView();
				this.mergeItemsBy(
					JSON.parse(results),
					(item) => {
						let token = item.type;
						if (item.rangeSpec) {
							const rangeSpec = JSON.parse(item.rangeSpec);
							if (rangeSpec.range) {
								token += JSON.stringify(rangeSpec.range);
							}
						}

						return token;
					},
					contextNamedRanges,
				);
				this.refreshSummaryTab();
			}
		}

		return namedRangesToUpsert;
	}

	static refreshView() {
		// eslint-disable-next-line no-eval
		eval("const refresher = $A.get('e.force:refreshView'); refresher && refresher.fire();");
	}

	processSectionResults(results, contextSections) {
		const resultArr = JSON.parse(results);
		const flatten = (section) => {
			const allSections = [];
			allSections.push(section);

			if (section.childSections.length > 0) {
				section.childSections.forEach((nextChild) => {
					allSections.push(...flatten(nextChild));
				});
			}

			return allSections;
		};

		const flat = resultArr.reduce((acc, val) => {
			acc.push(...flatten(val));
			return acc;
		}, []);

		this.mergeItemsBy(
			flat,
			(item) => item.sequence,
			contextSections,
		);
	}

	async qSaveSections() {
		const changedSections = Provus.Sync.forType(OBJECT_TYPE_SECTION).getChanges(OBSERVER_NAME_SFDC);
		const updateRequests = [];
		const contextSections = {};
		const newSections = [];
		Object.keys(changedSections).forEach((objectId) => {
			const { element: section } = changedSections[objectId];
			const updateDO = QuoteService.copyDO(section.elementDO);
			const isPersisted = !isEmpty(section.elementDO.id);
			if (!isPersisted) {
				newSections.push(section);
			}

			updateDO.operationType = isPersisted ? 'update' : 'insert';
			updateDO.quoteItemIdList = section.quoteItems
				.filter((quoteItem) => !!quoteItem.id)
				.map((quoteItem) => quoteItem.id);

			updateRequests.push(updateDO);
			contextSections[section.elementDO.sequence] = section;
			section.commit(OBSERVER_NAME_SFDC);
		});

		if (updateRequests.length) {
			try {
				const results = await commitQuoteSections({
					quoteSectionColData: JSON.stringify(updateRequests),
					quoteId: this.quote,
				});

				if (results) {
					this.processSectionResults(results, contextSections);
					QuoteService.setSectionIdOnChildren(newSections);
				}
			} catch (e) {
				const errorMessage = `Failed to save line items: ${e.body.message}`;
				throw new Error(errorMessage);
			}
		}
	}

	static setSectionIdOnChildren(sections) {
		sections.forEach((nextSection) => {
			nextSection.quoteItems.forEach((nextItem) => {
				const childItem = nextItem;
				childItem.elementDO.sectionId = nextSection.elementDO.id;
			});
		});
	}

	renderedCallback() {
		this._messageService = this.template.querySelector('c-message-service');
	}

	async refreshSummaryTab() {
		this._messageService.publish({ key: 'update' });
	}
}
