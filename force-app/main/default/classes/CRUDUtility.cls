/**
 *  Provus Services Quoting
 *  CRUDUtility -- perform crud operations with security enforced
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CRUDUtility {
	public static SObject insertRecords(SObject sObjectToInsert) {
		if (sObjectToInsert == null) {
			return sObjectToInsert;
		}

		return insertRecords(new List<SObject>{ sObjectToInsert })[0];
	}
	public static SObject updateRecords(SObject sObjectToUpdate) {
		if (sObjectToUpdate == null) {
			return sObjectToUpdate;
		}

		return updateRecords(new List<SObject>{ sObjectToUpdate })[0];
	}
	public static SObject upsertRecords(SObject sObjectToUpsert) {
		if (sObjectToUpsert == null) {
			return sObjectToUpsert;
		}

		return upsertRecords(new List<SObject>{ sObjectToUpsert })[0];
	}
	public static SObject deleteRecords(SObject sObjectToDelete) {
		if (sObjectToDelete == null) {
			return sObjectToDelete;
		}

		return deleteRecords(new List<SObject>{ sObjectToDelete })[0];
	}

	public static List<SObject> insertRecords(List<SObject> sObjectsToInsert) {
		if (SystemUtility.nullOrEmpty(sObjectsToInsert)) {
			return sObjectsToInsert;
		}
		// sObjectsToInsert.sort(); Sorting is troublesome when it is unexpected by the callee

		SObjectAccessDecision securityDecision = Security.stripInaccessible(
			AccessType.CREATABLE,
			sObjectsToInsert,
			true
		);
		insert securityDecision.getRecords();

		return resolveIdsAfterInsert(sObjectsToInsert, securityDecision.getRecords());
	}

	public static List<SObject> updateRecords(List<SObject> sObjectsToUpdate) {
		if (SystemUtility.nullOrEmpty(sObjectsToUpdate)) {
			return sObjectsToUpdate;
		}
		// sObjectsToUpdate.sort(); Sorting is troublesome when it is unexpected by the callee

		SObjectAccessDecision securityDecision = Security.stripInaccessible(
			AccessType.UPDATABLE,
			sObjectsToUpdate,
			true
		);

		update securityDecision.getRecords();
		return sObjectsToUpdate;
	}

	public static List<SObject> upsertRecords(List<SObject> sObjectsToUpsert) {
		if (SystemUtility.nullOrEmpty(sObjectsToUpsert)) {
			return sObjectsToUpsert;
		}
		// sObjectsToUpsert.sort(); Sorting is troublesome when it is unexpected by the callee

		// Breakup the operation into insert and update to allow sObjects
		// which have M-D relationships which are not reparentable to utilize `upsert`
		List<SObject> inserting = new List<SObject>();
		List<SObject> updating = new List<SObject>();
		for (sObject sObjectToUpsert : sObjectsToUpsert) {
			if (sObjectToUpsert.Id == null) {
				inserting.add(sObjectToUpsert);
			} else {
				updating.add(sObjectToUpsert);
			}
		}

		insertRecords(inserting);
		updateRecords(updating);

		return sObjectsToUpsert;
	}

	public static List<SObject> deleteRecords(List<SObject> sObjectsToDelete) {
		if (SystemUtility.nullOrEmpty(sObjectsToDelete)) {
			return sObjectsToDelete;
		}

		Set<Schema.SObjectType> deletableTypes = new Set<Schema.SObjectType>();
		Set<Schema.SObjectType> notDeletableTypes = new Set<Schema.SObjectType>();
		List<SObject> sanitizedList = new List<SObject>();
		for (SObject sObjectToDelete : sObjectsToDelete) {
			Schema.SObjectType ctxType = sObjectToDelete.getSObjectType();
			if (deletableTypes.contains(ctxType)) {
				sanitizedList.add(sObjectToDelete);
			} else if (!notDeletableTypes.contains(ctxType) && ctxType.getDescribe().isDeletable()) {
				deletableTypes.add(ctxType);
				sanitizedList.add(sObjectToDelete);
			} else if (!notDeletableTypes.contains(ctxType)) {
				notDeletableTypes.add(ctxType);
			}
		}

		// CRUD security for delete is checked on lines ~165 - 174
		delete sanitizedList; //NOPMD
		return sObjectsToDelete;
	}

	private static List<SObject> resolveIdsAfterInsert(
		List<SObject> sourceRecords,
		List<SObject> sanitizedRecords
	) {
		for (Integer i = 0; i < sanitizedRecords.size(); i++) {
			if (sourceRecords[i].Id == null) {
				sourceRecords[i].Id = sanitizedRecords[i].Id;
			}
		}
		return sourceRecords;
	}
}
