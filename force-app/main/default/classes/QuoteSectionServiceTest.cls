/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
@IsTest
private class QuoteSectionServiceTest extends TestBase {
	@IsTest
	static void shouldNestSubsections() {
		Quote__c quoteSO = newQuote();
		QuoteSection__c rootSection = newQuoteSection(quoteSO.Id);
		QuoteSection__c nestedSection = newQuoteSection(quoteSO.Id);
		nestedSection.ParentQuoteSectionId__c = rootSection.Id;
		update nestedSection;

		Test.startTest();
		List<QuoteSectionDO> sections = QuoteSectionService.getQuoteSectionsForQuote(quoteSO.Id);
		System.assert(sections[0].childSections.size() > 0, 'should have a child section');
		Test.stopTest();
	}
}
