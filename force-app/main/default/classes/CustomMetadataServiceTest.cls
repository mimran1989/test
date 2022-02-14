/**
 *  Provus Services Quoting
 *  CustomMetadataServiceTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private class CustomMetadataServiceTest {
	@isTest
	static void itShouldGetTheProductDefaultFields() {
		Set<String> productFields = new CustomMetadataService().getProductDefaultFields();
		System.assert(productFields.size() == 4, 'there should be 4 product fields');
		System.assert(productFields.contains('Id'), 'Id should be one of the fields');
		System.assert(productFields.contains('Name'), 'Name should be one of the fields');
		System.assert(
			productFields.contains(Schema.Quote__c.Practice__c + ''),
			'Practice__c should be one of the fields'
		);
		System.assert(
			productFields.contains(Schema.Quote__c.Group__c + ''),
			'Group__c should be one of the fields'
		);
	}

	@isTest
	static void itShouldGetTheQuoteItemItemDefaultFields() {
		Set<String> quoteItemFields = new CustomMetadataService().getQuoteItemDefaultFields();
		System.assert(quoteItemFields.size() == 11, 'there should be 11 quote item fields');
		System.assert(quoteItemFields.contains('Id'), 'Id should be one of the fields');
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.AdjustedUnitPrice__c + ''),
			'AdjustedUnitPrice__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.Frequency__c + ''),
			'Frequency__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.MarginPercent__c + ''),
			'MarginPercent__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.PriceMethod__c + ''),
			'PriceMethod__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.PriceMethodMarkdown__c + ''),
			'PriceMethodMarkdown__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.ProductId__c + ''),
			'ProductId__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.SkillLevel__c + ''),
			'SkillLevel__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.UnitCost__c + ''),
			'UnitCost__c should be one of the fields'
		);
		System.assert(
			quoteItemFields.contains(Schema.QuoteItem__c.UnitPrice__c + ''),
			'UnitPrice__c should be one of the fields'
		);
	}

	@isTest
	static void itShouldGetTheHiddenFields() {
		Set<String> hiddenFields = new CustomMetadataService().getHiddenFields();
		System.assert(hiddenFields.size() == 0, 'hidden fields should be empty');
	}

	@isTest
	static void itShouldGetTheRequiredFields() {
		Set<String> requiredFields = new CustomMetadataService().getRequiredFields();
		System.assert(requiredFields.size() == 0, 'required fields should be empty');
	}

	@isTest
	static void itShouldGetTheUneditableFields() {
		Set<String> uneditableFields = new CustomMetadataService().getUneditableFields();
		System.assert(uneditableFields.size() == 0, 'uneditable fields should be empty');
	}
}
