/**
 *  Provus Services Quoting
 *  CopyTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class CopyTestsBase extends TestBase {
	public static Quote__c newTemplate() {
		Quote__c newQuote = new Quote__c();
		newQuote.Type__c = QuoteService.RECORDTYPE_NAME_TEMPLATE;
		CRUDUtility.insertRecords(newQuote);
		return newQuote;
	}
}
