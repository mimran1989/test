/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing class ActivityGroupService {
	public static List<ActivityGroup__c> getApplicableGroups(Id estimateId) {
		return [
			SELECT
				Id,
				Name,
				Sequence__c,
				(
					SELECT Id, ResourceRoleId__c, TotalEstimatedDuration__c
					FROM RoleSummaries__r
					WHERE TotalEstimatedDuration__c > 0
				)
			FROM ActivityGroup__c
			WHERE EstimateId__c = :estimateId AND IsNotApplicable__c = FALSE
			WITH SECURITY_ENFORCED
			ORDER BY Sequence__c
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		];
	}
}
