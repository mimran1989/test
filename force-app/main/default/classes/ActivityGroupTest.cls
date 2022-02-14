/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
@IsTest
private class ActivityGroupTest {
	@IsTest
	static void shouldCopyFieldsFromTemplate() {
		ActivityGroupTemplate__c template = new ActivityGroupTemplate__c(
			Name = 'Test',
			Description__c = 'Test',
			Guidance__c = 'Test',
			Sequence__c = 1
		);

		Test.startTest();
		ActivityGroup__c groupSO = ActivityGroup.newSO(template);
		System.assertEquals(template.Name, groupSO.Name, 'should have the same name');
		System.assertEquals(
			template.Description__c,
			groupSO.Description__c,
			'should have the same description'
		);
		System.assertEquals(template.Guidance__c, groupSO.Guidance__c, 'should have the same guidance');
		System.assertEquals(template.Sequence__c, groupSO.Sequence__c, 'should have the same sequence');
		Test.stopTest();
	}
}
