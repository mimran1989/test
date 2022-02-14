/**
 *  Provus Services Quoting
 *  EstimatorTestsBase
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing abstract class EstimatorTestsBase extends TestBase {
	public static final String GUIDANCE = 'sample guidance for test';
	public static final String DESCRIPTION = 'sample description for test';

	public static EstimateTemplate__c newEstimateTemplate() {
		//Estimate Template Configuration Values
		Map<String, String> estimateTemplateValues = new Map<String, String>();
		estimateTemplateValues.put('Guidance__c', GUIDANCE);
		estimateTemplateValues.put('Description__c', DESCRIPTION);
		estimateTemplateValues.put('Name', 'CLM Development Estimate');

		EstimateTemplate__c estimateTemplate = newEstimateTemplate(estimateTemplateValues);

		CRUDUtility.insertRecords(estimateTemplate);
		return estimateTemplate;
	}

	public static List<ActivityGroupTemplate__c> createActivityGroupTemplates(Id estimateTemplateId) {
		//Activity Group Template Configuration Values
		Map<String, String> activityGroupValues = new Map<String, String>();
		activityGroupValues.put('Guidance__c', GUIDANCE);
		activityGroupValues.put('Description__c', DESCRIPTION);
		activityGroupValues.put('EstimateTemplateId__c', (String) estimateTemplateId);

		List<ActivityGroupTemplate__c> activityGroupTemplates = new List<ActivityGroupTemplate__c>();
		ActivityGroupTemplate__c activityGroupTemp1 = newActivityGroupTemplate(
			'Initiation',
			activityGroupValues,
			1
		);
		ActivityGroupTemplate__c activityGroupTemp2 = newActivityGroupTemplate(
			'Design',
			activityGroupValues,
			2
		);
		activityGroupTemplates.add(activityGroupTemp1);
		activityGroupTemplates.add(activityGroupTemp2);

		CRUDUtility.insertRecords(activityGroupTemplates);
		return activityGroupTemplates;
	}

	public static List<ActivityTemplate__c> createActivityTemplates(
		List<ActivityGroupTemplate__c> activityGroupTemplates
	) {
		Map<String, String> activityTemplateValues = new Map<String, String>();
		activityTemplateValues.put('Guidance__c', GUIDANCE);
		activityTemplateValues.put('Description__c', DESCRIPTION);
		activityTemplateValues.put('ActivityGroupTemplateId__c', (String) activityGroupTemplates[0].Id);

		List<ActivityTemplate__c> activityTemplates = new List<ActivityTemplate__c>();
		ActivityTemplate__c activityTemplate1 = newActivityTemplate(
			'Kick-Off',
			activityTemplateValues,
			1
		);
		activityTemplateValues.put('ActivityGroupTemplateId__c', (String) activityGroupTemplates[1].Id);
		ActivityTemplate__c activityTemplate2 = newActivityTemplate(
			'JIRA Setup',
			activityTemplateValues,
			1
		);
		activityTemplates.add(activityTemplate1);
		activityTemplates.add(activityTemplate2);

		CRUDUtility.insertRecords(activityTemplates);
		return activityTemplates;
	}

	public static List<TaskTemplate__c> createTaskTemplates(
		List<ActivityTemplate__c> activityTemplates,
		List<Product2> resourceRoles
	) {
		//Task Template Configuration values
		Map<String, String> taskTemplateValues = new Map<String, String>();
		taskTemplateValues.put('ResourceRoleId__c', (String) resourceRoles[0].Id);
		taskTemplateValues.put('Guidance__c', GUIDANCE);
		taskTemplateValues.put('Description__c', DESCRIPTION);
		taskTemplateValues.put('ActivityTemplateId__c', (String) activityTemplates[0].Id);

		List<TaskTemplate__c> taskTemplates = new List<TaskTemplate__c>();
		TaskTemplate__c taskTemplate1 = newTaskTemplate('Kick-Off', taskTemplateValues, 1);
		taskTemplateValues.put('ActivityTemplateId__c', (String) activityTemplates[1].Id);
		taskTemplateValues.put('ResourceRoleId__c', (String) resourceRoles[1].Id);
		TaskTemplate__c taskTemplate2 = newTaskTemplate('JIRA Process Setup', taskTemplateValues, 1);

		taskTemplates.add(taskTemplate1);
		taskTemplates.add(taskTemplate2);
		CRUDUtility.insertRecords(taskTemplates);
		return taskTemplates;
	}

	public static List<Product2> createResourceRoles() {
		Id resourceRoleTypeId = SObjectUtility.getRecordTypeIdbyName('Product2', 'Resource Role');

		List<Product2> resourceRoles = new List<Product2>();
		resourceRoles.add(newProduct('Software Engineer', resourceRoleTypeId));
		resourceRoles.add(newProduct('Project Manager', resourceRoleTypeId));
		resourceRoles.add(newProduct('Configuration Engineer', resourceRoleTypeId));

		CRUDUtility.insertRecords(resourceRoles);
		return resourceRoles;
	}

	public static EstimateTemplate__c newEstimateTemplate(Map<String, String> fieldValues) {
		EstimateTemplate__c estimateTemplate = new EstimateTemplate__c();
		estimateTemplate.IsActive__c = true;

		for (String field : fieldValues.keySet()) {
			estimateTemplate.put(field, fieldValues.get(field));
		}

		return estimateTemplate;
	}

	public static ActivityGroupTemplate__c newActivityGroupTemplate(
		String activityGroupTemplateName,
		Map<String, String> fieldValues,
		Integer sequence
	) {
		ActivityGroupTemplate__c activityGroupTemplate = new ActivityGroupTemplate__c();
		activityGroupTemplate.IsActive__c = true;
		activityGroupTemplate.Sequence__c = sequence;
		activityGroupTemplate.Name = activityGroupTemplateName;

		for (String field : fieldValues.keySet()) {
			activityGroupTemplate.put(field, fieldValues.get(field));
		}

		return activityGroupTemplate;
	}

	public static ActivityTemplate__c newActivityTemplate(
		String activityTemplateName,
		Map<String, String> fieldValues,
		Integer sequence
	) {
		ActivityTemplate__c activityTemplate = new ActivityTemplate__c();
		activityTemplate.IsActive__c = true;
		activityTemplate.Sequence__c = sequence;
		activityTemplate.Name = activityTemplateName;

		for (String field : fieldValues.keySet()) {
			activityTemplate.put(field, fieldValues.get(field));
		}

		return activityTemplate;
	}

	public static TaskTemplate__c newTaskTemplate(
		String taskTemplateName,
		Map<String, String> fieldValues,
		Integer sequence
	) {
		TaskTemplate__c taskTemplate = new TaskTemplate__c();
		taskTemplate.IsActive__c = true;
		taskTemplate.Sequence__c = sequence;
		taskTemplate.Name = taskTemplateName;

		for (String field : fieldValues.keySet()) {
			taskTemplate.put(field, fieldValues.get(field));
		}

		return taskTemplate;
	}

	public static RateCardItem__c newRateCardItem(
		Map<String, Object> rateCardItemValues,
		Id productId
	) {
		RateCardItem__c rateCardItem = new RateCardItem__c(
			IsActive__c = true,
			ProductId__c = productId
		);
		for (String field : rateCardItemValues.keySet()) {
			rateCardItem.put(field, rateCardItemValues.get(field));
		}

		return rateCardItem;
	}

	public static RateCard__c newRateCardWithItems(List<Product2> resourceRoles) {
		RateCard__c rateCard = newRateCard();
		Map<String, Object> rateCardItemValues = new Map<String, Object>();
		rateCardItemValues.put('RateCardId__c', (String) rateCard.Id);
		//rateCardItemValues.add('ProductId__c', role.Id);
		rateCardItemValues.put('LocationCountry__c', 'United States');
		rateCardItemValues.put('SkillLevel__c', 'L1');
		rateCardItemValues.put('LocationDisplayName__c', 'United States/California');

		List<RateCardItem__c> rateCardItems = new List<RateCardItem__c>();
		for (Product2 role : resourceRoles) {
			rateCardItems.add(newRateCardItem(rateCardItemValues, role.Id));
		}

		rateCardItemValues.put('SkillLevel__c', 'L2');
		for (Product2 role : resourceRoles) {
			rateCardItems.add(newRateCardItem(rateCardItemValues, role.Id));
		}

		if (!rateCardItems.isEmpty()) {
			CRUDUtility.insertRecords(rateCardItems);
		}

		return rateCard;
	}
}
