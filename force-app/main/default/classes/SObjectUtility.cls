/**
 *  Provus Services Quoting
 *  SObjectUtility
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class SObjectUtility {
	// constants
	public static final String FIELD_ID = 'Id';
	public static final String FIELD_NAME = 'Name';
	public static final String FIELD_OWNER_ID = 'OwnerId';
	public static final String PICKLIST_TYPE = 'PICKLIST';
	public static final String CUSTOM_FIELD_INDICATOR = '__c';

	/**
	 * Wrapper class which holds quote item fields
	 */
	public class SObjectFieldInfo {
		public String fieldName;
		public String fieldLabel;
		public Schema.DisplayType dataType;
		public String sourceObject;
		public List<String> pickListValues;
		public Boolean isEditable;
		public Boolean isRequired;
		public Boolean isHidden;
		public Decimal sequence;

		public SObjectFieldInfo() {
		}
	}

	/**
	 * Gets the details for requested fields on the sobjects
	 * @param  Map<String,Set<String>> fieldsBySObjectMap
	 * @return List<SObjectFieldInfo>
	 */
	public static List<SObjectFieldInfo> getSObjectFields(
		Map<Schema.SObjectType, Set<String>> fieldsBySObjectMap
	) {
		List<SObjectFieldInfo> sObjectFields = new List<SObjectFieldInfo>();

		for (Schema.SObjectType sobjectType : fieldsBySObjectMap.keySet()) {
			Map<String, Schema.SObjectField> fieldMap = sobjectType.getDescribe().fields.getMap();

			for (String requestedFieldName : fieldsBySObjectMap.get(sobjectType)) {
				Schema.SObjectField requestedFieldType = fieldMap.get(requestedFieldName);
				Schema.DescribeFieldResult fieldDescribe = requestedFieldType.getDescribe();

				SObjectFieldInfo thisField = new SObjectFieldInfo();
				thisField.sourceObject = sobjectType + '';
				thisField.fieldName = requestedFieldType + '';
				thisField.fieldLabel = fieldDescribe.getLabel();
				thisField.dataType = fieldDescribe.getType();

				if (thisField.dataType + '' == PICKLIST_TYPE) {
					thisField.pickListValues = getPicklistValuesFor(fieldDescribe.getPickListValues());
				}

				sObjectFields.add(thisField);
			}
		}

		return sObjectFields;
	}

	/** Gets the list of options for picklist values.
	 * @param String sObjectName
	 * @param String fieldName
	 * @returns list of Labels of picklist field
	 */
	public static List<String> getPicklistValuesFor(List<Schema.PicklistEntry> picklistEntries) {
		List<String> picklistValues = new List<String>();
		for (Schema.PicklistEntry entry : picklistEntries) {
			picklistValues.add(entry.getValue());
		}

		return picklistValues;
	}

	/** Gets the list of all fields for SObject
	 * @param String sObjectName
	 * @returns
	 */
	public static Set<String> getFieldsForSObject(SObjectType objType) {
		Set<String> objFieldSet = new Set<String>();

		Map<String, Schema.SObjectField> objFields = objType.getDescribe().fields.getMap();

		for (String fldName : objFields.keySet()) {
			if (objFields.get(fldName).getDescribe().isAccessible()) {
				objFieldSet.add(fldName);
			}
		}

		return objFieldSet;
	}

	/** Gets recordTypeId from Sobject.
	 * @param String sObjectName
	 * @param String recordTypeName
	 * @returns Id of recordType
	 */
	public static Id getRecordTypeIdbyName(String sObjectName, String recordTypeName) {
		return Schema.getGlobalDescribe()
			.get(sObjectName)
			.getDescribe()
			.getRecordTypeInfosByName()
			.get(recordTypeName)
			.getRecordTypeId();
	}

	/**
	 * Gets custom fields for the given SObject name.
	 * @param sObjectName An SObject name
	 *
	 * @return A set of accessible custom fields
	 */
	public static Set<String> getCustomFieldsForSObject(String sObjectName) {
		Set<String> objFieldSet = new Set<String>{ SObjectUtility.FIELD_ID };

		SObjectType objType = Schema.getGlobalDescribe().get(sObjectName);
		Map<String, Schema.SObjectField> objFields = objType.getDescribe().fields.getMap();

		for (String fldName : objFields.keySet()) {
			if (
				objFields.get(fldName).getDescribe().isAccessible() &&
				objFields.get(fldName).getDescribe().isCustom()
			) {
				objFieldSet.add(fldName);
			}
		}

		return objFieldSet;
	}
}
