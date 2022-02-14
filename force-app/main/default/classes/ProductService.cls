/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ProductService {
	// constants
	public static final String SOBJECT_NAME = 'Product2';
	public static final String RECORDTYPE_NAME_ANCILLARY = 'Ancillary';
	public static final String FIELD_ASSOCIATEDPRODUCTID = 'AssociatedProductId__c';
	public static final String RFIELD_ASSOCIATEDPRODUCTID = 'AssociatedProductId__r';

	public static final String RECORDTYPE_NAME_SERVICE = 'Service';

	// wrapper for product and related id
	public class ProductStruct {
		@AuraEnabled
		public String name;
		@AuraEnabled
		public String id;
		@AuraEnabled
		public Boolean isMiscellaneous;
	}

	/**
	 * Gets all valid products for a quote
	 * @param   quoteId Id of the quote
	 * @return  Serialized JSON string
	 */
	public static Set<ProductStruct> getAllProductsForQuote(Id quoteId) {
		Set<ProductStruct> productStructSet = new Set<ProductStruct>();
		for (
			Product2 prd : getProductsFromRateCardItems(
				RateCardItemService.getRateCardItemsProducts(quoteId)
			)
		) {
			ProductService.ProductStruct thisProductStruct = new ProductService.ProductStruct();
			thisProductStruct.id = prd.Id;
			thisProductStruct.name = prd.Name;
			thisProductStruct.isMiscellaneous =
				Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
					.get(RECORDTYPE_NAME_ANCILLARY)
					.getRecordTypeId() == prd.RecordTypeId;
			productStructSet.add(thisProductStruct);
		}

		return productStructSet;
	}

	/**
	 * Gets products from rate card items
	 * @param   List<RateCardItem__c>
	 * @return  Set<Product2>
	 */
	public static Set<Product2> getProductsFromRateCardItems(List<RateCardItem__c> rateCardItemList) {
		Set<Product2> productSet = new Set<Product2>();

		for (RateCardItem__c rci : rateCardItemList) {
			productSet.add(rci.ProductId__r);
		}

		return productSet;
	}
}
