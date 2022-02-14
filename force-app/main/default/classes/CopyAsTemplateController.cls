/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CopyAsTemplateController {
	@AuraEnabled
	public static Quote__c copyAsTemplate(Id recordId) {
		Quote__c clonedQuote = QuoteService.cloneQuote(recordId);
		if (clonedQuote != null) {
			clonedQuote.Type__c = QuoteService.RECORDTYPE_NAME_TEMPLATE;
			clonedQuote.Name = 'TEMPLATE FROM: ' + clonedQuote.Name;
			clonedQuote.AccountId__c = null;
			clonedQuote.OpportunityId__c = null;
			clonedQuote.TemplateId__c = null;

			CRUDUtility.updateRecords(clonedQuote);
		}

		return clonedQuote;
	}
}
