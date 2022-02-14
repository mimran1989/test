/**
 *  Provus Services Quoting
 *  ColaRateSheetCloneController : This is controller for cola rate sheet Cloner lwc component
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ColaRateSheetCloneController {
	/**
	 * Create a cloned Cola Rate Sheet record.
	 * @param   Id of the Cola Rate Sheet Record
	 * @param   String : cola rate sheet wrapper JSON
	 * @return  String : Id of the Cloned Cola Rate Sheet
	 */
	@AuraEnabled
	public static String cloneColaRateSheet(String colaRateSheetId, String clonedRateSheetData) {
		ColaRateSheet__c colaRateSheet = ColaRateSheetService.cloneColaRateSheet(
			colaRateSheetId,
			clonedRateSheetData
		);

		return colaRateSheet.Id;
	}

	public class ColaRateSheetData {
		@AuraEnabled
		public String name;

		@AuraEnabled
		public Decimal yearOverYearRate;
	}
}
