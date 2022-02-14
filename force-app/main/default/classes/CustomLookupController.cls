/**
 *  Provus Services Quoting
 *  CustomLookupController : This is a controller for Customlookup Component
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CustomLookupController {
	private static List<RecordsData> fetchRecordsforTasks(Map<String, String> params) {
		String objectName = String.escapeSingleQuotes(params.get(EstimatorConstants.SOBJECT_NAME));
		String filterField = String.escapeSingleQuotes(params.get(EstimatorConstants.FILTER_FIELD));

		// if filter criteria value provided escape
		String filterCriteriaValue = params.get(EstimatorConstants.FILTER_CRITERIA);
		String filterCriteria = filterCriteriaValue != null ? ' AND ' + filterCriteriaValue : '';

		String rateCard = params.get(EstimatorConstants.RATE_CARD);
		String searchWord =
			'\'%' +
			String.escapeSingleQuotes(params.get(EstimatorConstants.SEARCH_STRING).trim()) +
			'%\'';
		String query;
		if (rateCard != null) {
			query =
				'SELECT Id,ProductId__r.Name,ProductId__c from RateCardItem__c WHERE RateCardId__c=:rateCard AND ProductId__r.Name Like ' +
				searchWord +
				filterCriteria +
				' LIMIT 2000';
		} else {
			query =
				'SELECT Id,' +
				filterField +
				' FROM ' +
				objectName +
				' WHERE ' +
				filterField +
				' LIKE ' +
				searchWord +
				filterCriteria +
				' LIMIT 2000';
		}
		List<RecordsData> recordsDataList = new List<RecordsData>();
		// prettier-ignore
		for (SObject record : Database.query(query)) {//NOPMD; query is escaped on line 14
			if (rateCard != null) {
				recordsDataList.add(
					new RecordsData(
						String.valueOf(record.getSObject(EstimatorConstants.PRODUCT_RELATION).get('Name')),
						(String) record.get(EstimatorConstants.PRODUCT_APINAME)
					)
				);
			} else {
				recordsDataList.add(
					new RecordsData((String) record.get(filterField), (String) record.get('id'))
				);
			}
		}
		return recordsDataList;
	}
	// Method to fetch lookup default value
	@AuraEnabled
	public static SObject fetchDefaultRecord(String recordId, String sObjectApiName) {
		for (
			SObject obj : Database.query(
				String.escapeSingleQuotes(
					'Select Id,Name From ' +
					sObjectApiName +
					' Where Id = : recordId LIMIT 1'
				)
			)
		) {
			return obj;
		}
		return null;
	}

	@AuraEnabled
	public static List<RecordsData> fetchRecords(Map<String, String> paramMap) {
		String objectName = paramMap.get('objectName');
		String filterField = paramMap.get(EstimatorConstants.FILTER_FIELD);
		String filterCriteria = paramMap.get(EstimatorConstants.FILTER_CRITERIA);
		String searchString = paramMap.get('searchString');
		String hierarchylevel = paramMap.containsKey('hierarchylevel')
			? paramMap.get('hierarchylevel')
			: '';
		String hierarchylevelId = paramMap.containsKey('hierarchylevelId')
			? paramMap.get('hierarchylevelId')
			: '';
		String rateCard = paramMap.containsKey('rateCard') ? paramMap.get('rateCard') : '';
		if (hierarchylevel == 'Task') {
			return fetchRecordsforTasks(
				new Map<String, String>{
					'objectName' => objectName,
					EstimatorConstants.FILTER_FIELD => filterField,
					EstimatorConstants.FILTER_CRITERIA => filterCriteria,
					'searchString' => searchString,
					'rateCard' => rateCard
				}
			);
		} else {
			return fetchRecordsExceptTasks(
				new Map<String, String>{
					'objectName' => objectName,
					'filterField' => filterField,
					'searchString' => searchString,
					'hierarchylevelId' => hierarchylevelId,
					'hierarchylevel' => hierarchylevel
				}
			);
		}
	}

	public static List<RecordsData> fetchRecordsExceptTasks(Map<String, String> params) {
		String hierarchylevelId = params?.get('hierarchylevelId');
		String objectName = params?.get('objectName');
		String searchString = params?.get('searchString');
		String filterField = params?.get('filterField');
		String hierarchylevel = params?.get('hierarchylevel');
		Set<Id> productIds = new Set<Id>();
		if (hierarchylevel == EstimatorConstants.ACTIVITY_GROUP) {
			for (TaskRoleSummary__c taskroleSummary : [
				SELECT Id, ResourceRoleId__c
				FROM TaskRoleSummary__c
				WHERE ActivityGroupId__c = :hierarchylevelId
				WITH SECURITY_ENFORCED
			]) {
				productIds.add(taskroleSummary.ResourceRoleId__c);
			}
		} else if (hierarchylevel == EstimatorConstants.ACTIVITY) {
			for (TaskRoleSummary__c taskroleSummary : [
				SELECT Id, ResourceRoleId__c
				FROM TaskRoleSummary__c
				WHERE ActivityId__c = :hierarchylevelId
				WITH SECURITY_ENFORCED
			]) {
				productIds.add(taskroleSummary.ResourceRoleId__c);
			}
		} else if (hierarchylevel == EstimatorConstants.ESTIMATE) {
			for (TaskRoleSummary__c taskroleSummary : [
				SELECT Id, ResourceRoleId__c
				FROM TaskRoleSummary__c
				WHERE EstimateId__c = :hierarchylevelId
				WITH SECURITY_ENFORCED
			]) {
				productIds.add(taskroleSummary.ResourceRoleId__c);
			}
		}
		String searchWord = '\'%' + String.escapeSingleQuotes(searchString.trim()) + '%\'';
		List<RecordsData> recordsDataList = new List<RecordsData>();
		String query = 'SELECT Id, ' + filterField + ' FROM ' + objectName;
		query +=
			' WHERE recordtype.Name=\'Resource Role\' and ' +
			filterField +
			' LIKE ' +
			searchWord +
			' LIMIT 49999';
		// prettier-ignore
		for (SObject record : Database.query(query)) { //NOPMD; escaped on line 136
			if (!ProductIds.contains((String) record.get('id'))) {
				recordsDataList.add(
					new RecordsData((String) record.get(filterField), (String) record.get('id'))
				);
			}
		}
		return recordsDataList;
	}
	public class RecordsData {
		@AuraEnabled
		public String label;
		@AuraEnabled
		public String value;
		public RecordsData(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}
}
