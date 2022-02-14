/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteSummariesController {
	@AuraEnabled
	public static String getQuoteSummaries(Id quoteId) {
		return JSON.serialize(QuoteConfiguratorSupport.getQuoteSummaries(quoteId));
	}
}
