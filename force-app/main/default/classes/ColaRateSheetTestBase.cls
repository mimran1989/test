/**
 *  Provus Services Quoting
 *  ColaRateSheetTestsBase : This is Tests Base for cola rate sheet Object
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class ColaRateSheetTestBase extends TestBase {
	/**
	 * Create a Cola Rate Sheet record.
	 * @return  ColaRateSheet__c : Cloned Cola Rate Sheet Object
	 */
	public static ColaRateSheet__c newColaRateSheet() {
		ColaRateSheet__c rateSheet = new ColaRateSheet__c(
			Name = 'SFDC UT Rate Sheet',
			YearOverYearRate__c = 13.5
		);
		CRUDUtility.insertRecords(rateSheet);
		return rateSheet;
	}

	/**
	 * Creates set of resource roles for Cola Setup.
	 * @return  List<Product2> : List of Resource Roles
	 */
	public static List<Product2> createResourceRoles() {
		Id resourceRoleTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Resource Role');

		List<Product2> resourceRoles = new List<Product2>();
		resourceRoles.add(newProduct('Software Engineer', resourceRoleTypeId));
		resourceRoles.add(newProduct('Project Manager', resourceRoleTypeId));
		resourceRoles.add(newProduct('Configuration Engineer', resourceRoleTypeId));

		CRUDUtility.insertRecords(resourceRoles);
		return resourceRoles;
	}

	/**
	 * Create a Set od Cola Rate records.
	 * @param   Id of the Cola Rate Sheet Record
	 * @param   List<Product2> : List of Cola Rate Sheet Records
	 * @return  List<ColaRate__c> : List of Cola Rates Records
	 */
	public static List<ColaRate__c> createColaRates(
		Id colaRateSheetId,
		List<Product2> resourceRoles
	) {
		Map<String, object> colaRateValues = new Map<String, object>();
		colaRateValues.put('RateSheetId__c', colaRateSheetId);
		colaRateValues.put('Country__c', 'United States');
		colaRateValues.put('State__c', 'Ohio');
		colaRateValues.put('YearOverYearRate__c', 13.5);

		List<ColaRate__c> colaRates = new List<ColaRate__c>();
		for (Product2 resourceRole : resourceRoles) {
			colaRates.add(newColaRate(colaRateValues, resourceRole.Id));
		}

		return (List<ColaRate__c>) CRUDUtility.insertRecords(colaRates);
	}

	/**
	 * Create a cloned Cola Rate Sheet record.
	 * @param   Map<String, Object> of field values for Cola Rate Record
	 * @param   Id of the Cola Rate Sheet Record
	 * @return  String : Id of the Cloned Cola Rate Sheet
	 */
	public static ColaRate__c newColaRate(Map<String, Object> params, Id resourceRoleId) {
		ColaRate__c colaRate = new ColaRate__c(ResourceRoleId__c = resourceRoleId);
		for (String field : params.keySet()) {
			colaRate.put(field, params.get(field));
		}
		return colaRate;
	}
}
