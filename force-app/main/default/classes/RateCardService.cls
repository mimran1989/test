/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class RateCardService {
	// constants
	public static final String SOBJECT_NAME = 'RateCard__c';

	// runtime context
	public static RateCard__c rateCardSO;

	// constructor
	public RateCardService(Id rateCardId) {
		rateCardSO = [
			SELECT Id, AttributeGroupId__c
			FROM RateCard__c
			WHERE Id = :rateCardId
			WITH SECURITY_ENFORCED
			LIMIT 1
		];
	}

	/**
	 * Gets the list of attributes for a rate card
	 * @param
	 * @return Set<String>  list of attributes
	 */
	@AuraEnabled(cacheable=true)
	public static List<String> getAttributesFor(Id rateCardId) {
		Set<String> attributes = new Set<String>();
		for (RateCardAttribute__c att : [
			SELECT FieldAPIName__c, Sequence__c, AttributeGroupId__c
			FROM RateCardAttribute__c
			WHERE
				AttributeGroupId__c IN (SELECT AttributeGroupId__c FROM RateCard__c WHERE Id = :rateCardId)
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		]) {
			attributes.add(att.FieldAPIName__c);
		}
		return new List<String>(attributes);
	}

	/**
	 * Gets the list of attributes for a rate card
	 * @param
	 * @return Set<String>  list of attributes
	 */
	public Set<String> getAttributes() {
		Set<String> attributes = new Set<String>();
		for (RateCardAttribute__c att : [
			SELECT FieldAPIName__c, Sequence__c, AttributeGroupId__c
			FROM RateCardAttribute__c
			WHERE AttributeGroupId__c = :rateCardSO.AttributeGroupId__c
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		]) {
			attributes.add(att.FieldAPIName__c);
		}
		return attributes;
	}

	/**
	 * Gets the list of attributes for a rate card with their sequence
	 * @param
	 * @return Map<String, Decimal>  list of attributes
	 */
	public Map<String, Decimal> getAttributesWithSequence() {
		Map<String, Decimal> attributesWithSequence = new Map<String, Decimal>();
		for (RateCardAttribute__c att : [
			SELECT FieldAPIName__c, Sequence__c, AttributeGroupId__c
			FROM RateCardAttribute__c
			WHERE AttributeGroupId__c = :rateCardSO.AttributeGroupId__c
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c ASC
		]) {
			attributesWithSequence.put(att.FieldAPIName__c, att.Sequence__c);
		}
		return attributesWithSequence;
	}

	/**
	 * Checks if the rate card associated with a quote is expired or not
	 * @param
	 * @return Boolean true, if ratecard expired else false
	 */
	@AuraEnabled(cacheable=true)
	public static Map<Boolean, String> checkIfRateCardIsExpired(Id quoteId) {
		Map<Boolean, String> rateCardStatusMap = new Map<Boolean, String>();
		Boolean isExpired = true;
		Boolean isValidEffectiveDate;
		Boolean isValidExpirationDate;
		Boolean isActive;
		for (Quote__c quote : [
			SELECT
				Id,
				RateCardId__r.Name,
				AccountId__r.Name,
				RateCardId__r.EffectiveDate__c,
				RateCardId__r.ExpirationDate__c,
				RateCardId__r.IsActive__c,
				ServiceStartDate__c
			FROM Quote__c
			WHERE ID = :quoteId
			WITH SECURITY_ENFORCED
		]) {
			isValidEffectiveDate =
				quote.RateCardId__r.EffectiveDate__c == null ||
				quote.ServiceStartDate__c >= quote.RateCardId__r.EffectiveDate__c;
			isValidExpirationDate =
				quote.RateCardId__r.EffectiveDate__c == null ||
				quote.ServiceStartDate__c <= quote.RateCardId__r.ExpirationDate__c;
			isActive =
				quote.RateCardId__r.IsActive__c && quote.RateCardId__r.ExpirationDate__c >= Date.Today();
			isExpired = !(isValidEffectiveDate && isValidExpirationDate && isActive);
			rateCardStatusMap.put(isExpired, quote.AccountId__r.Name);
		}
		return rateCardStatusMap;
	}

	public static void overrideRateCardFromAssociatedAccount(List<Quote__c> newObjs) {
		Set<Id> accountId = new Set<Id>();
		List<Quote__c> quoteLst = new List<Quote__c>();
		for (Quote__c quote : (List<Quote__c>) newObjs) {
			if (quote.AccountId__c != null) {
				accountId.add(quote.AccountId__c);
				quotelst.add(quote);
			}
		}
		rateCardOverride(accountId, quoteLst);
	}

	public static void rateCardOverride(Set<Id> accountId, List<Quote__c> quoteLst) {
		Map<Id, RateCard__c> acctIdToRtMap = new Map<Id, RateCard__c>();
		for (RateCard__c rtCard : [
			SELECT AssignedToAccountId__c, Id
			FROM RateCard__c
			WHERE AssignedToAccountId__c IN :accountId
			WITH SECURITY_ENFORCED
			ORDER BY CreatedDate ASC
			LIMIT 1
		]) {
			acctIdToRtMap.put(rtCard.AssignedToAccountId__c, rtCard);
		}

		for (Quote__c qte : quoteLst) {
			if (acctIdToRtMap.containskey(qte.AccountId__c)) {
				qte.RateCardId__c = acctIdToRtMap.get(qte.AccountId__c).Id;
			}
		}
	}
}
