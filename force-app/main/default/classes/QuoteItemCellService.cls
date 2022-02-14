/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteItemCellService {
	/**
	 * Queries and returns the quote item cells with fields needed for merge for the given
	 * quote item IDs.
	 * @param quoteItemIds A list of quote item IDs
	 *
	 * @return A list of quote item cells under the given quote item IDs
	 */
	public static List<QuoteItemCell__c> getCellsForMergeFor(Set<Id> quoteItemIds) {
		QueryRequest queryRequest = new QueryRequest(Schema.QuoteItemCell__c.SObjectType);
		queryRequest.requestedFields = SObjectUtility.getCustomFieldsForSObject(
			Schema.QuoteItemCell__c.SObjectType + ''
		);
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ QuoteItemCell.FIELD_NAME_QUOTE_ITEM_ID => quoteItemIds }
		);
		return (List<QuoteItemCell__c>) SOQLUtility.querySObject(queryRequest);
	}

	public static QuoteItemCellResponse createQuoteItemCell(
		Decimal quoteItemSpan,
		QuoteItem__c quoteItemSO,
		Integer startCellCount
	) {
		QuoteItemCellResponse itemCellResp = new QuoteItemCellResponse();

		QuoteItemCell__c itemCell = new QuoteItemCell__c();
		itemCell.QuoteItemId__c = quoteItemSO.Id;
		for (; quoteItemSpan > 0; startCellCount++) {
			if (quoteItemSpan > 1) {
				itemCell.put('C' + String.valueOf(startCellCount).leftPad(3, '0') + '__c', 1);
				quoteItemSpan -= 1;
			} else {
				itemCell.put('C' + String.valueOf(startCellCount).leftPad(3, '0') + '__c', quoteItemSpan);
				quoteItemSpan -= quoteItemSpan;
			}
		}

		itemCellResp.quoteItemCell = itemCell;
		itemCellResp.endCellPos = startCellCount;
		return itemCellResp;
	}

	public class QuoteItemCellResponse {
		public QuoteItemCell__c quoteItemCell;
		public Integer endCellPos;
	}
}
