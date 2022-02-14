/**
 *  Provus Services Quoting
 *  MakeScenarioPrimaryController
 *
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class MakeScenarioPrimaryController {
	/**
	 * clone Sceanrio to Quote
	 * @param   quoteId Id of the quote
	 * @return  Quote Record Id
	 */
	@AuraEnabled
	public static string cloneScenarioToPrimaryQuote(String scenarioId) {
		Quote__c scenarioRecord = getScenarioRecord(scenarioId);
		Quote__c clonedQuote = cloneToQuoteRecordType(scenarioRecord);
		scenarioRecord.Status__c = 'Inactive';
		CRUDUtility.updateRecords(scenarioRecord);

		Quote__c derviedFromQuote = new Quote__c(
			Id = scenarioRecord.DerivedFromId__c,
			IsPrimary__c = false
		);
		CRUDUtility.updateRecords(derviedFromQuote);
		return clonedQuote.Id;
	}

	/**
	 * clone to Quote RecordType
	 * @param   Quote record
	 * @return  Quote Record of Quote type
	 */
	public static Quote__c cloneToQuoteRecordType(Quote__c scenarioRecord) {
		Quote__c clonedQuote = scenarioRecord.clone(false, false, false, false);
		clonedQuote.IsPrimary__c = true;
		clonedQuote.Type__c = QuoteService.RECORDTYPE_NAME_QUOTE;
		clonedQuote.DerivedFromId__c = null;
		CRUDUtility.insertRecords(clonedQuote);
		QuoteService.copyQuoteChildEntities(scenarioRecord.Id, clonedQuote.Id, null);
		return clonedQuote;
	}

	/**
	 * get Sceanrio record
	 * @param scenarioId Id of the scenario
	 *
	 * @return returns scenario quote record
	 */
	public static Quote__c getScenarioRecord(String scenarioId) {
		QueryRequest queryRequest = new QueryRequest(Schema.Quote__c.SObjectType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(Schema.Quote__c.SObjectType);
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => scenarioId });
		List<Quote__c> scenarioRecords = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);

		return !scenarioRecords.isEmpty() ? scenarioRecords[0] : null;
	}
}
