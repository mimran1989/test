/**
 *  Provus Services Quoting
 *  RateCardServiceTest
 *  @2021 Provus Inc. All rights reserved.
 */
@isTest
private class RateCardServiceTest extends TestBase {
	@testSetup
	static void setup() {
		RateCardAttributeGroup__c rateCardAttributeGroup = newRateCardAttributeGroup();
		newRateCardAttribute(rateCardAttributeGroup.Id); // create attribute and related it to attribute group
		RateCard__c rateCard = newRateCard();
		rateCard.AttributeGroupId__c = rateCardAttributeGroup.Id;
		update rateCard;
	}

	@IsTest
	static void itShouldGetRateCard() {
		Test.startTest();
		RateCard__c rateCardSO = [
			SELECT Id
			FROM RateCard__c
			WHERE Name = 'Skill & Resource Location'
			LIMIT 1
		];
		RateCardService rateCardService = new RateCardService(rateCardSO.Id);
		System.assertNotEquals(rateCardService, null, 'should not be null');
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetRateCardAttributes() {
		Test.startTest();
		RateCard__c rateCardSO = [
			SELECT Id
			FROM RateCard__c
			WHERE Name = 'Skill & Resource Location'
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
		RateCardService rateCardService = new RateCardService(rateCardSO.Id);
		Set<String> attributes = rateCardService.getAttributes();
		System.assert(
			attributes.contains(Schema.RateCardItem__c.SkillLevel__c + ''),
			'should contain skill level as an attribute'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldGetRateCardWithSequence() {
		Test.startTest();
		RateCard__c rateCardSO = [
			SELECT Id
			FROM RateCard__c
			WHERE Name = 'Skill & Resource Location'
			LIMIT 1
		];
		RateCardService rateCardService = new RateCardService(rateCardSO.Id);
		Map<String, Decimal> attributesWithSequence = rateCardService.getAttributesWithSequence();
		System.assertEquals(
			attributesWithSequence.get(Schema.RateCardItem__c.SkillLevel__c + ''),
			1,
			'should be the first attribute'
		);
		Test.stopTest();
	}

	@IsTest
	static void itShouldcheckIfRateCardIsExpired() {
		Test.startTest();
		RateCard__c rateCardSO = [
			SELECT Id
			FROM RateCard__c
			WHERE Name = 'Skill & Resource Location'
			LIMIT 1
		];

		Quote__c quoteSO = newQuote();
		quoteSO.RateCardId__c = rateCardSO.Id;
		Map<Boolean, String> rateCardStatusMap = RateCardService.checkIfRateCardIsExpired(quoteSO.Id);
		System.assertEquals(rateCardStatusMap.size(), 1, 'size should be one');
		Test.stopTest();
	}
}
