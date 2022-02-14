/**
 *  Provus Services Quoting
 *  ColaRateSheetService : This is service class for Cola Rate Sheet object
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ColaRateSheetService {
	/**
	 * Create a cloned Cola Rate Sheet record.
	 * @param   Id of the Cola Rate Sheet Record
	 * @param   wrapper class for COlA Rate Sheet object
	 * @return  String : Id of the Cloned Cola Rate Sheet
	 */
	public static ColaRateSheet__c cloneColaRateSheet(
		String colaRateSheetId,
		String clonedRateSheetData
	) {
		ColaRateSheet__c clonedRateSheet;
		ColaRateSheetCloneController.ColaRateSheetData rateSheetData = (ColaRateSheetCloneController.ColaRateSheetData) JSON.deserialize(
			clonedRateSheetData,
			ColaRateSheetCloneController.ColaRateSheetData.class
		);
		//fetching Cola Rate Sheet record
		QueryRequest queryRequest = new QueryRequest(Schema.ColaRateSheet__c.SObjectType);
		queryRequest.requestedFields = SObjectUtility.getFieldsForSObject(
			Schema.ColaRateSheet__c.SObjectType
		);
		queryRequest.setFilterBy(new Map<String, String>{ SObjectUtility.FIELD_ID => colaRateSheetId });
		List<ColaRateSheet__c> colaRateSheets = (List<ColaRateSheet__c>) SOQLUtility.querySObject(
			queryRequest
		);

		if (!colaRateSheets.isEmpty()) {
			ColaRateSheet__c colaRateSheet = colaRateSheets[0];
			clonedRateSheet = colaRateSheet.clone(false, false, false, false);
			clonedRateSheet.Name = rateSheetData.Name;
			clonedRateSheet.YearOverYearRate__c = rateSheetData.yearOverYearRate;
			clonedRateSheet.DerivedFromId__c = colaRateSheetId;

			CRUDUtility.insertRecords(clonedRateSheet);

			List<ColaRate__c> clonedColaRates = new List<ColaRate__c>();
			//fetching Cola Rates
			QueryRequest colaRatesQueryRequest = new QueryRequest(Schema.ColaRate__c.SObjectType);
			colaRatesQueryRequest.requestedFields = SObjectUtility.getFieldsForSObject(
				Schema.ColaRate__c.SObjectType
			);
			colaRatesQueryRequest.setFilterBy(
				new Map<String, String>{ Schema.ColaRate__c.RateSheetId__c + '' => colaRateSheetId }
			);
			for (
				ColaRate__c colaRate : (List<ColaRate__c>) SOQLUtility.querySObject(colaRatesQueryRequest)
			) {
				ColaRate__c clonedColaRate = colaRate.clone(false, false, false, false);
				clonedColaRate.RateSheetId__c = clonedRateSheet.Id;
				clonedColaRates.add(clonedColaRate);
			}

			if (!clonedColaRates.isEmpty()) {
				CRUDUtility.insertRecords(clonedColaRates);
			}
		}

		return clonedRateSheet;
	}
}
