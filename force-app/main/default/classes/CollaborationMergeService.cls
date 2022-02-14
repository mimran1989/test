/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */

public with sharing class CollaborationMergeService {
	public static final Set<String> EXCLUDED_ITEM_FIELDS = new Set<String>{
		Schema.QuoteItem__c.AdjustmentId__c + '',
		Schema.QuoteItem__c.DerivedFromId__c + '',
		Schema.QuoteItem__c.Id + '',
		Schema.QuoteItem__c.Name + '',
		Schema.QuoteItem__c.QuoteId__c + '',
		Schema.QuoteItem__c.QuoteSectionId__c + '',
		Schema.QuoteItem__c.Sequence__c + '',
		SystemUtility.getRName(Schema.QuoteItem__c.AdjustmentId__c)
	};

	public static final Set<String> EXCLUDED_CELL_FIELDS = new Set<String>{
		Schema.QuoteItemCell__c.Id + '',
		Schema.QuoteItemCell__c.Name + '',
		Schema.QuoteItemCell__c.QuoteItemId__c + ''
	};

	public static final Set<String> EXCLUDED_ADJUSTMENT_FIELDS = new Set<String>{
		Schema.Adjustment__c.Id + '',
		Schema.Adjustment__c.Name + '',
		Schema.Adjustment__c.NamedRangeId__c + ''
	};

	private static List<SObject> updateObjects = new List<SObject>();
	private static List<Adjustment__c> updateAdjustments = new List<Adjustment__c>();
	private static List<QuoteItemCell__c> updateCells = new List<QuoteItemCell__c>();

	private class ClonedEntity {
		QuoteItem__c item;
		Adjustment__c adj;
		QuoteItemCell__c cell;

		public ClonedEntity(Id quoteId, QuoteItem__c sourceItem) {
			this.item = sourceItem.clone(false, true);
			this.item.QuoteId__c = quoteId;
		}
	}

	/**
	 * Merges the section changes whose target is the given section IDs and the given
	 * quote.
	 * @param targetQuoteId A target quote ID
	 * @param targetSectionIds A list of target section IDs
	 */
	public static void mergeSections(Id targetQuoteId, List<Id> targetSectionIds) {
		Map<Id, QuoteSection__c> sectionById = new Map<Id, QuoteSection__c>(
			CollaborationSectionService.getMergeReadyLineage(targetSectionIds)
		);

		Map<Id, Id> targetSectionIdBySourceSectionId = new Map<Id, Id>();
		for (QuoteSection__c section : sectionById.values()) {
			if (section.DerivedFromId__c != null) {
				targetSectionIdBySourceSectionId.put(section.Id, section.DerivedFromId__c);
			}
		}

		Map<Id, QuoteItem__c> quoteItemById = new Map<Id, QuoteItem__c>(
			QuoteItemService.getQuoteItemsForMergeFor(sectionById.keySet())
		);

		Map<Id, QuoteItemCell__c> quoteItemCellByItemId = (Map<Id, QuoteItemCell__c>) SystemUtility.keyByIdType(
			QuoteItemCellService.getCellsForMergeFor(quoteItemById.keySet()),
			Schema.QuoteItemCell__c.QuoteItemId__c
		);

		// determine the source items
		List<QuoteItem__c> allSourceItems = new List<QuoteItem__c>();
		Map<Id, QuoteItem__c> sourceItemByDerivedId = new Map<Id, QuoteItem__c>();
		List<QuoteItem__c> targetItems = new List<QuoteItem__c>();
		for (QuoteItem__c item : quoteItemById.values()) {
			if (item.QuoteId__c != targetQuoteId) {
				allSourceItems.add(item);
				sourceItemByDerivedId.put(item.DerivedFromId__c, item);
			} else {
				targetItems.add(item);
			}
		}

		List<ClonedEntity> entities = new List<ClonedEntity>();
		for (QuoteItem__c sourceItem : allSourceItems) {
			if (sourceItem.DerivedFromId__c != null) {
				// matching source and target items
				QuoteItem__c targetItem = quoteItemById.get(sourceItem.DerivedFromId__c);
				mergeQuoteItem(sourceItem, targetItem);
				mergeAdjustments(sourceItem.AdjustmentId__r, targetItem.AdjustmentId__r);
				mergeQuoteItemCell(
					quoteItemCellByItemId.get(sourceItem.Id),
					quoteItemCellByItemId.get(targetItem.Id)
				);
			} else {
				ClonedEntity entity = new ClonedEntity(targetQuoteId, sourceItem);
				entity.item.QuoteSectionId__c = targetSectionIdBySourceSectionId.get(
					sourceItem.QuoteSectionId__c
				);

				if (sourceItem.AdjustmentId__r != null) {
					entity.adj = sourceItem.AdjustmentId__r.clone(false, true);
				}

				entity.cell = quoteItemCellByItemId.get(sourceItem.Id).clone(false, true);
				entities.add(entity);
			}
		}

		processClone(entities);
		CRUDUtility.deleteRecords(rejectQuoteItems(targetItems, sourceItemByDerivedId.keySet()));

		updateObjects.addAll(updateAdjustments);
		updateObjects.addAll(updateCells);
		CRUDUtility.updateRecords(updateObjects);

		CollaborationRequestService.markAsMerged(new List<Id>(sectionById.keySet()));
		QuoteItemService.resequenceItemsFor(targetQuoteId);
	}

	/**
	 * Processes the cloned entities, building them from top-down.
	 * @param entities A list of cloned entities
	 */
	private static void processClone(List<ClonedEntity> entities) {
		List<QuoteItem__c> newItems = new List<QuoteItem__c>();
		List<Adjustment__c> newAdjs = new List<Adjustment__c>();
		List<QuoteItemCell__c> newCells = new List<QuoteItemCell__c>();

		for (ClonedEntity entity : entities) {
			newItems.add(entity.item);
			newAdjs.add(entity.adj);
			newCells.add(entity.cell);
		}

		CRUDUtility.insertRecords(newAdjs);

		for (ClonedEntity entity : entities) {
			if (entity.adj != null) {
				entity.item.AdjustmentId__c = entity.adj.Id;
			}
		}

		CRUDUtility.insertRecords(newItems);

		for (ClonedEntity entity : entities) {
			entity.cell.QuoteItemId__c = entity.item.Id;
		}

		CRUDUtility.insertRecords(newCells);
	}

	/**
	 * Returns a list of quote items whose IDs are not in the given rejected list.
	 * @param items A list of quote items
	 * @param rejectedIds A list of rejected IDs
	 *
	 * @return A list of quote items excluding the omitted list
	 */
	private static List<QuoteItem__c> rejectQuoteItems(
		List<QuoteItem__c> items,
		Set<Id> rejectedIds
	) {
		List<QuoteItem__c> resultItems = new List<QuoteItem__c>();
		for (QuoteItem__c targetItem : items) {
			if (!rejectedIds.contains(targetItem.Id)) {
				resultItems.add(targetItem);
			}
		}

		return resultItems;
	}

	/**
	 * Merges the source fields into the target.
	 * @param source A source
	 * @param target A target
	 */
	public static void mergeQuoteItem(QuoteItem__c source, QuoteItem__c target) {
		if (source == null || target == null) {
			return;
		}

		copyFieldValues(source, target, EXCLUDED_ITEM_FIELDS);
		updateObjects.add(target);
	}

	/**
	 * Merges the source fields into the target.
	 * @param source A source
	 * @param target A target
	 */
	public static void mergeAdjustments(Adjustment__c source, Adjustment__c target) {
		if (source == null || target == null) {
			return;
		}

		copyFieldValues(source, target, EXCLUDED_ADJUSTMENT_FIELDS);
		updateAdjustments.add(target);
	}

	/**
	 * Merges the source fields into the target.
	 * @param source A source
	 * @param target A target
	 */
	public static void mergeQuoteItemCell(QuoteItemCell__c source, QuoteItemCell__c target) {
		if (source == null || target == null) {
			return;
		}

		copyFieldValues(source, target, EXCLUDED_CELL_FIELDS);
		updateCells.add(target);
	}

	/**
	 * Copies field values from source to target, including null values.
	 * @param source A source object
	 * @param target A target object of the same type
	 * @param excludedFields A list of fields not to copy
	 */
	public static void copyFieldValues(SObject source, SObject target, Set<String> excludedFields) {
		Map<String, Object> sourceMap = source.getPopulatedFieldsAsMap();
		Map<String, Object> targetMap = target.getPopulatedFieldsAsMap();

		Map<String, Schema.SObjectField> objFields = source.getSObjectType()
			.getDescribe()
			.fields.getMap();

		for (String field : sourceMap.keySet()) {
			if (!excludedFields.contains(field) && !objFields.get(field).getDescribe().isCalculated()) {
				Object value = sourceMap.get(field);
				target.put(field, value);
			}
		}

		for (String field : targetMap.keySet()) {
			if (
				!excludedFields.contains(field) &&
				!sourceMap.containsKey(field) &&
				!objFields.get(field).getDescribe().isCalculated()
			) {
				target.put(field, null);
			}
		}
	}
}
