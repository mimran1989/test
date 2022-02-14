/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteItemCell {
	// constants
	public static final String SOBJECT_NAME = 'QuoteItemCell__c';
	public static final String QUOTE_ITEM_CHILD_RELATIONSHIP = 'QuoteItemCells__r';
	public static final String PERIOD_FIELD_PREFIX = SystemUtility.getNamespacePrefix() + 'c';
	public static final String FIELD_NAME_QUOTE_ITEM_ID = 'QuoteItemId__c';
	// instance variables
	private static List<String> periodColumns;

	public static List<String> getPeriodColumns() {
		if (periodColumns == null) {
			periodColumns = new List<String>();
			for (
				String fieldName : SObjectUtility.getCustomFieldsForSObject(
					Schema.QuoteItemCell__c.SObjectType + ''
				)
			) {
				if (fieldName.startsWith(PERIOD_FIELD_PREFIX.toLowerCase())) {
					periodColumns.add(fieldName);
				}
			}
		}

		return periodColumns;
	}
}
