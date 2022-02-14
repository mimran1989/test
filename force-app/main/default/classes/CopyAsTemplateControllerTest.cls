/**
 *  Provus Services Quoting
 *  CopyAsTemplateControllerTest
 *  @2021 Provus Inc. All rights reserved.
 */
@IsTest
private class CopyAsTemplateControllerTest extends CopyTestsBase {
	@IsTest
	static void itShouldCopyTheQuoteFields() {
		Quote__c quoteToCopy = newQuote();

		Test.startTest();
		Quote__c copiedQuote = CopyAsTemplateController.copyAsTemplate(quoteToCopy.Id);
		System.assertEquals(
			quoteToCopy.TimePeriodsAlignment__c,
			copiedQuote.TimePeriodsAlignment__c,
			'Time Periods Alignment should be the same'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldChangeTheRecordTypeToTemplate() {
		Quote__c quoteToCopy = newQuote();

		Test.startTest();
		Quote__c copiedQuote = CopyAsTemplateController.copyAsTemplate(quoteToCopy.Id);
		System.assertEquals(
			copiedQuote.Type__c,
			QuoteService.RECORDTYPE_NAME_TEMPLATE,
			'Record Type Id should be the same'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldSetTheTemplateName() {
		Quote__c quoteToCopy = newQuote();

		Test.startTest();
		Quote__c copiedQuote = CopyAsTemplateController.copyAsTemplate(quoteToCopy.Id);

		quoteToCopy = [SELECT Name FROM Quote__c WHERE Id = :quoteToCopy.Id];
		System.assertEquals(
			copiedQuote.Name,
			'TEMPLATE FROM: ' + quoteToCopy.Name,
			'Name should be "TEMPLATE FROM: name'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldClearSpecialFields() {
		Quote__c quoteToCopy = newQuote();
		Quote__c templateQuote = newTemplate();

		Account testAccount = new Account(Name = 'Test Account');
		CRUDUtility.insertRecords(testAccount);

		Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', Account = testAccount);
		testOpportunity.CloseDate = System.Today();
		testOpportunity.StageName = 'Prospecting';
		CRUDUtility.insertRecords(testOpportunity);

		quoteToCopy.AccountId__c = testAccount.Id;
		quoteToCopy.OpportunityId__c = testOpportunity.Id;
		quoteToCopy.TemplateId__c = templateQuote.Id;
		quoteToCopy.Type__c = QuoteService.RECORDTYPE_NAME_TEMPLATE;

		CRUDUtility.updateRecords(quoteToCopy);

		Test.startTest();
		Quote__c copiedQuote = CopyAsTemplateController.copyAsTemplate(quoteToCopy.Id);

		System.assertEquals(copiedQuote.AccountId__c, null, 'Account Id should be null');
		System.assertEquals(copiedQuote.OpportunityId__c, null, 'Opportunity Id should be null');
		System.assertEquals(copiedQuote.TemplateId__c, null, 'Template Id should be null');
		Test.stopTest();
	}
}
