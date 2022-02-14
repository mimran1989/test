/**
 *  Provus Services Quoting
 *  NumericHelperTest
 *  @2022 Provus Inc. All rights reserved.
 */
@IsTest
private class NumericHelperTest {
	@IsTest
	static void itShouldBeNonZeroForSomePositiveValue() {
		System.assert(NumericHelper.isNonZero(1), 'it should be some non zero value');
	}

	@IsTest
	static void itShouldBeNonZeroForSomeNegativeValue() {
		System.assert(NumericHelper.isNonZero(-1), 'it should be some non zero value');
	}

	@IsTest
	static void itShouldBeZeroForNullValue() {
		System.assert(!NumericHelper.isNonZero(null), 'it is some falsy value');
	}

	@IsTest
	static void itShouldBeZeroForZeroValue() {
		System.assert(!NumericHelper.isNonZero(0), 'it is some falsy value');
	}

	@IsTest
	static void deltaShouldEqualThree() {
		System.assertEquals(3, NumericHelper.delta(6, 3), 'should be three');
	}

	@IsTest
	static void deltaFiveMinusNullShouldEqualFive() {
		System.assertEquals(5, NumericHelper.delta(5, null), 'should be five');
	}

	@IsTest
	static void nullToZeroGivenNullReturnsZero() {
		System.assertEquals(0, NumericHelper.nullToZero(null), 'should be five');
	}

	@IsTest
	static void nullToZeroGivenTenReturnsTen() {
		System.assertEquals(10, NumericHelper.nullToZero(10), 'should be five');
	}
}
