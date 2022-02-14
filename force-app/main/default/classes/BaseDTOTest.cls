/**
 * Created on 10/13/21.
 */

@IsTest
private class BaseDTOTest {
	@IsTest
	static void itShouldReturnTrueForOperationTypeInsert() {
		BaseDTO testBaseDTO = new BaseDTO();
		testBaseDTO.operationType = BaseDTO.OPERATION_TYPE_INSERT;

		Test.startTest();
		System.assertEquals(true, testBaseDTO.isInsert(), 'should return true for insert operation');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnTrueForOperationTypeUpdate() {
		BaseDTO testBaseDTO = new BaseDTO();
		testBaseDTO.operationType = BaseDTO.OPERATION_TYPE_UPDATE;

		Test.startTest();
		System.assertEquals(true, testBaseDTO.isUpdate(), 'should return true for update operation');
		Test.stopTest();
	}

	@IsTest
	static void itShouldReturnTrueForOperationTypeDelete() {
		BaseDTO testBaseDTO = new BaseDTO();
		testBaseDTO.operationType = BaseDTO.OPERATION_TYPE_DELETE;

		Test.startTest();
		System.assertEquals(true, testBaseDTO.isDelete(), 'should return true for insert delete');
		Test.stopTest();
	}
}
