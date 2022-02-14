/**
 *  Provus Services Quoting
 *  SystemUtility
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class SystemUtility {
	// constants
	public static final String PACKAGE_NAMESPACE = 'PSQ';
	public static final String CLASS_NAME = 'SystemUtility';
	public static final String COMMA = ',';
	private static Boolean isDeployedInSandbox;

	/**
	 * Checks if this class is deployed in the namespace
	 * @return returns namespace prefix string
	 */
	@AuraEnabled(Cacheable=true)
	public static String getNamespacePrefix() {
		System.Type systemType;
		try {
			systemType = System.Type.forName(PACKAGE_NAMESPACE, CLASS_NAME);
		} catch (Exception e) {
			systemType = null;
		}
		return (systemType != null ? PACKAGE_NAMESPACE + '__' : '');
	}

	/**
	 * Checks if the source is deployed in a sandbox
	 * @return  true if deployed in a sandbox, false otherwise
	 */
	public static Boolean isInSandbox() {
		if (isDeployedInSandbox == null) {
			// Intentionally query with system context
			Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1]; //NOPMD
			isDeployedInSandbox = orgInfo.IsSandbox;
		}

		return isDeployedInSandbox;
	}

	/**
	 * Get the email template by name or developer name
	 * @param developerName the unique template name
	 * @return the email template sobject id
	 */
	public static EmailTemplate getEmailTemplateFor(String developerName) {
		EmailTemplate templateSO = [
			SELECT Subject, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = :developerName
			WITH SECURITY_ENFORCED
		];

		return templateSO;
	}

	/**
	 * Converts String with comma separated values to a Set of Strings
	 * @param commaString comma seperated values
	 *
	 * @return returns set of string values
	 */
	public static Set<String> csvToSet(String commaString) {
		Set<String> stringSet = new Set<String>();
		if (commaString != null && commaString.contains(COMMA)) {
			for (String fld : commaString.split(COMMA)) {
				stringSet.add(fld.trim());
			}
		} else if (commaString != null) {
			stringSet.add(commaString.trim());
		}
		return stringSet;
	}

	public static Boolean nullOrEmpty(List<Object> objList) {
		return objList == null || objList.isEmpty();
	}

	public static Boolean nullOrEmpty(Map<Id, SObject> objects) {
		return objects == null || objects.isEmpty();
	}

	public static Decimal delta(Decimal oldValue, Decimal newValue) {
		return nullToZero(newValue) - nullToZero(oldValue);
	}

	public static Decimal nullToZero(Decimal input) {
		return input == null ? 0 : input;
	}

	public static Map<Id, SObject> keyByIdType(List<SObject> objs, SObjectField idTypeField) {
		String sObjName = String.valueOf(objs[0].getSObjectType());
		Type objType = Type.forName('Map<Id,' + sObjName + '>');
		Map<Id, SObject> objByIdTypeField = (Map<Id, SObject>) objType.newInstance();
		for (SObject obj : objs) {
			objByIdTypeField.put((Id) obj.get(idTypeField), obj);
		}

		return objByIdTypeField;
	}

	public static Map<String, SObject> keyByStringType(
		List<SObject> objs,
		SObjectField stringTypeField
	) {
		String sObjName = String.valueOf(objs[0].getSObjectType());
		Type objType = Type.forName('Map<String,' + sObjName + '>');
		Map<String, SObject> objByIdTypeField = (Map<String, SObject>) objType.newInstance();
		for (SObject obj : objs) {
			objByIdTypeField.put((String) obj.get(stringTypeField), obj);
		}

		return objByIdTypeField;
	}

	public static String getRName(Schema.SObjectField field) {
		return (field + '').substringBeforeLast('__c') + '__r';
	}

	public static String getChildRName(Schema.SObjectField parent, Schema.SObjectField child) {
		return getRName(parent) + '.' + child;
	}

	public static String getInverseRName(Schema.SObjectType parent, Schema.SObjectType child) {
		for (ChildRelationship relation : parent.getDescribe().getChildRelationships()) {
			if (relation.getChildSObject() == child) {
				return relation.getRelationshipName();
			}
		}

		return '';
	}

	public static Map<Id, Map<Id, SObject>> cloneChildEntities(
		Schema.SObjectType objectType,
		String parentFieldName,
		Map<Id, Set<Id>> targetIdsBySourceId
	) {
		QueryRequest queryRequest = new QueryRequest(objectType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(objectType);
		queryRequest.setFilterBy(
			new Map<String, Set<Id>>{ parentFieldName => targetIdsBySourceId.keySet() }
		);
		List<SObject> sourceEntitiesToClone = SOQLUtility.querySObject(queryRequest);

		Map<Id, Map<Id, SObject>> newEntities = new Map<Id, Map<Id, SObject>>();
		for (SObject sourceEntity : sourceEntitiesToClone) {
			for (Id targetId : targetIdsBySourceId.get((Id) sourceEntity.get(parentFieldName))) {
				SObject clonedEntity = sourceEntity.clone(false, true);
				clonedEntity.put(parentFieldName, targetId);

				Map<Id, SObject> entitiesForTarget = newEntities.get(targetId);
				if (entitiesForTarget == null) {
					entitiesForTarget = new Map<Id, SObject>();
					newEntities.put(targetId, entitiesForTarget);
				}

				entitiesForTarget.put(sourceEntity.Id, clonedEntity);
			}
		}

		return newEntities;
	}

	public static Map<Id, Map<Id, SObject>> cloneChildEntities(
		List<SObject> sourceEntitiesToClone,
		String parentFieldName,
		Map<Id, Set<Id>> targetIdsBySourceId
	) {
		Map<Id, Map<Id, SObject>> newEntities = new Map<Id, Map<Id, SObject>>();
		for (SObject sourceEntity : sourceEntitiesToClone) {
			for (Id targetId : targetIdsBySourceId.get((Id) sourceEntity.get(parentFieldName))) {
				SObject clonedEntity = sourceEntity.clone(false, true);
				clonedEntity.put(parentFieldName, targetId);

				Map<Id, SObject> entitiesForTarget = newEntities.get(targetId);
				if (entitiesForTarget == null) {
					entitiesForTarget = new Map<Id, SObject>();
					newEntities.put(targetId, entitiesForTarget);
				}

				entitiesForTarget.put(sourceEntity.Id, clonedEntity);
			}
		}

		return newEntities;
	}
}
