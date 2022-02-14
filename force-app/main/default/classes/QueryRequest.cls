/**
 *  Provus Services Quoting
 *  QueryRequest
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class QueryRequest {
	// name of sobject
	public String sObjectName;
	// list of requested fields
	public Set<String> requestedFields;
	// inner queries
	public List<QueryRequest> innerQueries;
	// filter by conditions
	public FilterBy filterBy;
	// order for sobject result set
	public Map<String, String> fieldBySortOrder;
	// limit query string
	public Integer querySize;

	public QueryRequest(String sObjectName) {
		this.sObjectName = sObjectName;
		this.requestedFields = new Set<String>();
		this.innerQueries = new List<QueryRequest>();
		this.fieldBySortOrder = new Map<String, String>();
		this.filterBy = new FilterBy();
	}

	public QueryRequest(Schema.SObjectType sObjectType) {
		this(sObjectType + '');
	}

	private String getInnerQueries() {
		Set<String> queries = new Set<String>();
		for (QueryRequest innerQuery : innerQueries) {
			String qry = innerQuery.getSOQLQuery(true);
			queries.add('(' + qry + ')');
		}
		return String.join(new List<String>(queries), ', ');
	}

	public void setFilterBy(Map<String, String> fieldValues) {
		this.filterBy = new FilterBy(fieldValues);
	}

	public void setFilterBy(Map<String, Set<Id>> fieldValues) {
		this.filterBy = new FilterBy(fieldValues);
	}

	/**
	 * Converts requested fields into a proper string for selecting fields
	 * @return returns string containing select portion of query
	 */
	public String getSelectFields() {
		String selectQry = '';
		for (String field : requestedFields) {
			if (field != SObjectUtility.FIELD_ID && field != SObjectUtility.FIELD_NAME) {
				selectQry += ', ' + field;
			}
		}
		String innerQueryStr = getInnerQueries();
		if (innerQueryStr != '') {
			selectQry += ', ' + innerQueryStr;
		}
		return selectQry;
	}

	/**
	 * Converts fieldsBySortOrder into an order by fields string
	 * @return returns order by clause as string
	 */
	public String getOrderByFields() {
		List<String> orderByFields = new List<String>();
		for (String field : fieldBySortOrder.keySet()) {
			String order = fieldBySortOrder.get(field);
			if (order == SOQLConstants.SORT_DESC) {
				orderByFields.add(field + ' ' + SOQLConstants.SORT_DESC);
			} else {
				orderByFields.add(field + ' ' + SOQLConstants.SORT_ASC);
			}
		}
		String orderBy = null;
		if (!orderByFields.isEmpty()) {
			orderBy = String.join(orderByFields, ', ');
		}
		return orderBy;
	}

	public String getLimitByField() {
		String limitByField = null;
		if (querySize != null) {
			limitByField = ' LIMIT ' + querySize;
		}
		return limitByField;
	}

	public String getSOQLQuery() {
		return getSOQLQuery(false);
	}

	public String getSOQLQuery(Boolean isInnerQuery) {
		String orderByField = this.getOrderByFields();
		String limitByField = this.getLimitByField();
		String qry = 'SELECT ';

		// add standard fields
		qry += SObjectUtility.FIELD_ID;
		qry += ', ' + SObjectUtility.FIELD_NAME;
		// add requested fields
		qry += this.getSelectFields();

		// add sobject name
		qry += ' FROM ' + this.sObjectName;

		// add where clause
		if (this.filterBy.getWhereClause() != null) {
			qry += this.filterBy.getWhereClause();
		}

		if (!isInnerQuery) {
			qry += ' WITH SECURITY_ENFORCED';
		}

		// add sort order
		if (orderByField != null) {
			qry += ' ORDER BY ' + orderByField;
		}

		if (limitByField != null) {
			qry += limitByField;
		}
		return qry;
	}
}
