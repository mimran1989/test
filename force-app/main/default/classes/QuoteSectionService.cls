/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class QuoteSectionService {
	// constants
	public static final String SOBJECT_NAME = 'QuoteSection__c';

	public static final String RELATED_QUOTE_ID = 'QuoteId__c';

	public static final String OPERATION_TYPE_INSERT = 'insert';
	public static final String OPERATION_TYPE_UPDATE = 'update';
	public static final String OPERATION_TYPE_DELETE = 'delete';

	/**
	 * Gets all quote sections for quote
	 * @param   quoteId Id of the quote
	 * @return  List<QuoteSectionDO>
	 */
	public static List<QuoteSectionDO> getQuoteSectionsForQuote(Id quoteId) {
		List<QuoteSectionDO> sectionDOs = new List<QuoteSectionDO>();

		for (QuoteSection__c sectionSO : [
			SELECT
				Id,
				Name,
				Description__c,
				ParentQuoteSectionId__c,
				ParentQuoteSectionId__r.Name,
				QuoteId__c,
				DisplaySequence__c,
				SectionSequence__c,
				Sequence__c,
				(
					SELECT Id, Sequence__c, SectionSequence__c, QuoteId__c
					FROM QuoteItems__r
					WHERE QuoteId__c = :quoteId
					ORDER BY SectionSequence__c ASC NULLS LAST
				)
			FROM QuoteSection__c
			WHERE QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
			ORDER BY ParentQuoteSectionId__c NULLS FIRST, DisplaySequence__c ASC NULLS LAST
		]) {
			QuoteSectionDO sectionDO = new QuoteSectionDO(sectionSO);
			sectionDOs.add(sectionDO);
		}

		return reduceParent(sectionDOs);
	}

	private static List<QuoteSectionDO> reduceParent(List<QuoteSectionDO> sectionDOS) {
		List<QuoteSectionDO> rootSections = new List<QuoteSectionDO>();
		Map<Id, QuoteSectionDO> sectionDOById = new Map<Id, QuoteSectionDO>();
		for (QuoteSectionDO sectionDO : sectionDOS) {
			if (sectionDO.parentSectionId == null) {
				rootSections.add(sectionDO);
			}

			sectionDOById.put(sectionDO.id, sectionDO);
		}

		for (QuoteSectionDO sectionDO : sectionDOS) {
			if (sectionDO.parentSectionId != null) {
				sectionDOById.get(sectionDO.parentSectionId).childSections.add(sectionDO);
			}
		}

		return rootSections;
	}

	/**
	 * commit Quote Sections for the Quote
	 * @param   quoteId Id of the quote
	 * @param   quoteSectionColData String containing quote section data
	 * @return  Boolean success Status
	 */
	public static Boolean commitQuoteSections(Id quoteId, String quoteSectionColData) {
		List<QuoteSectionDO> sectionDOs = (List<QuoteSectionDO>) JSON.deserialize(
			quoteSectionColData,
			List<QuoteSectionDO>.class
		);

		Map<Decimal, QuoteSection__c> sectionsBySequenceNumber = new Map<Decimal, QuoteSection__c>();
		List<QuoteSection__c> sectionsToDelete = new List<QuoteSection__c>();

		for (QuoteSectionDO sectionDO : sectionDOs) {
			QuoteSection__c quoteSection = new QuoteSection__c(
				Id = sectionDO.id,
				QuoteId__c = sectionDO.quoteId,
				ParentQuoteSectionId__c = sectionDO.parentSectionId
			);
			sectionsBySequenceNumber.put(sectionDO.sequence, quoteSection);

			if (sectionDO.operationType == OPERATION_TYPE_DELETE) {
				sectionsToDelete.add(quoteSection);
			} else {
				quoteSection.Name = sectionDO.name;
				quoteSection.Sequence__c = sectionDO.sequence;
				quoteSection.DisplaySequence__c = sectionDO.displaySequence;
				quoteSection.Description__c = sectionDO.description;
				quoteSection.SectionSequence__c = sectionDO.sectionSequence;
			}
		}

		CRUDUtility.upsertRecords(sectionsBySequenceNumber.values());
		CRUDUtility.deleteRecords(sectionsToDelete);

		Boolean isSuccess = true;
		return isSuccess;
	}

	/**
	 * Gets the sections for the given IDs as well as any sections that are derived
	 * from them.
	 * @param targetSectionIds A list of section IDs
	 *
	 * @return A list of sections from the same lineage
	 */
	public static List<QuoteSection__c> getSectionLineageFor(List<Id> targetSectionIds) {
		return [
			SELECT Id, QuoteId__c, DerivedFromId__c
			FROM QuoteSection__c
			WHERE Id IN :targetSectionIds OR DerivedFromId__c IN :targetSectionIds
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];
	}
}
