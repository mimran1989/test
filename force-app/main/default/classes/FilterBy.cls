/**
 *  Provus Services Quoting
 *  FilterBy
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class FilterBy {
	// filter by a specific field name to a value
	public Map<String, String> valueByFieldName;
	// filter by a specific field name to a list of ids
	public Map<String, Set<Id>> valuesByFieldName;
	// boolean operand for how we combine multiple conditions
	public String boolOperand;
	// cache where clause
	private String whereClause;

	public FilterBy() {
		this.valueByFieldName = new Map<String, String>();
		this.valuesByFieldName = new Map<String, Set<Id>>();
		this.whereClause = null;
		this.boolOperand = SOQLConstants.BOOL_OPERATION_AND;
	}

	public FilterBy(Map<String, String> valueByFieldName) {
		this.valueByFieldName = valueByFieldName;
		this.whereClause = null;
		this.boolOperand = SOQLConstants.BOOL_OPERATION_AND;
	}

	public FilterBy(Map<String, Set<Id>> valuesByFieldName) {
		this.valuesByFieldName = valuesByFieldName;
		this.whereClause = null;
		this.boolOperand = SOQLConstants.BOOL_OPERATION_AND;
	}

	/**
	 * Generates where clause given a specific field and value pair
	 * @return list of where clause conditions
	 */
	private List<String> getWhereClauseWithValue() {
		List<String> conditions = new List<String>();
		for (String fieldName : this.valueByFieldName.keySet()) {
			String fieldValue = this.valueByFieldName.get(fieldName);
			String safeFieldValue = fieldValue;
			if (safeFieldValue != null) {
				safeFieldValue = String.escapeSingleQuotes(this.valueByFieldName.get(fieldName));
			}

			String condition = fieldName + ' = ';
			if (safeFieldValue != null) {
				condition += '\'' + safeFieldValue + '\'';
			} else {
				condition += 'NULL';
			}

			conditions.add(condition);
		}
		return conditions;
	}

	/**
	 * Generates where clause given a specific field and set pair
	 * @return returns where clause conditions
	 */
	private List<String> getWhereClauseWithSet() {
		List<String> conditions = new List<String>();
		for (String fieldName : this.valuesByFieldName.keySet()) {
			List<Id> idsForField = new List<Id>(this.valuesByFieldName.get(fieldName));
			String condition = fieldName + ' IN (\'' + String.join(idsForField, '\', \'') + '\')';
			conditions.add(condition);
		}
		return conditions;
	}

	/**
	 * Retrieves where clause without needing to know context of what
	 * type of data is being used for where clause
	 * @return returns where clause string
	 */
	public String getWhereClause() {
		if (this.whereClause == null) {
			List<String> conditions = new List<String>();
			if (this.valueByFieldName != null) {
				conditions = getWhereClauseWithValue();
			} else if (this.valuesByFieldName != null) {
				conditions = getWhereClauseWithSet();
			}
			if (!SystemUtility.nullOrEmpty(conditions)) {
				this.whereClause = ' WHERE ' + String.join(conditions, ' ' + this.boolOperand + ' ');
			}
		}
		return this.whereClause;
	}
}
