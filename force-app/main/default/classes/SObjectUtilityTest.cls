/**
 *  Provus Services Quoting
 *  SObjectUtilityTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
public with sharing class SObjectUtilityTest extends TestBase {
	@isTest
	static void itShouldReturnPicklistValues() {
		Test.startTest();
		List<String> picklistValues = SObjectUtility.getPicklistValuesFor(
			Schema.Quote__c.Status__c.getDescribe().getPickListValues()
		);
		Test.stopTest();

		System.assert(picklistValues.size() > 0, 'picklist values not returend properly');
	}

	@isTest
	static void itShouldReturnObjectFields() {
		Test.startTest();
		Set<String> fields = SObjectUtility.getFieldsForSObject(Quote__c.sObjectType);
		Test.stopTest();

		System.assert(fields.size() > 0, 'returned fields are empty');
	}

	@isTest
	static void itShouldReturnAncillaryRecordTypeId() {
		Test.startTest();
		Id recordId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Ancillary');
		Test.stopTest();

		Id ancillaryRecordId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
			.get('Ancillary')
			.getRecordTypeId();

		System.assertEquals(ancillaryRecordId, recordId, 'record id is not correct');
	}
}
