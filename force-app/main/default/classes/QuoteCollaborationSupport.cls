/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteCollaborationSupport {
	public static final String EMAIL_COLLABORATION_REVIEW = 'CollaborationReview';
	public static final String EMAIL_COLLABORATION_INVITE = 'CollaborationInvite';

	public static List<User> getUsers() {
		return UserSupport.getActiveExcludingLoggedInUser();
	}

	/**
	 * retrieve the quote sections which are available for collaboartion
	 * @param quoteId Id of the quote
	 * @return List<QuoteSection__c>
	 */
	public static List<QuoteSection__c> getAvailableQuoteSections(Id quoteId) {
		return [
			SELECT Id, Name, QuoteId__c
			FROM QuoteSection__c
			WHERE
				QuoteId__c = :quoteId
				AND Id NOT IN (
					SELECT SectionId__c
					FROM CollaborationRequest__c
					WHERE
						QuoteId__c = :quoteId
						AND (Status__c = :CollaborationRequest.STATUS_ACCEPTED
						OR Status__c = :CollaborationRequest.STATUS_ASSIGNED)
				)
			WITH SECURITY_ENFORCED
			ORDER BY DisplaySequence__c, SectionSequence__c
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];
	}

	public static void sendEmailToCollaborator(Id userId, Id quoteId) {
		EmailTemplate templateSO = SystemUtility.getEmailTemplateFor(EMAIL_COLLABORATION_INVITE);

		User userSO = UserSupport.getUserInformation(userId);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] sendTo = new List<String>{ userSO.Email };
		mail.setToAddresses(sendTo);
		mail.setSubject(templateSO.Subject);

		String componentNSPrefix = !String.isBlank(SystemUtility.getNamespacePrefix())
			? SystemUtility.getNamespacePrefix()
			: 'c__';

		String url = String.format(
			'https://{0}/lightning/cmp/{3}checkoutQuoteSection?c__userId={1}&c__quoteId={2}',
			new List<String>{
				System.URL.getSalesforceBaseUrl().getHost(),
				userId,
				quoteId,
				componentNSPrefix
			}
		);

		mail.setHtmlBody(String.format(templateSO.HtmlValue, new List<String>{ userSO.Name, url }));

		mail.setReplyTo(UserInfo.getUserEmail());
		mail.setSenderDisplayName(UserInfo.getName());
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}

	/**
	 * Sends a ready-for-review email to the quote owner of the given
	 * collaboration quote.
	 * @param quoteId A collaboration quote ID
	 */
	public static void sendEmailToQuoteOwner(Id quoteId) {
		Quote__c sourceQuote = [
			SELECT DerivedFromId__c, DerivedFromId__r.OwnerId
			FROM Quote__c
			WHERE Id = :quoteId
			WITH SECURITY_ENFORCED
		];

		EmailTemplate templateSO = SystemUtility.getEmailTemplateFor(EMAIL_COLLABORATION_REVIEW);

		User ownerUserSO = UserSupport.getUserInformation(sourceQuote.DerivedFromId__r.OwnerId);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] sendTo = new List<String>{ ownerUserSO.Email };
		mail.setToAddresses(sendTo);
		mail.setSubject(templateSO.Subject);

		String url = String.format(
			'https://{0}/lightning/r/Quote__c/{1}/view',
			new List<String>{ System.URL.getSalesforceBaseUrl().getHost(), sourceQuote.DerivedFromId__c }
		);

		mail.setHtmlBody(
			String.format(templateSO.HtmlValue, new List<String>{ ownerUserSO.Name, url })
		);
		mail.setReplyTo(UserInfo.getUserEmail());
		mail.setSenderDisplayName(UserInfo.getName());
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
	}

	public static void revokeSections(Id quoteId, List<Id> sectionIds) {
		List<Id> sectionLineageIds = new List<Id>();
		for (QuoteSection__c section : QuoteSectionService.getSectionLineageFor(sectionIds)) {
			sectionLineageIds.add(section.Id);
		}

		List<CollaborationRequest__c> acceptedRequests = CollaborationRequestService.getRevocableRequestsFor(
			quoteId,
			sectionLineageIds
		);
		for (CollaborationRequest__c request : acceptedRequests) {
			request.Status__c = CollaborationRequest.STATUS_REVOKED;
		}

		CRUDUtility.updateRecords(acceptedRequests);
	}

	public static Quote__c getExistingCollaborationQuoteFor(Id userId, Id sourceQuoteId) {
		String childRequestName = SystemUtility.getInverseRName(
			Schema.Quote__c.SObjectType,
			Schema.CollaborationRequest__c.SObjectType
		);
		QueryRequest innerQuery = new QueryRequest(childRequestName);
		innerQuery.requestedFields = new Set<String>{ 'Id' };
		innerQuery.setFilterBy(
			new Map<String, String>{
				Schema.CollaborationRequest__c.Status__c + '' => CollaborationRequest.STATUS_ACCEPTED
			}
		);

		SObjectType objType = Quote__c.SObjectType;
		QueryRequest queryRequest = new QueryRequest(objType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(objType);
		queryRequest.setFilterBy(
			new Map<String, String>{
				Schema.Quote__c.DerivedFromId__c + '' => sourceQuoteId,
				SObjectUtility.FIELD_OWNER_ID => userId
			}
		);
		queryRequest.innerQueries = new List<QueryRequest>{ innerQuery };
		List<Quote__c> sourceQuotes = (List<Quote__c>) SOQLUtility.querySObject(queryRequest);

		for (Quote__c quote : sourceQuotes) {
			if (quote.CollaborationRequests__r.size() > 0) {
				return quote;
			}
		}

		return null;
	}
}
