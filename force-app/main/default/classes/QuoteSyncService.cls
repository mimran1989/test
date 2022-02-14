/**
 *  Provus Services Quoting
 *  QuoteSyncService
 *  @2021 Provus Inc. All rights reserved.
 *
 */
public with sharing class QuoteSyncService {
	public final static List<String> PROPOSAL_SYNC_FIELDS = new List<String>{
		Schema.Quote__c.TotalAmountBeforeDiscount__c + '',
		Schema.Quote__c.TotalAmount__c + '',
		Schema.Quote__c.TotalCost__c + '',
		Schema.Quote__c.DiscountAmount__c + ''
	};

	public static void deltaSyncQuotesToProposal(
		List<Quote__c> quotesToSync,
		Map<Id, Quote__c> oldQuotes,
		Map<Id, Proposal__c> proposals
	) {
		for (Quote__c quote : quotesToSync) {
			Quote__c oldQuote = (Quote__c) oldQuotes.get(quote.Id);
			Proposal__c proposal = proposals.get(quote.ProposalId__c);
			for (String fieldApiName : PROPOSAL_SYNC_FIELDS) {
				Decimal oldValue = SystemUtility.nullToZero((Decimal) proposal.get(fieldApiName));
				Decimal deltaValue = SystemUtility.delta(
					(Decimal) oldQuote.get(fieldApiName),
					(Decimal) quote.get(fieldApiName)
				);
				proposal.put(fieldApiName, oldValue + deltaValue);
			}
		}
	}

	public static void fullSyncQuotesToProposal(
		List<Quote__c> quotesToSync,
		Map<Id, Proposal__c> proposals
	) {
		for (Quote__c quote : quotesToSync) {
			Proposal__c proposal = proposals.get(quote.ProposalId__c);
			for (String fieldApiName : PROPOSAL_SYNC_FIELDS) {
				Decimal proposalValue = SystemUtility.nullToZero((Decimal) proposal.get(fieldApiName));
				Decimal syncValue = SystemUtility.nullToZero((Decimal) quote.get(fieldApiName));
				proposal.put(fieldApiName, proposalValue + syncValue);
			}
		}
	}

	public static void rollbackQuoteTotalsFromProposal(
		List<Quote__c> oldQuotes,
		Map<Id, Proposal__c> proposals
	) {
		for (Quote__c quote : oldQuotes) {
			if (quote.ProposalId__c != null) {
				Proposal__c proposal = proposals.get(quote.ProposalId__c);
				for (String fieldApiName : PROPOSAL_SYNC_FIELDS) {
					Decimal proposalValue = SystemUtility.nullToZero((Decimal) proposal.get(fieldApiName));
					Decimal syncValue = SystemUtility.nullToZero((Decimal) quote.get(fieldApiName));
					proposal.put(fieldApiName, proposalValue - syncValue);
				}
			}
		}
	}
}
