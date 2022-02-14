/**
 *  Provus Services Quoting
 *  NumericHelper
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class NumericHelper {
	/**
	 * Test if value is not null and not equal to zero
	 *
	 * @param numericValue numeric value to be tested
	 *
	 * @return returns true if value is not zero and non-null
	 */
	public static Boolean isNonZero(Decimal numericValue) {
		return numericValue != null && numericValue != 0;
	}

	/**
	 * get the difference between two numeric values
	 *
	 * @param firstValue first decimal value
	 * @param secondValue second decimal value
	 *
	 * @return returns difference between the two values
	 */
	public static Decimal delta(Decimal firstValue, Decimal secondValue) {
		return nullToZero(firstValue) - nullToZero(secondValue);
	}

	public static Decimal nullToZero(Decimal numericValue) {
		return numericValue == null ? 0 : numericValue;
	}
}
