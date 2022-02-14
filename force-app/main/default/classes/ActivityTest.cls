/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */

@IsTest
private class ActivityTest {
	@IsTest
	static void shouldCopyFieldsFromTemplate() {
		ActivityTemplate__c template = new ActivityTemplate__c(
			Name = 'Test',
			Description__c = 'Test',
			Guidance__c = 'Test',
			Sequence__c = 1
		);

		Test.startTest();
		Activity__c activitySO = Activity.newSO(template);
		System.assertEquals(template.Name, activitySO.Name, 'should have the same name');
		System.assertEquals(
			template.Description__c,
			activitySO.Description__c,
			'should have the same description'
		);
		System.assertEquals(
			template.Guidance__c,
			activitySO.Guidance__c,
			'should have the same guidance'
		);
		System.assertEquals(
			template.Sequence__c,
			activitySO.Sequence__c,
			'should have the same sequence'
		);
		Test.stopTest();
	}
}
