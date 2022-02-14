/**
 *  Provus Services Quoting
 *  ObjectOverrideService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ObjectOverrideService {
	/**
	 * Gets the Id of the associated object override record to a quote for a specified object api name
	 *
	 * @param quoteId quote id to find related override records
	 * @param overrideObjectApiName specific object API name we need overrides for
	 *
	 * @return returns id of associated Object Override record for given override object API name
	 */
	public static QuoteObjectOverride__c getObjectOverrideId(
		Id quoteId,
		String overrideObjectApiName
	) {
		QuoteObjectOverride__c quoteObjectOverrideJct = new QuoteObjectOverride__c();
		List<QuoteObjectOverride__c> objectOverrides = [
			SELECT Id, ObjectOverrideId__c
			FROM QuoteObjectOverride__c
			WHERE
				ObjectOverrideId__c IN (
					SELECT Id
					FROM ObjectOverride__c
					WHERE OverrideObjectApiName__c = :overrideObjectApiName
				)
				AND QuoteId__c = :quoteId
			WITH SECURITY_ENFORCED
			LIMIT 1
		];

		if (objectOverrides.size() == 1) {
			quoteObjectOverrideJct = objectOverrides[0];
		}

		return quoteObjectOverrideJct;
	}

	public static Id insertQuoteObjectOverrideJctRecord(Id quoteId, Id objectOverrideId) {
		QuoteObjectOverride__c quoteObjectOverrideJct = new QuoteObjectOverride__c(
			QuoteId__c = quoteId,
			ObjectOverrideId__c = objectOverrideId
		);

		CRUDUtility.insertRecords(quoteObjectOverrideJct);
		return quoteObjectOverrideJct.Id;
	}

	public static ObjectOverrideDTO getObjectOverride(Id objectOverrideId) {
		return getObjectOverride(objectOverrideId, null);
	}

	/**
	 * Returns object override record by id and child value override records as custom DTO objects
	 *
	 * @param objectOverrideId Id of Object Override record
	 * @param overrideObjectApiName String object api name of object being overriden
	 *
	 * @return returns object override DTO
	 */
	public static ObjectOverrideDTO getObjectOverride(
		Id objectOverrideId,
		String overrideObjectApiName
	) {
		ObjectOverride__c objectOverrideRecord = new ObjectOverride__c();
		objectOverrideRecord.OverrideObjectApiName__c = overrideObjectApiName;

		if (objectOverrideId != null) {
			objectOverrideRecord = [
				SELECT
					Id,
					OverrideObjectApiName__c,
					(
						SELECT Id, FieldApiName__c, FieldValue__c, ObjectOverrideId__c
						FROM ObjectValueOverrides__r
					)
				FROM ObjectOverride__c
				WHERE Id = :objectOverrideId
				WITH SECURITY_ENFORCED
				LIMIT 1
			];
		}

		ObjectOverrideDTO objectValueOverrideDTO = new ObjectOverrideDTO(objectOverrideRecord);

		objectValueOverrideDTO.valueOverrides = mapValueOverrideSOsToDTOs(
			objectOverrideRecord.ObjectValueOverrides__r
		);

		if (objectOverrideRecord.OverrideObjectApiName__c.contains('ScheduleSetting__mdt')) {
			objectValueOverrideDTO.valueOverrides = mapScheduleSettingToDefaultValueOverrides(
				objectValueOverrideDTO.valueOverrides
			);
		}

		return objectValueOverrideDTO;
	}

	public static ObjectOverrideResult commitObjectOverride(ObjectOverrideDTO objectOverrideDto) {
		ObjectOverrideResult validationResult = validate(objectOverrideDto);
		if (validationResult.isValid()) {
			objectOverrideDto.refreshSO();
			if (objectOverrideDto.valueOverrides.size() == 0) {
				// delete object override parent record (cascading delete will remove child records)
				CRUDUtility.deleteRecords(objectOverrideDto.sO);
			} else {
				// insert for new object override
				if (objectOverrideDto.sO.Id == null) {
					CRUDUtility.insertRecords(objectOverrideDto.sO);
				}

				commitValueOverrides(objectOverrideDto);
			}

			// copy SO object property values to DTO object properties
			objectOverrideDto.refreshDO();
			validationResult.objectOverrideDtos.add(objectOverrideDto);
		}

		return validationResult;
	}

	/**
	 * Validates ObjectOverrideDTO object before upsert
	 *
	 * @param objectOverride ObjectOverrideDTO object record to validate
	 * @param callerIsTrigger set true if being called from a trigger
	 *
	 * @return returns a List of String of errors when callerIsTrigger is false
	 */
	public static ObjectOverrideResult validate(ObjectOverrideDTO objectOverride) {
		ObjectOverrideResult validationResult = new ObjectOverrideResult();

		// validate object API name exists
		SObjectType objType = Schema.getGlobalDescribe().get(objectOverride.overrideObjectApiName);

		if (objType == null) {
			String errorMessage = Label.InvalidObjectAPIName.replace(
				'{0}',
				objectOverride.overrideObjectApiName
			);
			validationResult.errorMsgs.add(errorMessage);

			return validationResult;
		}

		validationResult.errorMsgs = validateValueOverrides(objectOverride, objType);

		return validationResult;
	}

	private static List<String> validateValueOverrides(
		ObjectOverrideDTO objectOverride,
		SObjectType objType
	) {
		List<String> errorMsgs = new List<String>();
		Set<String> customFieldApiNames = new Set<String>();

		// get map of SObject fields
		for (Schema.SObjectField fld : objType.getDescribe().fields.getMap().values()) {
			DescribeFieldResult fieldDescribe = fld.getDescribe();

			if (fieldDescribe.custom) {
				customFieldApiNames.add(fieldDescribe.name);
			}
		}

		Set<String> newFieldApiNames = new Set<String>();

		for (ValueOverrideDTO valueOverrideDto : objectOverride.valueOverrides) {
			String fieldApiName = valueOverrideDto.fieldApiName;
			// if field api name is a duplicate or not existing on the target object list of custom fields
			// then add error message
			if (newFieldApiNames.contains(fieldApiName) || !customFieldApiNames.contains(fieldApiName)) {
				String errorMsg = Label.InvalidFieldAPIName.replace('{0}', valueOverrideDto.fieldApiName);
				errorMsgs.add(errorMsg);

				// skip this field override and process any more erroneous field value override records
				continue;
			}

			newFieldApiNames.add(fieldApiName);
		}

		return errorMsgs;
	}

	private static void commitValueOverrides(ObjectOverrideDTO objectOverrideDto) {
		Id objectOverrideId = objectOverrideDto.sO.Id;

		List<ValueOverride__c> valueOverrideSOs = new List<ValueOverride__c>();

		// create list of SOs and update relationship Id for upsert if needed
		for (ValueOverrideDTO valueOverrideDto : objectOverrideDto.valueOverrides) {
			if (valueOverrideDto.sO.Id == null) {
				valueOverrideDto.sO.ObjectOverrideId__c = objectOverrideId;
			}
			objectOverrideDto.sO.ObjectValueOverrides__r.add(valueOverrideDto.sO);
			valueOverrideSOs.add(valueOverrideDto.sO);
		}

		// upsert override values in case they've changed for an already existing object override
		CRUDUtility.upsertRecords(valueOverrideSOs);

		// get list of value override records no long existing
		List<ValueOverride__c> valueOverrideSOsForDelete = getValueOverridesForDelete(
			objectOverrideDto.id,
			objectOverrideDto.valueOverrides
		);

		if (valueOverrideSOsForDelete.size() > 0) {
			CRUDUtility.deleteRecords(valueOverrideSOsForDelete);
		}
	}

	private static List<ValueOverrideDTO> mapScheduleSettingToDefaultValueOverrides(
		List<ValueOverrideDTO> valueOverrides
	) {
		List<ValueOverrideDTO> newValueOverrideDtos = new List<ValueOverrideDTO>();
		ScheduleSetting__mdt scheduleSetting = ScheduleSetting__mdt.getInstance('StandardSchedule');
		Map<String, String> fieldApiNames = new Map<String, String>();

		// validate object API name exists
		SObjectType objType = Schema.getGlobalDescribe()
			.get(SystemUtility.getNamespacePrefix() + 'ScheduleSetting__mdt');

		// get map of SObject fields
		for (Schema.SObjectField fld : objType.getDescribe().fields.getMap().values()) {
			DescribeFieldResult fieldDescribe = fld.getDescribe();

			if (fieldDescribe.custom && fieldDescribe.getType().name() != 'REFERENCE') {
				fieldApiNames.put(fieldDescribe.name, fieldDescribe.label);
			}
		}

		for (String fieldApiName : fieldApiNames.keySet()) {
			ValueOverrideDTO valueOverrideDto = getOverride(valueOverrides, fieldApiName);
			String valueOverrideDtp = String.valueOf(scheduleSetting.get(fieldApiName));
			String fieldLabel = fieldApiNames.get(fieldApiName);
			// value override record exists
			if (valueOverrideDto != null) {
				valueOverrideDto.defaultFieldValue = valueOverrideDtp;
				valueOverrideDto.fieldLabel = fieldLabel;
				newValueOverrideDtos.add(valueOverrideDto);
			} else {
				// value override record does not exist
				ValueOverrideDTO newDefaultValueOverrideDto = new ValueOverrideDTO(
					fieldApiName,
					valueOverrideDtp
				);
				newDefaultValueOverrideDto.fieldLabel = fieldLabel;
				valueOverrides.add(newDefaultValueOverrideDto);
				newValueOverrideDtos.add(newDefaultValueOverrideDto);
			}
		}

		return newValueOverrideDtos;
	}

	private static ValueOverrideDTO getOverride(
		List<ValueOverrideDTO> valueOverrides,
		String fieldNameApi
	) {
		for (ValueOverrideDTO valueOverrideDto : valueOverrides) {
			if (valueOverrideDto.fieldApiName == fieldNameApi) {
				return valueOverrideDto;
			}
		}

		return null;
	}

	/**
	 * @param valueOverrideSOs list of Value Override SO objects
	 *
	 * @return return list of ValueOverrideDTO objects
	 */
	private static List<ValueOverrideDTO> mapValueOverrideSOsToDTOs(
		List<ValueOverride__c> valueOverrideSOs
	) {
		List<ValueOverrideDTO> valueOverrideDtos = new List<ValueOverrideDTO>();

		for (ValueOverride__c valueOverride : valueOverrideSOs) {
			valueOverrideDtos.add(new ValueOverrideDTO(valueOverride));
		}

		return valueOverrideDtos;
	}

	private static List<ValueOverride__c> getValueOverridesForDelete(
		Id objectOverrideId,
		List<ValueOverrideDTO> valueOverrideDtos
	) {
		Set<String> fieldApiNames = new Set<String>();
		for (ValueOverrideDTO valueOverrideDto : valueOverrideDtos) {
			fieldApiNames.add(valueOverrideDto.fieldApiName);
		}

		List<ValueOverride__c> valueOverridesForDelete = [
			SELECT Id, FieldApiName__c
			FROM ValueOverride__c
			WHERE ObjectOverrideId__c = :objectOverrideId AND FieldApiName__c NOT IN :fieldApiNames
			WITH SECURITY_ENFORCED
		];

		return valueOverridesForDelete;
	}
}
