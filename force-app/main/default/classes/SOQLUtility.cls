/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class SOQLUtility {
	/**
	 * Get results for requested sObject fields with where clause
	 *
	 * @param queryRequest query request object with SOQL query details
	 *
	 * @return requested SObjects
	 */
	public static List<SObject> querySObject(QueryRequest queryRequest) {
		// query conditions are escaped on line ~40 (FilterBy inner class)
		return Database.query(queryRequest.getSOQLQuery()); //NOPMD
	}
}
