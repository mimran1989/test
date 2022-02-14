/**
 *  Provus Services Quoting
 *  QuoteItemService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class QuoteItemService {
	/**
	 * Gets all quote items for quote
	 * @param   quoteId Id of the quote
	 * @return  List<QuoteItemStruct>
	 */
	public static List<QuoteItemDTO> getQuoteItemsForQuote(Id quoteId) {
		List<QuoteItemDTO> quoteItemDOs = new List<QuoteItemDTO>();
		for (QuoteItem__c quoteItemSO : QuoteItemServiceSupport.getQuoteItemSOsForQuote(quoteId)) {
			QuoteItem quoteItem = new QuoteItem(QuoteItemDTO.newDO(quoteItemSO));
			quoteItemDOs.add((QuoteItemDTO) quoteItem.baseDTO);
		}

		return quoteItemDOs;
	}

	/**
	 * Commit quote items for quote
	 * @param quoteId  Id of the quote
	 * @param quoteItemDTOs list of quote item DOs
	 *
	 * @return list of committed quote items
	 */
	public static List<QuoteItemDTO> commitQuoteItems(Id quoteId, List<QuoteItemDTO> quoteItemDTOs) {
		List<QuoteItemDTO> quoteItemsToCommit = new List<QuoteItemDTO>();
		List<QuoteItemDTO> quoteItemsToDelete = new List<QuoteItemDTO>();
		List<QuoteItem__c> quoteItemSOsToDelete = new List<QuoteItem__c>();
		List<QuoteItem__c> quoteItemSOsToCommit = new List<QuoteItem__c>();

		for (QuoteItemDTO quoteItemDO : quoteItemDTOs) {
			// sync DTO data to the SO object
			quoteItemDO.updateSO();
			if (quoteItemDO.quoteItemSO.Id == null) {
				// non-reparentable master detail field
				quoteItemDO.quoteItemSO.QuoteId__c = quoteId;
			}

			if (!quoteItemDO.isDelete()) {
				quoteItemSOsToCommit.add(quoteItemDO.quoteItemSO);
				quoteItemsToCommit.add(quoteItemDO);
			} else {
				quoteItemSOsToDelete.add(quoteItemDO.quoteItemSO);
				quoteItemsToDelete.add(quoteItemDO);
			}
		}

		commitAdjustmentsFor(quoteItemsToCommit);
		deleteAdjustmentsFor(quoteItemsToDelete);

		CRUDUtility.deleteRecords(quoteItemSOsToDelete);
		CRUDUtility.upsertRecords(quoteItemSOsToCommit);

		commitQuoteItemCellsFor(quoteItemsToCommit);

		for (QuoteItemDTO quoteItemDO : quoteItemDTOs) {
			// update DO fields with SO field values
			quoteItemDO.refreshDO();
		}

		return quoteItemsToCommit;
	}

	/**
	 * Queries and returns the quote items with fields needed for merge for the given
	 * section IDs.
	 * @param sectionIds A list of sections IDs
	 *
	 * @return A list of quote items containing fields needed for merge
	 */
	public static List<QuoteItem__c> getQuoteItemsForMergeFor(Set<Id> sectionIds) {
		String nsPrefix = SystemUtility.getNamespacePrefix();
		String adjustmentFieldRName = SystemUtility.getRName(Schema.QuoteItem__c.AdjustmentId__c);
		String quoteItemObjName = nsPrefix + QuoteItem.SOBJECT_NAME;
		Set<String> fieldSet = SObjectUtility.getCustomFieldsForSObject(quoteItemObjName);
		fieldSet.add(adjustmentFieldRName + '.' + SObjectUtility.FIELD_ID);
		fieldSet.add(adjustmentFieldRName + '.' + Schema.Adjustment__c.Amount__c);
		fieldSet.add(adjustmentFieldRName + '.' + Schema.Adjustment__c.AppliedBy__c);
		fieldSet.add(adjustmentFieldRName + '.' + Schema.Adjustment__c.AppliedTo__c);
		fieldSet.add(adjustmentFieldRName + '.' + Schema.Adjustment__c.Method__c);

		QueryRequest queryRequest = new QueryRequest(quoteItemObjName);
		queryRequest.requestedFields = fieldSet;
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ Schema.QuoteItem__c.QuoteSectionId__c + '' => sectionIds }
		);
		return (List<QuoteItem__c>) SOQLUtility.querySObject(queryRequest);
	}

	private static void commitQuoteItemCellsFor(List<QuoteItemDTO> quoteItems) {
		List<QuoteItemCell__c> cellsToUpsert = new List<QuoteItemCell__c>();
		for (QuoteItemDTO ctxDO : quoteItems) {
			QuoteItemCell__c quoteItemCell = new QuoteItemCell__c(
				Id = ctxDO.quoteItemCellId,
				QuoteItemId__c = ctxDO.quoteItemSO.Id
			);

			for (String periodNumber : ctxDO.periodValueMap.keySet()) {
				Decimal periodValue = ctxDO.periodValueMap.get(periodNumber);
				String periodToken = quoteItemCellToken(periodNumber);
				quoteItemCell.put(periodToken, periodValue);
			}

			cellsToUpsert.add(quoteItemCell);
		}

		CRUDUtility.upsertRecords(cellsToUpsert);

		Integer loopIdx = 0;
		for (QuoteItemDTO ctxDO : quoteItems) {
			ctxDO.quoteItemCellId = cellsToUpsert[loopIdx++].Id;
		}
	}

	private static String quoteItemCellToken(String periodNumber) {
		return QuoteItemCell.PERIOD_FIELD_PREFIX + periodNumber + SObjectUtility.CUSTOM_FIELD_INDICATOR;
	}

	/**
	 * Resequences the quote items for the given quote ID.
	 * @param quoteId A quote ID
	 */
	public static void resequenceItemsFor(Id quoteId) {
		Integer nextSequence = 1;
		List<QuoteItem__c> quoteItems = new List<QuoteItem__c>();
		for (QuoteItem__c itemSO : [
			SELECT Id, Sequence__c
			FROM QuoteItem__c
			WHERE QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
			ORDER BY QuoteSectionId__r.Sequence__c NULLS LAST, SectionSequence__c, Sequence__c
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		]) {
			if (itemSO.Sequence__c != nextSequence) {
				itemSO.Sequence__c = nextSequence;
				quoteItems.add(itemSO);
			}

			nextSequence += 1;
		}

		CRUDUtility.updateRecords(quoteItems);
	}

	private static void commitAdjustmentsFor(List<QuoteItemDTO> quoteItems) {
		List<Adjustment__c> adjustmentsToUpsert = new List<Adjustment__c>();
		for (QuoteItemDTO ctxDO : quoteItems) {
			Adjustment__c adjustmentSO = ctxDO.adjustment.getSObject();
			adjustmentSO.Method__c = Adjustment.METHOD_INITIAL;
			adjustmentsToUpsert.add(adjustmentSO);
			CRUDUtility.upsertRecords(adjustmentsToUpsert);
		}

		// Resolve the Adjustment Id for Quote Items
		Integer loopIdx = 0;
		for (QuoteItemDTO ctxDO : quoteItems) {
			Adjustment__c ctxAdjustment = adjustmentsToUpsert[loopIdx++];
			ctxDO.quoteItemSO.AdjustmentId__c = ctxAdjustment.Id;
			ctxDO.adjustmentId = ctxAdjustment.Id;
		}
	}

	private static void deleteAdjustmentsFor(List<QuoteItemDTO> quoteItems) {
		List<Adjustment__c> adjustmentsToDelete = new List<Adjustment__c>();
		for (QuoteItemDTO ctxDO : quoteItems) {
			if (ctxDO.adjustmentId != null) {
				Adjustment__c adjustmentToDelete = new Adjustment__c();
				adjustmentToDelete.Id = ctxDO.adjustmentId;
				adjustmentsToDelete.add(adjustmentToDelete);
			}
		}

		CRUDUtility.deleteRecords(adjustmentsToDelete);
	}

	public static void deleteQuoteItemNamedRange(List<QuoteItem__c> quoteItemId) {
		List<NamedRange> requestNamedRanges = new List<NamedRange>();
		List<NamedRange__c> namedRangeList = [
			SELECT
				Id,
				Type__c,
				NamedRangeTotalId__c,
				NamedRangeTotalId__r.Id,
				NamedRangeTotalId__r.NetExtendedAmount__c,
				NamedRangeTotalId__r.NetExtendedCost__c,
				NamedRangeTotalId__r.Quantity__c,
				NamedRangeTotalId__r.QuantityUOM__c,
				NamedRangeTotalId__r.MarginPercent__c,
				Name,
				QuoteId__c,
				QuoteItemId__c,
				QuotePeriodId__c,
				QuotePeriodGroupId__c,
				QuoteSectionId__c,
				ProjectPhaseId__c,
				RangeSpecJSON__c
			FROM NamedRange__c
			WHERE QuoteItemId__c IN :quoteItemId
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];

		NamedRange namedRangeDO;
		NamedRange.NamedRangeDO namedRangeDOs;
		for (NamedRange__c namedRangeSO : namedRangeList) {
			namedRangeDO = new NamedRange(namedRangeSO);
			namedRangeDO.baseDTO.operationType = ManagedObject.OPERATION_TYPE_DELETE;
			namedRangeDOs = (NamedRange.NamedRangeDO) namedRangeDO.baseDTO;
			namedRangeDOs.relatedtotal.operationType = ManagedObject.OPERATION_TYPE_DELETE;
			requestNamedRanges.add(new NamedRange(namedRangeDOs));
		}
		NamedRange.commitNamedRanges(requestNamedRanges);
	}
}
