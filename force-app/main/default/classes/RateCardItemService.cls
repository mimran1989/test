/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class RateCardItemService {
	// constants
	public static final String SOBJECT_NAME = 'RateCardItem__c';
	public static final String FIELD_NAME_PRODUCT_ID = 'ProductId__c';
	public static final String FIELD_NAME_RATECARD_ID = 'RateCardId__c';
	public static final String FIELD_NAME_LOCATION_DISPLAY_NAME = 'LocationDisplayName__c';
	public static final String FIELD_NAME_LOCATION_COUNTRY = 'LocationCountry__c';
	public static final String FIELD_NAME_UNIT_PRICE = 'UnitPrice__c';
	public static final String FIELD_NAME_UNIT_COST = 'UnitCost__c';
	public static final String FIELD_NAME_PRICE_UOM = 'PriceUOM__c';

	// wrapper for rate card item
	public class RateCardItemStruct {
		public Map<String, String> fieldValueMap;
		public RateCardItemStruct() {
		}
	}

	/**
	 * Gets products from rate card items
	 * @param   quoteId id of quote record
	 * @return  List<RateCardItem__c>
	 */
	public static List<RateCardItem__c> getRateCardItemsProducts(Id quoteId) {
		QuoteService qService = new QuoteService(quoteId);

		return [
			SELECT
				Id,
				ProductId__c,
				ProductId__r.Name,
				ProductId__r.IsActive,
				ProductId__r.Practice__c,
				ProductId__r.Group__c,
				ProductId__r.RecordTypeId
			FROM RateCardItem__c
			WHERE
				RateCardId__c = :qService.rateCardId
				AND ProductId__r.Practice__c = :qService.quotePractice
				AND ProductId__r.Group__c = :qService.quoteGroup
				AND ProductId__r.IsActive = TRUE
			WITH SECURITY_ENFORCED
		];
	}

	/**
	 * Gets all rate card items for a product
	 * @param   quoteId Id of the quote
	 * @param   productId Id of the product
	 * @return  List<RateCardItemStruct>
	 */
	public static List<RateCardItemStruct> getAllRateCardItemsForProduct(Id quoteId, Id productId) {
		List<RateCardItemStruct> rateCardItemList = new List<RateCardItemStruct>();

		// requested fields
		Set<String> rateCardItemsFieldSet = new Set<String>{
			'Id',
			SystemUtility.getNamespacePrefix() + FIELD_NAME_LOCATION_DISPLAY_NAME,
			SystemUtility.getNamespacePrefix() + FIELD_NAME_LOCATION_COUNTRY,
			SystemUtility.getNamespacePrefix() + FIELD_NAME_UNIT_PRICE,
			SystemUtility.getNamespacePrefix() + FIELD_NAME_UNIT_COST,
			SystemUtility.getNamespacePrefix() + FIELD_NAME_PRICE_UOM
		};

		// get attribute fields
		QuoteService qService = new QuoteService(quoteId);
		RateCardService rtService = new RateCardService(qService.rateCardId);
		rateCardItemsFieldSet.addAll(rtService.getAttributes());

		// where clause
		Map<String, String> conditionFieldsMap = new Map<String, String>();
		conditionFieldsMap.put(SystemUtility.getNamespacePrefix() + FIELD_NAME_PRODUCT_ID, productId);
		conditionFieldsMap.put(
			SystemUtility.getNamespacePrefix() + FIELD_NAME_RATECARD_ID,
			qService.rateCardId
		);

		// perform query and put in the result
		QueryRequest queryRequest = new QueryRequest(SystemUtility.getNamespacePrefix() + SOBJECT_NAME);
		queryRequest.requestedFields = rateCardItemsFieldSet;
		queryRequest.setFilterBy(conditionFieldsMap);
		for (RateCardItem__c rci : (List<RateCardItem__c>) SOQLUtility.querySObject(queryRequest)) {
			RateCardItemStruct thisRateCardItem = new RateCardItemStruct();
			Map<String, String> fieldValues = new Map<String, String>();
			for (String fld : rateCardItemsFieldSet) {
				fieldValues.put(fld, String.valueOf(rci.get(fld)));
			}
			thisRateCardItem.fieldValueMap = fieldValues;
			rateCardItemList.add(thisRateCardItem);
		}

		return rateCardItemList;
	}

	public static List<RateCardItem__c> getRateCardItems(Id rateCardId, Set<Id> resourceRoleIds) {
		String relatedProductName = SystemUtility.getChildRName(
			Schema.RateCardItem__c.ProductId__c,
			Schema.RateCardItem__c.ProductId__r.Name
		);
		Set<String> rateCardItemFields = new Set<String>();
		rateCardItemFields.add(Schema.RateCardItem__c.SkillLevel__c + '');
		rateCardItemFields.add(Schema.RateCardItem__c.LocationDisplayName__c + '');
		rateCardItemFields.add(Schema.RateCardItem__c.ProductId__c + '');
		rateCardItemFields.add(relatedProductName);

		Map<String, Set<Id>> rateCardItemConditions = new Map<String, Set<Id>>();
		rateCardItemConditions.put(Schema.RateCardItem__c.ProductId__c + '', resourceRoleIds);
		rateCardItemConditions.put(
			Schema.RateCardItem__c.RateCardId__c + '',
			new Set<Id>{ rateCardId }
		);

		QueryRequest queryRequest = new QueryRequest(Schema.RateCardItem__c.SObjectType);
		queryRequest.requestedFields = rateCardItemFields;
		queryRequest.setFilterBy(rateCardItemConditions);
		queryRequest.fieldBySortOrder = new Map<String, String>{
			relatedProductName => SOQLConstants.SORT_ASC
		};
		return (List<RateCardItem__c>) SOQLUtility.querySObject(queryRequest);
	}
}
