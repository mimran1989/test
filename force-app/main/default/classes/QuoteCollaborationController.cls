/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteCollaborationController {
	public final static String ACCESSLEVEL_EDIT = 'Edit';
	public final static String STATUS_ASSIGNED = 'Assigned';
	public final static String STATUS_ACCEPTED = 'Accepted';

	@AuraEnabled(cacheable=true)
	public static List<User> getUsers() {
		return QuoteCollaborationSupport.getUsers();
	}

	@AuraEnabled
	public static String getAvailableQuoteSections(Id quoteId) {
		return JSON.serialize(QuoteCollaborationSupport.getAvailableQuoteSections(quoteId));
	}

	@AuraEnabled
	public static String getCollaborationRequestsForQuote(Id quoteId) {
		return JSON.serialize(CollaborationRequestService.getOutstandingRequestsFor(quoteId));
	}

	@AuraEnabled
	public static Boolean submitInvitationForCollaboration(
		Id userId,
		Id quoteId,
		List<Id> quoteSectionIds
	) {
		QuoteViewSetting__c quoteViewSettingSO = createQuoteViewSetting(userId, quoteId);
		List<CollaborationRequest__c> listCollaborationRequests = createCollaborationRequests(
			quoteId,
			userId,
			quoteSectionIds
		);
		createSharingRecordForQuoteViewSetting(quoteViewSettingSO.Id, userId);
		createSharingRecordsForCollaborationRequest(
			new List<Id>(new Map<Id, CollaborationRequest__c>(listCollaborationRequests).keySet()),
			userId
		);
		QuoteCollaborationSupport.sendEmailToCollaborator(userId, quoteId);
		return true;
	}

	public static QuoteViewSetting__c createQuoteViewSetting(Id userId, Id quoteId) {
		QuoteViewSetting__c quoteViewSettingSO = new QuoteViewSetting__c();
		quoteViewSettingSO.OwnerId = UserInfo.getUserId();
		quoteViewSettingSO.QuoteId__c = quoteId;
		quoteViewSettingSO.CollaboratorUserId__c = userId;

		return (QuoteViewSetting__c) CRUDUtility.insertRecords(quoteViewSettingSO);
	}

	public static List<CollaborationRequest__c> createCollaborationRequests(
		Id quoteId,
		Id userId,
		List<Id> quoteSectionIds
	) {
		List<CollaborationRequest__c> listCollaborationRequests = new List<CollaborationRequest__c>();
		for (Id quoteSectionId : quoteSectionIds) {
			CollaborationRequest__c collaborationRequestSO = new CollaborationRequest__c(
				OwnerId = UserInfo.getUserId(),
				QuoteId__c = quoteId,
				SectionId__c = quoteSectionId,
				CollaboratorUserId__c = userId,
				Status__c = STATUS_ASSIGNED
			);
			listCollaborationRequests.add(collaborationRequestSO);
		}

		return (List<CollaborationRequest__c>) CRUDUtility.insertRecords(listCollaborationRequests);
	}

	public static void createSharingRecordForQuoteViewSetting(Id quoteViewSettingId, Id userId) {
		QuoteViewSetting__Share quoteViewSettingShare = new QuoteViewSetting__Share();
		quoteViewSettingShare.UserOrGroupId = userId;
		quoteViewSettingShare.ParentId = quoteViewSettingId;
		quoteViewSettingShare.AccessLevel = ACCESSLEVEL_EDIT;

		CRUDUtility.insertRecords(quoteViewSettingShare);
	}

	public static void createSharingRecordsForCollaborationRequest(
		List<Id> sectionViewSettingIds,
		Id userId
	) {
		List<CollaborationRequest__Share> listCollaborationRequestsShare = new List<CollaborationRequest__Share>();
		for (Id quoteViewSettingId : sectionViewSettingIds) {
			CollaborationRequest__Share collaborationRequestShare = new CollaborationRequest__Share(
				UserOrGroupId = userId,
				ParentId = quoteViewSettingId,
				AccessLevel = ACCESSLEVEL_EDIT
			);
			listCollaborationRequestsShare.add(collaborationRequestShare);
		}

		CRUDUtility.insertRecords(listCollaborationRequestsShare);
	}

	@AuraEnabled
	public static String createCollaborationQuote(Id userId, Id sourceQuoteId) {
		Quote__c clonedQuoteSO = QuoteCollaborationSupport.getExistingCollaborationQuoteFor(
			userId,
			sourceQuoteId
		);

		if (clonedQuoteSO == null) {
			clonedQuoteSO = cloneQuote(userId, sourceQuoteId);
			CRUDUtility.insertRecords(clonedQuoteSO);
		}

		List<CollaborationRequest__c> sourceQuoteCollaborationRequests = new List<CollaborationRequest__c>();
		List<CollaborationRequest__c> clonedCollaborationRequests = new List<CollaborationRequest__c>();
		Set<Id> sourceQuoteSectionIds = new Set<Id>();

		for (
			CollaborationRequest__c collaborationRequestSO : CollaborationRequestService.getAssignedRequestsFor(
				sourceQuoteId
			)
		) {
			collaborationRequestSO.Status__c = CollaborationRequest.STATUS_ACCEPTED;
			sourceQuoteCollaborationRequests.add(collaborationRequestSO);
			sourceQuoteSectionIds.add(collaborationRequestSO.SectionId__c);
		}

		CRUDUtility.updateRecords(sourceQuoteCollaborationRequests);

		QuoteService.copyQuoteChildEntities(sourceQuoteId, clonedQuoteSO.Id, sourceQuoteSectionIds);

		Map<String, Id> clonedCollaborationRequestToSectionId = new Map<String, Id>();
		for (QuoteSection__c clonedQuoteSectionSO : [
			SELECT Id, Name, QuoteId__c
			FROM QuoteSection__c
			WHERE QuoteId__c = :clonedQuoteSO.Id
			WITH SECURITY_ENFORCED
		]) {
			clonedCollaborationRequestToSectionId.put(clonedQuoteSectionSO.Name, clonedQuoteSectionSO.Id);
		}

		for (CollaborationRequest__c collaborationRequestSO : sourceQuoteCollaborationRequests) {
			CollaborationRequest__c clonedCollaborationRequestSO = new CollaborationRequest__c(
				Status__c = CollaborationRequest.STATUS_ACCEPTED,
				QuoteId__c = clonedQuoteSO.Id,
				CollaboratorUserId__c = collaborationRequestSO.CollaboratorUserId__c,
				SectionId__c = clonedCollaborationRequestToSectionId.get(
						collaborationRequestSO.SectionId__r.Name
					) != null
					? clonedCollaborationRequestToSectionId.get(collaborationRequestSO.SectionId__r.Name)
					: null
			);
			clonedCollaborationRequests.add(clonedCollaborationRequestSO);
		}

		CRUDUtility.insertRecords(clonedCollaborationRequests);

		return String.valueOf(clonedQuoteSO.Id);
	}

	public static Quote__c cloneQuote(Id userId, Id sourceQuoteId) {
		SObjectType objType = Quote__c.SObjectType;
		QueryRequest queryRequest = new QueryRequest(objType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(objType);
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => sourceQuoteId });
		List<Quote__c> sourceQuotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);

		Quote__c clonedQuote;
		if (sourceQuotes.size() > 0) {
			Quote__c sourceQuote = sourceQuotes[0];
			clonedQuote = sourceQuote.clone(false, true);
			clonedQuote.OwnerId = userId;
			clonedQuote.Name = QuoteService.RECORDTYPE_NAME_COLLABORATION + ': ' + sourceQuote.Name;
			clonedQuote.DerivedFromId__c = sourceQuote.Id;
			clonedQuote.Type__c = QuoteService.RECORDTYPE_NAME_COLLABORATION;
		}

		return clonedQuote;
	}

	/**
	 * Commits the changes by marking the sections for merge and sending an email to the quote owner
	 * to review.
	 * @param quoteId A collaboration quote ID
	 * @param sectionIds A list of quote section IDs to mark
	 */
	@AuraEnabled
	public static void commitChanges(Id quoteId, List<Id> sectionIds) {
		CollaborationRequestService.markForMerge(sectionIds);
		QuoteCollaborationSupport.sendEmailToQuoteOwner(quoteId);
	}

	/**
	 * Merges the quote items from the given section IDs into their main quotes.
	 * @param quoteId A main quote ID
	 * @param sectionIds A list of section IDs to merge
	 * @return A JSON representation of the quote items
	 */
	@AuraEnabled
	public static String mergeSections(Id quoteId, List<Id> sectionIds) {
		CollaborationMergeService.mergeSections(quoteId, sectionIds);
		return JSON.serialize(QuoteConfiguratorSupport.getQuoteItemsForQuote(quoteId));
	}

	@AuraEnabled
	public static void revokeSections(Id quoteId, List<Id> sectionIds) {
		QuoteCollaborationSupport.revokeSections(quoteId, sectionIds);
	}
}
