/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class AdjustmentService {
	public class AdjustmentCloneInfo {
		private Map<Id, Map<Id, SObject>> copiedItems;
		Map<Id, Set<Id>> oldToNewItemIds = new Map<Id, Set<Id>>();
		Map<Id, Id> newToOldId = new Map<Id, Id>();

		public AdjustmentCloneInfo(Map<Id, Map<Id, SObject>> copiedQuoteItems) {
			this.copiedItems = copiedQuoteItems;
			for (Map<Id, SObject> quoteItemsByOldId : this.copiedItems.values()) {
				for (Id oldItemId : quoteItemsByOldId.keySet()) {
					QuoteItem__c quoteItem = (QuoteItem__c) quoteItemsByOldId.get(oldItemId);
					if (quoteItem.Id != null) {
						Set<Id> newItemIds = this.oldToNewItemIds.get(oldItemId);
						if (newItemIds == null) {
							newItemIds = new Set<Id>();
							this.oldToNewItemIds.put(oldItemId, newItemIds);
						}
						this.newToOldId.put(quoteItem.AdjustmentId__c, oldItemId);
						newItemIds.add(quoteItem.Id);
					}
				}
			}
		}

		public Map<Id, Set<Id>> getOldToNewIds() {
			return oldToNewItemIds;
		}

		public Map<Id, Id> getNewToOldIds() {
			return newToOldId;
		}
	}

	public static Map<Id, Adjustment__c> getAdjustmentsToInsert(AdjustmentCloneInfo adjCloneInfo) {
		// STEP V - Clone the adjustment records
		QueryRequest queryRequest = new QueryRequest(Adjustment__c.SObjectType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(
			Schema.Adjustment__c.SObjectType
		);
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{
				SObjectUtility.FIELD_ID => new Set<Id>(adjCloneInfo.getNewToOldIds().keySet())
			}
		);
		List<Adjustment__c> newAdjustments = (List<Adjustment__c>) SOQLUtility.querySObject(
			queryRequest
		);

		Map<Id, Adjustment__c> adjustmentsToInsert = new Map<Id, Adjustment__c>();
		Id userId = UserInfo.getUserId();
		for (Adjustment__c adjustment : newAdjustments) {
			for (
				Id newId : adjCloneInfo.getOldToNewIds()
					.get(adjCloneInfo.getNewToOldIds().get(adjustment.Id))
			) {
				Adjustment__c newAdjustment = adjustment.clone(false, true);
				newAdjustment.OwnerId = userId;
				adjustmentsToInsert.put(newId, newAdjustment);
			}
		}
		return adjustmentsToInsert;
	}

	public static List<QuoteItem__c> updateAdjustmentIdOnQuoteItems(
		Map<Id, Adjustment__c> adjustmentsToInsert
	) {
		// STEP VI - Quote items adjustment record
		List<QuoteItem__c> quoteItemsToUpdate = new List<QuoteItem__c>();
		for (Id newQuoteItemId : adjustmentsToInsert.keySet()) {
			String quoteItemIdString = String.valueOf(newQuoteItemId);
			if (String.isNotBlank(quoteItemIdString)) {
				quoteItemsToUpdate.add(
					new QuoteItem__c(
						Id = newQuoteItemId,
						AdjustmentId__c = adjustmentsToInsert.get(newQuoteItemId).Id
					)
				);
			}
		}

		CRUDUtility.updateRecords(quoteItemsToUpdate);

		return quoteItemsToUpdate;
	}

	public static List<QuoteItemCell__c> getQuoteItemCellsToInsert(AdjustmentCloneInfo adjCloneInfo) {
		// STEP VII - Clone the quote item cells
		List<QuoteItemCell__c> quoteItemCellsToInsert = new List<QuoteItemCell__c>();
		Map<Id, Map<Id, SObject>> newQuoteItemCells = SystemUtility.cloneChildEntities(
			QuoteItemCell__c.SObjectType,
			QuoteItemCell.FIELD_NAME_QUOTE_ITEM_ID,
			adjCloneInfo.getOldToNewIds()
		);

		if (newQuoteItemCells.size() > 0) {
			for (Map<Id, SObject> quoteItemCellsByOldId : newQuoteItemCells.values()) {
				quoteItemCellsToInsert.addAll((List<QuoteItemCell__c>) quoteItemCellsByOldId.values());
			}
		}
		return quoteItemCellsToInsert;
	}
}
