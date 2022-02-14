/**
 *  Provus Services Quoting
 *  ResourceDefaults
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ResourceDefaults {
	// constants
	public static final String SKILL_LEVEL_FIELD = Schema.RateCardItem__c.SkillLevel__c + '';
	public static final String FIELD_NAME_LOCATION_DISPLAY_NAME =
		Schema.RateCardItem__c.LocationDisplayName__c + '';

	@AuraEnabled
	public static Map<String, ResourceRoleDetail> getResourceRoleData(String estimateTemplateId) {
		Map<String, ResourceRoleDetail> resourceDefaultsByProductId = getResourceRoles(
			estimateTemplateId
		);
		return resourceDefaultsByProductId;
	}

	public static Map<String, ResourceRoleDetail> getResourceRoles(Id estimateTemplateId) {
		Map<String, ResourceRoleDetail> resourceDefaultsByProductId = new Map<String, ResourceRoleDetail>();
		Set<Id> resourceRoleIds = getResourceIds(estimateTemplateId);
		EstimateTemplate__c templateSO = [
			SELECT RateCardId__c
			FROM EstimateTemplate__c
			WHERE Id = :estimateTemplateId
			WITH SECURITY_ENFORCED
		];

		List<RateCardItem__c> rateCardItems = RateCardItemService.getRateCardItems(
			templateSO.RateCardId__c,
			resourceRoleIds
		);

		Map<String, ResourceDefault__c> resourceByProductAttribute = getResourceDefaults(
			estimateTemplateId
		);

		for (RateCardItem__c rateCardItem : rateCardItems) {
			if (!resourceDefaultsByProductId.containsKey(rateCardItem.ProductId__c)) {
				ResourceRoleDetail roleStruct = new ResourceRoleDetail();
				roleStruct.resourceRoleName = rateCardItem.ProductId__r.Name;
				roleStruct.skillLevelByLocation = new Map<String, List<String>>{
					rateCardItem.SkillLevel__c => new List<String>{ rateCardItem.LocationDisplayName__c }
				};

				roleStruct.defaultSkill = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + SKILL_LEVEL_FIELD
					)
					?.TextValue__c;
				roleStruct.defaultLocation = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + FIELD_NAME_LOCATION_DISPLAY_NAME
					)
					?.TextValue__c;
				roleStruct.resourceDefaultSkillId = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + SKILL_LEVEL_FIELD
					)
					?.Id;
				roleStruct.resourceDefaultLocationId = resourceByProductAttribute.get(
						rateCardItem.ProductId__c + FIELD_NAME_LOCATION_DISPLAY_NAME
					)
					?.Id;

				resourceDefaultsByProductId.put(rateCardItem.ProductId__c, roleStruct);
			} else {
				ResourceRoleDetail roleStruct = resourceDefaultsByProductId.get(rateCardItem.ProductId__c);
				if (!roleStruct.skillLevelByLocation.containsKey(rateCardItem.SkillLevel__c)) {
					roleStruct.skillLevelByLocation
						.put(
							rateCardItem.SkillLevel__c,
							new List<String>{ rateCardItem.LocationDisplayName__c }
						);
				} else {
					roleStruct.skillLevelByLocation
						.get(rateCardItem.SkillLevel__c)
						.add(rateCardItem.LocationDisplayName__c);
				}
			}
		}

		return resourceDefaultsByProductId;
	}

	public class ResourceRoleDetail {
		@AuraEnabled
		public String resourceRoleName;
		@AuraEnabled
		public Map<String, List<String>> skillLevelByLocation;
		@AuraEnabled
		public String defaultSkill;
		@AuraEnabled
		public String defaultLocation;
		@AuraEnabled
		public String resourceDefaultSkillId;
		@AuraEnabled
		public String resourceDefaultLocationId;
	}

	private static Map<String, ResourceDefault__c> getResourceDefaults(Id estimateTemplateId) {
		Map<String, ResourceDefault__c> resourceByProductAttribute = new Map<String, ResourceDefault__c>();
		for (ResourceDefault__c resourceDefault : [
			SELECT Id, FieldAPIName__c, TextValue__c, ProductId__c, EstimateId__c, EstimateTemplateId__c
			FROM ResourceDefault__c
			WHERE EstimateTemplateId__c = :estimateTemplateId
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		]) {
			resourceByProductAttribute.put(
				resourceDefault.ProductId__c + resourceDefault.FieldAPIName__c,
				resourceDefault
			);
		}

		return resourceByProductAttribute;
	}

	private static Set<Id> getResourceIds(Id estimateTemplateId) {
		Set<Id> resourceIds = new Set<Id>();

		for (TaskTemplate__c taskTemplate : [
			SELECT Id, ResourceRoleId__c
			FROM TaskTemplate__c
			WHERE
				ActivityTemplateId__r.ActivityGroupTemplateId__r.EstimateTemplateId__c = :estimateTemplateId
			WITH SECURITY_ENFORCED
			LIMIT :SOQLConstants.SOQL_QUERY_LIMIT
		]) {
			resourceIds.add(taskTemplate.ResourceRoleId__c);
		}

		return resourceIds;
	}

	@AuraEnabled
	public static void saveResourceDefaults(String resourceDefaultRecords) {
		List<ResourceDefault__c> resourceDefaults = (List<ResourceDefault__c>) JSON.deserialize(
			resourceDefaultRecords,
			List<ResourceDefault__c>.class
		);

		CRUDUtility.upsertRecords(resourceDefaults);
	}
}
