/**
 *  Provus Services Quoting
 *  CreateNewScenario
 *
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CreateNewScenarioController {
	// constants
	private static final String REVENUE_ADJUSTMENT = 'Revenue Adjustment';
	private static final String MARGIN_ADJUSTMENT = 'Margin Adjustment';
	private static final String RULE_BASED_ADJUSTMENT = 'Rule-Based Adjustment';

	public class QuoteAdjustment {
		public String type;
		public String name;
		public Integer value;
	}

	/**
	 * Gets Quote details
	 * @param   quoteId Id of the quote
	 * @return  List<Quote__c>
	 */
	@AuraEnabled
	public static List<Quote__c> getQuoteDetails(Id quoteId) {
		Set<String> quoteFields = new Set<String>();
		quoteFields.add(Schema.Quote__c.AccountId__c + '');
		quoteFields.add(
			SystemUtility.getChildRName(Schema.Quote__c.AccountId__c, Schema.Quote__c.AccountId__r.Name)
		);
		quoteFields.add(Schema.Quote__c.MarginPercent__c + '');
		quoteFields.add(Schema.Quote__c.TotalAmount__c + '');

		QueryRequest queryRequest = new QueryRequest(Schema.Quote__c.SObjectType);
		queryRequest.requestedFields = quoteFields;
		queryRequest.setFilterBy(new Map<String, String>{ 'Id' => quoteId });
		List<Quote__c> quotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);

		return quotes;
	}

	/**
	 * clone Quote to Scenario
	 * @param quoteId id of the quote
	 * @param adjustment
	 *
	 * @return returns Quote scenario record id
	 */
	@AuraEnabled
	public static String cloneQuoteToScenario(String quoteId, String adjustment) {
		QuoteAdjustment adjustmentDO = new QuoteAdjustment();
		adjustmentDO = (QuoteAdjustment) JSON.deserializeStrict(adjustment, QuoteAdjustment.class);

		Quote__c sourceQuote = [
			SELECT Id, DerivedFromId__c
			FROM Quote__c
			WHERE Id = :quoteId
			WITH SECURITY_ENFORCED
		];
		Quote__c scenarioRecord;
		scenarioRecord = QuoteService.cloneQuote(quoteId);

		scenarioRecord.Name = adjustmentDO.name;
		scenarioRecord.Status__c = 'Active';
		scenarioRecord.Version__c = 1;
		scenarioRecord.Type__c = QuoteService.RECORDTYPE_NAME_SCENARIO;

		scenarioRecord.IsPrimary__c = false;

		if (sourceQuote.DerivedFromId__c != null) {
			scenarioRecord.DerivedFromId__c = sourceQuote.DerivedFromId__c;
		}

		if (adjustmentDO.type.Equals(REVENUE_ADJUSTMENT)) {
			scenarioRecord.TotalAmount__c = Integer.ValueOf(adjustmentDO.value);
			scenarioRecord.MarginPercent__c = null;
		} else if (adjustmentDO.type.Equals(MARGIN_ADJUSTMENT)) {
			scenarioRecord.TotalAmount__c = null;
			scenarioRecord.MarginPercent__c = Integer.ValueOf(adjustmentDO.value);
		}

		CRUDUtility.updateRecords(scenarioRecord);

		return scenarioRecord.Id;
	}
}
