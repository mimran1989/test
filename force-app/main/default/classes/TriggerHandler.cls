/**
 *  Provus Services Quoting
 *  TriggerHandler
 *  @2021 Provus Inc. All rights reserved.
 *
 */
public virtual with sharing class TriggerHandler {
	protected final Map<Id, SObject> oldMap;
	protected final Map<Id, SObject> newMap;
	protected final List<SObject> newObjs;
	protected final Boolean isInsert;
	protected final Boolean isUpdate;
	protected final Boolean isDelete;
	protected final Boolean isBulk;

	public TriggerHandler(Map<Id, SObject> xOldMap, List<SObject> xNewObjs, Boolean isBefore) {
		oldMap = xOldMap;
		newObjs = xNewObjs;

		if (!isBefore && newObjs != null) {
			newMap = new Map<Id, SObject>(newObjs);
		}

		isDelete =
			(SystemUtility.nullOrEmpty(xNewObjs) && isBefore) ||
			(SystemUtility.nullOrEmpty(newMap) && !isBefore);
		isUpdate = !isDelete && !SystemUtility.nullOrEmpty(oldMap);
		isInsert = !isDelete && !isUpdate;
		isBulk = newObjs != null && newObjs.size() > 1;

		if (isBefore && isUpdate && newObjs != null) {
			newMap = new Map<Id, SObject>(newObjs);
		}
	}

	public Boolean isChanged(Id objectId, Schema.SObjectField fieldSchema) {
		return isChanged(objectId, fieldSchema + '');
	}

	public Boolean isChanged(Id objectId, String fieldApiName) {
		Object oldValue = oldMap?.get(objectId)?.get(fieldApiName);
		Object newValue = newMap?.get(objectId)?.get(fieldApiName);
		return oldValue != newValue;
	}
}
