/**
 * @description       : This is a test class for CustomLookupController
 * @author            : Vikrant kumar
 * @group             :
 * @last modified on  : 08-25-2021
 * @last modified by  : Vikrant kumar
 **/
@IsTest
private class CustomLookupControllerTest extends TestBase {
	static final String SERVICE_PRODUCT_PRACTICE = 'Architect';
	static final String SERVICE_PRODUCT_GROUP = 'Software';
	//Below is a method with @testsetup annotation, the name can be anything like setup(), oneTimeData(), etc.
	@TestSetup
	static void setup() {
		RateCard__c rateCard = newRateCard();
		rateCard.Name = 'RateCard';
		CRUDUtility.updateRecords(rateCard);
		RateCard__c rateCard2 = newRateCard();
		rateCard2.Name = 'RateCard2';
		CRUDUtility.updateRecords(rateCard2);
		Map<String, RecordTypeInfo> describeRecordInfos = Schema.SObjectType.Product2.getRecordTypeInfosByName();
		Id recordTypeId = describeRecordInfos.get('Resource Role').getRecordTypeId();
		Id servicePrdTypeId = describeRecordInfos.get('Service').getRecordTypeId();
		Product2 architectProduct = TestDataFactory.createResource('Architect', servicePrdTypeId);
		architectProduct.Practice__c = SERVICE_PRODUCT_PRACTICE;
		architectProduct.Group__c = SERVICE_PRODUCT_GROUP;
		List<Product2> prdLst = new List<Product2>{
			TestDataFactory.createResource('Software Engineer', recordTypeId),
			TestDataFactory.createResource('Project Manager', recordTypeId),
			architectProduct
		};
		CRUDUtility.insertRecords(prdLst);
		RateCardItem__c rateCardItem = new RateCardItem__c();
		rateCardItem.RateCardId__c = rateCard.Id;
		rateCardItem.ProductId__c = prdLst[0].Id;
		CRUDUtility.insertRecords(rateCardItem);
		RateCardItem__c rateCardItem2 = new RateCardItem__c();
		rateCardItem2.RateCardId__c = rateCard2.Id;
		rateCardItem2.ProductId__c = prdLst[2].Id;
		CRUDUtility.insertRecords(rateCardItem2);
		Estimate__c est = TestDataFactory.createEstimate('CLMEstimate', true);
		CRUDUtility.insertRecords(est);
		ActivityGroup__c ag = TestDataFactory.createActivityGroup('AcitivityGroup');
		ag.EstimateId__c = est.Id;
		CRUDUtility.insertRecords(ag);
		Activity__c act = TestDataFactory.createActivity(ag.Id);
		CRUDUtility.insertRecords(act);
	}

	@IsTest
	static void testMethod1() {
		Map<String, String> paramMap = new Map<String, String>{
			'objectName' => 'Product2',
			'filterField' => 'Name',
			'searchString' => 'Software',
			'value' => 'Test',
			'hierarchylevel' => 'Task',
			'hierarchylevelId' => [SELECT Id FROM Estimate__c LIMIT 1]
			.Id,
			'rateCard' => [SELECT Id FROM RateCard__c LIMIT 1]
			.Id
		};

		CustomLookupController.fetchRecords(paramMap);

		paramMap.put('searchString', 'Software Engineer');
		paramMap.put('hierarchylevel', 'Estimate');
		CustomLookupController.fetchRecords(paramMap);

		SObject obj = CustomLookupController.fetchDefaultRecord(
			[SELECT Id FROM RateCard__c LIMIT 1]
			.Id,
			'RateCard__c'
		);
		System.assertEquals('RateCard', String.valueOf(obj.get('Name')), 'Success');
	}

	@IsTest
	static void fetchRecordsFilterCriteriaForNonExistingPracticeTypeExpectEmptyRecordResult() {
		Map<String, String> paramMap = new Map<String, String>{
			'objectName' => 'Product2',
			'filterField' => 'Name',
			'filterCriteria' => 'ProductId__r.Practice__c = \'Architype\'', // no records with practice architype exist
			'searchString' => 'Architect',
			'value' => 'Test',
			'hierarchylevel' => 'Task',
			'rateCard' => [SELECT Id FROM RateCard__c WHERE Name = 'RateCard2' LIMIT 1]
			.Id
		};

		List<CustomLookupController.RecordsData> emptyRecordsData = new List<CustomLookupController.RecordsData>();
		List<CustomLookupController.RecordsData> recordsData = CustomLookupController.fetchRecords(
			paramMap
		);
		System.assertEquals(
			emptyRecordsData,
			recordsData,
			'expect records data to not exist and equal null'
		);
	}

	@IsTest
	static void fetchRecordsFilterCriteriaForExistingPracticeTypeExpectRecord() {
		Map<String, String> paramMap = new Map<String, String>{
			'objectName' => 'Product2',
			'filterField' => 'Name',
			'filterCriteria' => 'ProductId__r.Practice__c = \'' +
			SERVICE_PRODUCT_PRACTICE +
			'\'', // records exists with practice Architect
			'searchString' => 'Architect',
			'value' => 'Test',
			'hierarchylevel' => 'Task',
			'rateCard' => [SELECT Id FROM RateCard__c WHERE Name = 'RateCard2' LIMIT 1]
			.Id
		};

		List<CustomLookupController.RecordsData> recordsData = CustomLookupController.fetchRecords(
			paramMap
		);
		System.assertEquals(1, recordsData.size(), 'expect records data to return one result');
		System.assertEquals(
			'Architect',
			recordsData[0].label,
			'expect the dropdown entry label to be \'Architect\''
		);
	}
}
