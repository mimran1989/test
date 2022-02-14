/**
 *  Provus Services Quoting
 *  QuoteItemServiceSupport
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class QuoteItemServiceSupport {
	static final String FIELD_NAME_RADJUSTMENT_ID = SystemUtility.getRName(
		Schema.QuoteItem__c.AdjustmentId__c
	);

	public static List<QuoteItem__c> getQuoteItemSOsForQuote(Id quoteId) {
		Quote__c ctxQuote = [
			SELECT RateCardId__c
			FROM Quote__c
			WHERE Id = :quoteId
			WITH SECURITY_ENFORCED
		];
		CustomMetadataService cmService = new CustomMetadataService();

		// add product default fields
		Set<String> requestedFields = cmService.getProductDefaultFields();
		// add rate card attributes
		RateCardService rtService = new RateCardService(ctxQuote.RateCardId__c);
		requestedFields.addAll(rtService.getAttributes());
		// add quote item default fields
		requestedFields.addAll(cmService.getQuoteItemDefaultFields());

		requestedFields.addAll(
			new Set<String>{
				SObjectUtility.FIELD_ID,
				SObjectUtility.FIELD_NAME,
				Schema.QuoteItem__c.AdjustmentId__c + '',
				Schema.QuoteItem__c.DisplaySequence__c + '',
				Schema.QuoteItem__c.LineType__c + '',
				Schema.QuoteItem__c.ProductId__c + '',
				Schema.QuoteItem__c.QuoteId__c + '',
				Schema.QuoteItem__c.QuoteSectionId__c + '',
				Schema.QuoteItem__c.RateCardItemId__c + '',
				Schema.QuoteItem__c.SectionSequence__c + '',
				Schema.QuoteItem__c.Sequence__c + '',
				Schema.QuoteItem__c.RoleNameOverride__c + '',
				Schema.QuoteItem__c.Quantity__c + '',
				Schema.QuoteItem__c.NetExtendedAmount__c + '',
				Schema.QuoteItem__c.NetExtendedCost__c + '',
				Schema.QuoteItem__c.MarginPercent__c + '',
				Schema.QuoteItem__c.NonBillable__c + '',
				FIELD_NAME_RADJUSTMENT_ID +
				'.' +
				Schema.Adjustment__c.Amount__c,
				FIELD_NAME_RADJUSTMENT_ID +
				'.' +
				Schema.Adjustment__c.Type__c
			}
		);

		// build query string
		String qry = 'SELECT ';

		for (String fld : requestedFields) {
			qry += fld + ', ';
		}

		qry += '(SELECT ';
		qry += SObjectUtility.FIELD_ID;

		for (String fieldName : QuoteItemCell.getPeriodColumns()) {
			qry += ', ' + fieldName;
		}

		qry +=
			' FROM ' +
			SystemUtility.getNamespacePrefix() +
			QuoteItemCell.QUOTE_ITEM_CHILD_RELATIONSHIP +
			')';

		qry += ' FROM ' + SystemUtility.getNamespacePrefix() + QuoteItem.SOBJECT_NAME;
		qry += ' WHERE ' + Schema.QuoteItem__c.QuoteId__c + ' =: quoteId';
		qry += ' WITH SECURITY_ENFORCED';
		qry += ' ORDER BY ' + Schema.QuoteItem__c.Sequence__c + ' ASC';

		return Database.query(String.escapeSingleQuotes(qry));
	}
}
