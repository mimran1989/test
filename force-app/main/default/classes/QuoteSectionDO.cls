/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */

public with sharing class QuoteSectionDO implements Comparable {
	public Id id;
	public String name;
	public Id quoteId;
	public Decimal sequence;
	public Decimal sectionSequence;
	public Decimal displaySequence;
	public Integer startRow;
	public String description;
	public String operationType;

	public Id parentSectionId;
	public String parentSectionName;
	public List<QuoteSectionDO> childSections = new List<QuoteSectionDO>();

	public List<Id> quoteItemIdList;

	public QuoteSectionDO(QuoteSection__c sectionSO) {
		this.id = sectionSO.Id;
		this.name = sectionSO.Name;
		this.quoteId = sectionSO.QuoteId__c;
		this.sequence = sectionSO.Sequence__c;
		this.displaySequence = sectionSO.DisplaySequence__c;
		this.sectionSequence = sectionSO.SectionSequence__c;
		this.description = sectionSO.Description__c;

		this.parentSectionId = sectionSO.ParentQuoteSectionId__c;
		this.parentSectionName = sectionSO.ParentQuoteSectionId__r.Name;

		List<Id> qteLineIdList = new List<Id>();
		for (QuoteItem__c qteItem : sectionSO.QuoteItems__r) {
			qteLineIdList.add(qteItem.Id);
		}
		if (qteLineIdList.size() > 0) {
			this.quoteItemIdList = qteLineIdList;
			this.startRow = sectionSO.QuoteItems__r[0].SectionSequence__c.intValue();
		}
	}

	public Integer compareTo(Object compareTo) {
		QuoteSectionDO compareToSection = (QuoteSectionDO) compareTo;
		if (this.sequence == compareToSection.sequence) {
			return 0;
		}

		if (this.sequence > compareToSection.sequence) {
			return 1;
		}

		return -1;
	}
}
