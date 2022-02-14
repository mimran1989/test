/**
 *  Provus Services Quoting
 *  ObjectOverrideController
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ObjectOverrideController {
	@AuraEnabled
	public static ObjectOverrideDTO getObjectOverride(Id quoteId, String overrideObjectApiName) {
		// get object override id from junction object
		QuoteObjectOverride__c quoteObjectOverrideJct = ObjectOverrideService.getObjectOverrideId(
			quoteId,
			overrideObjectApiName
		);

		// get object override object for UI
		ObjectOverrideDTO objectOverrideDto = ObjectOverrideService.getObjectOverride(
			quoteObjectOverrideJct.ObjectOverrideId__c,
			overrideObjectApiName
		);
		objectOverrideDto.junctionRecordId = quoteObjectOverrideJct.Id;
		return objectOverrideDto;
	}

	@AuraEnabled
	public static ObjectOverrideResult commitObjectOverride(
		Id quoteId,
		ObjectOverrideDTO objectOverrideDto
	) {
		ObjectOverrideResult validationResult = ObjectOverrideService.commitObjectOverride(
			objectOverrideDto
		);
		if (objectOverrideDto.junctionRecordId == null) {
			validationResult.objectOverrideDtos[0]
				.junctionRecordId = ObjectOverrideService.insertQuoteObjectOverrideJctRecord(
				quoteId,
				validationResult.objectOverrideDtos[0].id
			);
		}

		return validationResult;
	}
}
