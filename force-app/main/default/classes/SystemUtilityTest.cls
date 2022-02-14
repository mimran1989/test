/**
 *  Provus Services Quoting
 *  SystemUtilityTest
 *  @2021 Provus Inc. All rights reserved.
 */

@isTest
private class SystemUtilityTest extends TestBase {
	@isTest
	static void itShouldReturnthePackageNamespace() {
		String pkgNameSpace = SystemUtility.getNamespacePrefix();
		System.assertNotEquals(
			null,
			pkgNameSpace,
			'namespace should be defined as any value (including empty space)'
		);
	}

	@isTest
	static void itShouldSplitUniqueStrings() {
		String commaString = 'Test1,    Test1, Test2';
		Set<String> stringSet = SystemUtility.csvToSet(commaString);

		System.assertEquals(stringSet.size(), 2, 'there should only be 2 unique values');
		System.assert(stringSet.contains('Test1'), 'Test1 should be one of the values');
		System.assert(stringSet.contains('Test2'), 'Test2 should be one of the values');
	}

	@isTest
	static void itShouldTrimTheWhitespace() {
		String commaString = 'Test1,       Test2,Test3     , Test4';
		Set<String> stringSet = SystemUtility.csvToSet(commaString);

		System.assertEquals(stringSet.size(), 4, 'there should only be 4 unique values');
		System.assert(stringSet.contains('Test1'), 'Test1 should be one of the values');
		System.assert(stringSet.contains('Test2'), 'Test2 should be one of the values');
		System.assert(stringSet.contains('Test3'), 'Test3 should be one of the values');
		System.assert(stringSet.contains('Test4'), 'Test4 should be one of the values');
	}

	@IsTest
	static void shouldReturnInverseName() {
		Test.startTest();
		System.assertNotEquals(
			'',
			SystemUtility.getInverseRName(
				Schema.Quote__c.SObjectType,
				Schema.CollaborationRequest__c.SObjectType
			),
			'should return a relationship'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldGiveChildRelationshipName() {
		Test.startTest();
		String childRName = SystemUtility.getChildRName(
			Schema.TaskRoleSummary__c.ActivityGroupId__c,
			Schema.ActivityGroup__c.Sequence__c
		);
		String nsPrefix = SystemUtility.getNamespacePrefix();
		String expectedChildRName = nsPrefix + 'ActivityGroupId__r.' + nsPrefix + 'Sequence__c';
		System.assertEquals(
			expectedChildRName,
			childRName,
			'it should return the full child relationship field name'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldCopyTheItems() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c sectionSO1 = newQuoteSection(quoteSO.Id);
		QuoteSection__c sectionSO2 = newQuoteSection(quoteSO.Id);

		QuoteItem__c quoteItemSO1 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO1.Id
		);
		QuoteItem__c quoteItemSO2 = new QuoteItem__c(
			QuoteId__c = quoteSO.Id,
			QuoteSectionId__c = sectionSO2.Id
		);
		CRUDUtility.insertRecords(new List<QuoteItem__c>{ quoteItemSO1, quoteItemSO2 });

		Test.startTest();
		Quote__c clonedQuote = QuoteService.cloneQuote(quoteSO.Id, new Set<Id>());
		List<QuoteItem__c> items = [
			SELECT Id, QuoteSectionId__c
			FROM QuoteItem__c
			WHERE QuoteId__c = :clonedQuote.Id
		];

		System.assert(items.size() == 2, 'should copy all items when quote section set is empty');
		Test.stopTest();
	}
}
