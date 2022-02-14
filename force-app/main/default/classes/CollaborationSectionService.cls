/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
public with sharing class CollaborationSectionService {
	/**
	 * Gets the merge ready section lineage of the given target section IDs.
	 * @param targetSectionIds A list of target section IDs
	 *
	 * @return The lineage sections of the target section IDs
	 */
	public static List<QuoteSection__c> getMergeReadyLineage(List<Id> targetSectionIds) {
		Map<Id, QuoteSection__c> lineageSections = new Map<Id, QuoteSection__c>(
			QuoteSectionService.getSectionLineageFor(targetSectionIds)
		);

		List<CollaborationRequest__c> requests = [
			SELECT SectionId__c
			FROM CollaborationRequest__c
			WHERE
				SectionId__c IN :lineageSections.keySet()
				AND Status__c = :CollaborationRequest.STATUS_READY_TO_MERGE
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];

		List<Id> mergeReadySections = new List<Id>();
		for (CollaborationRequest__c request : requests) {
			mergeReadySections.add(request.SectionId__c);
		}

		return [
			SELECT Id, QuoteId__c, DerivedFromId__c
			FROM QuoteSection__c
			WHERE Id IN :mergeReadySections
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];
	}
}
