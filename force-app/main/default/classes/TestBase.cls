/**
 *  Provus Services Quoting
 *  TestBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class TestBase {
	static final String NS_PREFIX = SystemUtility.getNamespacePrefix();

	public static String nsPrefix() {
		return NS_PREFIX;
	}

	public static User newUser() {
		Profile profileSO = [SELECT Id FROM Profile WITH SECURITY_ENFORCED LIMIT 1];

		User newUser = new User(
			Username = 'testbase@provus.com',
			LastName = 'TestBase',
			Email = 'testbase@provus.com',
			Alias = 'testbase',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			ProfileId = profileSO.Id,
			LanguageLocaleKey = 'en_US'
		);

		CRUDUtility.insertRecords(newUser);
		return newUser;
	}

	public static Quote__c newQuote() {
		return newQuote(null);
	}

	public static Quote__c newQuote(String quoteName) {
		Quote__c newQuote = new Quote__c(Name = quoteName, ServiceStartDate__c = Date.today());
		CRUDUtility.insertRecords(newQuote);
		return newQuote;
	}

	public static QuotePeriod__c newQuotePeriod(Id quoteId) {
		QuotePeriod__c newQuotePeriod = new QuotePeriod__c();
		newQuotePeriod.QuoteId__c = quoteId;
		CRUDUtility.insertRecords(newQuotePeriod);
		return newQuotePeriod;
	}

	public static Proposal__c newProposal() {
		Proposal__c proposalSO = new Proposal__c(Name = 'Test Proposal');
		CRUDUtility.insertRecords(proposalSO);
		return proposalSO;
	}

	public static Opportunity newOpportunity() {
		Opportunity opp = new Opportunity(
			Name = 'Test',
			StageName = 'Test',
			CloseDate = Date.valueOf('2021-12-31')
		);
		CRUDUtility.insertRecords(opp);
		return opp;
	}

	public static Pricebook2 newPricebook() {
		Pricebook2 newPricebook = new Pricebook2(IsActive = true, Name = 'Pricebook');
		CRUDUtility.insertRecords(newPricebook);
		return newPricebook;
	}

	public static PricebookEntry newPricebookEntry(Id pricebookId, Id productId) {
		PricebookEntry newPricebookEntry = new PricebookEntry(
			IsActive = true,
			UnitPrice = 1000,
			Pricebook2Id = pricebookId,
			Product2Id = productId
		);
		return newPricebookEntry;
	}

	public static RateCard__c newRateCard() {
		RateCard__c rateCard = new RateCard__c(
			Name = 'Skill & Resource Location',
			IsActive__c = true,
			ExpirationDate__c = Date.today() + 1,
			EffectiveDate__c = Date.today() - 1
		);
		CRUDUtility.insertRecords(rateCard);
		return rateCard;
	}

	public static RateCardAttributeGroup__c newRateCardAttributeGroup() {
		RateCardAttributeGroup__c rateCardAttributeGroup = new RateCardAttributeGroup__c(
			Name = 'Skill & Resource Location'
		);
		CRUDUtility.insertRecords(rateCardAttributeGroup);
		return rateCardAttributeGroup;
	}

	public static RateCardAttribute__c newRateCardAttribute(Id rateCardAttributeGroupId) {
		RateCardAttribute__c rateCardAttribute = new RateCardAttribute__c(
			AttributeGroupId__c = rateCardAttributeGroupId,
			Sequence__c = 1,
			Name = 'Skill',
			FieldAPIName__c = Schema.RateCardItem__c.SkillLevel__c + ''
		);
		CRUDUtility.insertRecords(rateCardAttribute);
		return rateCardAttribute;
	}

	public static RateCardItem__c newRateCardItem(Id rateCardId, Id productId) {
		RateCardItem__c rateCardItem = new RateCardItem__c(
			IsActive__c = true,
			RateCardId__c = rateCardId,
			ProductId__c = productId
		);
		CRUDUtility.insertRecords(rateCardItem);
		return rateCardItem;
	}

	public static Product2 newProduct(String productName, String recordTypeId) {
		Product2 product = new Product2();
		product.IsActive = true;
		product.Name = productName;
		product.RecordTypeId = recordTypeId;
		return product;
	}

	public static CollaborationRequest__c newCollaborationRequest() {
		CollaborationRequest__c requestSO = new CollaborationRequest__c();
		CRUDUtility.insertRecords(requestSO);
		return requestSO;
	}

	public static QuoteSection__c newQuoteSection(Id quoteId) {
		QuoteSection__c sectionSO = new QuoteSection__c();
		sectionSO.QuoteId__c = quoteId;
		CRUDUtility.insertRecords(sectionSO);
		return sectionSO;
	}

	public static Estimate__c newEstimate() {
		Estimate__c newEstimate = new Estimate__c();
		return newEstimate;
	}

	public static OpportunityLineItem newOpportunityLineItem(
		Id opportunityId,
		Id productId,
		Id pricebookEntryId
	) {
		OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem();
		newOpportunityLineItem.OpportunityId = opportunityId;
		newOpportunityLineItem.Product2Id = productId;
		newOpportunityLineItem.PricebookEntryId = pricebookEntryId;
		newOpportunityLineItem.Quantity = 1;
		newOpportunityLineItem.UnitPrice = 1000;
		return newOpportunityLineItem;
	}

	public static CollaborationRequest__c newCollaborationRequest(Id sectionId, String status) {
		CollaborationRequest__c request = new CollaborationRequest__c(
			SectionId__c = sectionId,
			Status__c = status
		);
		CRUDUtility.insertRecords(request);
		return request;
	}
}
