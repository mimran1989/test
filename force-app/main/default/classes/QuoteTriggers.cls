/**
 *  Provus Services Quoting
 *  QuoteTriggers
 *  @2021 Provus Inc. All rights reserved.
 *
 */
public with sharing class QuoteTriggers extends TriggerHandler {
	public static void processTrigger(
		Map<Id, Quote__c> oldMap,
		List<Quote__c> newObjs,
		Boolean isBefore
	) {
		final QuoteTriggers myTrigger = new QuoteTriggers(oldMap, newObjs, isBefore);
		if (isBefore) {
			// prevent manual changes to object fields
			myTrigger.preventCurrencyChange();
			myTrigger.preventChangeOfLastProposalSync();

			myTrigger.assignCurrencyConversionRatio();
			myTrigger.rollbackQuoteTotalsFromProposal();
			myTrigger.syncTotalsToProposal();
			myTrigger.overrideRateCardFromAssociatedAccount();
		} else {
			myTrigger.createPeriodsAndPeriodGroups();
			myTrigger.cloneTemplatesIntoQuotes();
		}
	}

	public QuoteTriggers(Map<Id, Quote__c> oldMap, List<Quote__c> newObjs, Boolean isBefore) {
		super(oldMap, newObjs, isBefore);
	}

	public void preventCurrencyChange() {
		if (MultiCurrencyService.isMultiCurrencyEnabled() && isUpdate) {
			MultiCurrencyService.preventCurrencyChange(newObjs, (Map<Id, Quote__c>) oldMap);
		}
	}

	public void preventChangeOfLastProposalSync() {
		if (isUpdate) {
			for (Quote__c quote : (List<Quote__c>) newObjs) {
				Quote__c oldQuote = (Quote__c) oldMap.get(quote.Id);
				if (
					oldQuote.LastProposalSync__c != null &&
					isChanged(quote.Id, Schema.Quote__c.LastProposalSync__c)
				) {
					quote.LastProposalSync__c.addError(Label.SystemFieldChangeDisallowed);
				}
			}
		}
	}

	public void assignCurrencyConversionRatio() {
		if (MultiCurrencyService.isMultiCurrencyEnabled() && isInsert) {
			MultiCurrencyService.assignCurrencyConversionRatio(newObjs);
		}
	}

	public void createPeriodsAndPeriodGroups() {
		if (isInsert) {
			QuotePeriodService.createPeriodsAndPeriodGroupsFor(newObjs);
		}
	}

	public void cloneTemplatesIntoQuotes() {
		if (isInsert) {
			QuoteService.applyQuoteTemplateAfter(newObjs);
		}
	}

	private Boolean isProposalRollback(Quote__c ctxQuote) {
		Id quoteId = ctxQuote.Id;
		Boolean isProposalChanged = isChanged(quoteId, Schema.Quote__c.ProposalId__c);
		Quote__c oldQuote = ((Quote__c) oldMap?.get(quoteId));
		return isProposalChanged && oldQuote?.ProposalId__c != null;
	}

	private Boolean isProposalPartialSync(Quote__c ctxQuote) {
		Id quoteId = ctxQuote.Id;
		Boolean isProposalChanged = isChanged(quoteId, Schema.Quote__c.ProposalId__c);
		return ctxQuote.ProposalId__c != null &&
			!isProposalChanged &&
			anyProposalSyncFieldChanged(quoteId);
	}

	private Boolean isProposalFullSync(Quote__c ctxQuote) {
		Quote__c oldQuote = ((Quote__c) oldMap?.get(ctxQuote.Id));
		DateTime oldSyncTime = oldQuote?.LastProposalSync__c;
		Boolean isNeverSynced = isUpdate && oldSyncTime == null;
		Boolean isProposalChanged = isChanged(ctxQuote.Id, Schema.Quote__c.ProposalId__c);
		return ctxQuote.ProposalId__c != null && (isInsert || isProposalChanged || isNeverSynced);
	}

	public void syncTotalsToProposal() {
		if (isDelete) {
			return;
		}

		Set<Id> proposalIdsForSync = new Set<Id>();
		List<Quote__c> quotesToFullSync = new List<Quote__c>();
		List<Quote__c> quotesToDeltaSync = new List<Quote__c>();
		List<Quote__c> quotesToRolback = new List<Quote__c>();

		Datetime syncTime = Datetime.now();
		for (Quote__c quote : (List<Quote__c>) newObjs) {
			Id quoteId = quote.Id;

			Boolean isFullSync = isProposalFullSync(quote);
			Boolean isPartialSync = isProposalPartialSync(quote);
			Boolean isRollback = isProposalRollback(quote);

			if (isFullSync) {
				quote.LastProposalSync__c = syncTime;
				quotesToFullSync.add(quote);
				proposalIdsForSync.add(quote.ProposalId__c);
			} else if (isPartialSync) {
				quote.LastProposalSync__c = syncTime;
				quotesToDeltaSync.add(quote);
				proposalIdsForSync.add(quote.ProposalId__c);
			}

			if (isRollback) {
				Quote__c oldQuote = (Quote__c) oldMap.get(quoteId);
				// if we remove the proposal, we clear out the last sync time
				quote.LastProposalSync__c = quote.ProposalId__c == null ? null : quote.LastProposalSync__c;
				quotesToRolback.add(oldQuote);
			}
		}

		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Proposal__c.getName());
		queryRequest.requestedFields = new Set<String>(QuoteSyncService.PROPOSAL_SYNC_FIELDS);
		Map<Id, Proposal__c> proposalsToSyncTo = new Map<Id, Proposal__c>(
			(List<Proposal__c>) SOQLUtility.querySObject(queryRequest)
		);
		QuoteSyncService.deltaSyncQuotesToProposal(
			quotesToDeltaSync,
			(Map<Id, Quote__c>) oldMap,
			proposalsToSyncTo
		);
		QuoteSyncService.fullSyncQuotesToProposal(quotesToFullSync, proposalsToSyncTo);
		QuoteSyncService.rollbackQuoteTotalsFromProposal(quotesToRolback, proposalsToSyncTo);

		CRUDUtility.updateRecords(proposalsToSyncTo.values());
	}

	private Boolean anyProposalSyncFieldChanged(Id quoteId) {
		Boolean anySyncFieldChanged = false;
		for (String syncField : QuoteSyncService.PROPOSAL_SYNC_FIELDS) {
			if (isChanged(quoteId, syncField)) {
				anySyncFieldChanged = true;
				break;
			}
		}
		return anySyncFieldChanged;
	}

	public void rollbackQuoteTotalsFromProposal() {
		if (!isDelete) {
			return;
		}

		Set<Id> proposalIds = new Set<Id>();
		List<Quote__c> quotesToRollback = new List<Quote__c>();

		for (Quote__c oldQuote : (List<Quote__c>) oldMap.values()) {
			Id proposalId = oldQuote.ProposalId__c;
			if (proposalId != null) {
				proposalIds.add(proposalId);
				quotesToRollback.add(oldQuote);
			}
		}

		QueryRequest queryRequest = new QueryRequest(Schema.SObjectType.Proposal__c.getName());
		queryRequest.requestedFields = new Set<String>(QuoteSyncService.PROPOSAL_SYNC_FIELDS);
		Map<Id, Proposal__c> proposals = new Map<Id, Proposal__c>(
			(List<Proposal__c>) SOQLUtility.querySObject(queryRequest)
		);

		QuoteSyncService.rollbackQuoteTotalsFromProposal(quotesToRollback, proposals);
		CRUDUtility.updateRecords(proposals.values());
	}

	public void overrideRateCardFromAssociatedAccount() {
		if (isInsert || isUpdate) {
			RateCardService.overrideRateCardFromAssociatedAccount((List<quote__c>) newObjs);
		}
	}
}
