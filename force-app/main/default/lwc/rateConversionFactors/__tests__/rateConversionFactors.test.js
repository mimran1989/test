/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import RateConversionFactors from 'c/rateConversionFactors';

jest.mock('lightning/actions', () => {}, { virtual: true });
// jest.useFakeTimers();

describe('rateConversionFactorsDialog', () => {
	describe('getWholeDigits', () => {
		it('pass in \'5.23\' returns numeric value `5`', async() => {
			const wholeDigits = RateConversionFactors.getWholeDigits('5.23');
			expect(wholeDigits).toEqual(5);
		});

		it('pass in \'5,23\' returns numeric value `5`', async() => {
			const wholeDigits = RateConversionFactors.getWholeDigits('5.23');
			expect(wholeDigits).toEqual(5);
		});

		it('pass in \'1.050,23\' returns numeric value `1050`', async() => {
			const wholeDigits = RateConversionFactors.getWholeDigits('1.050,23');
			expect(wholeDigits).toEqual(1050);
		});

		it('pass in \'1,050.23\' returns numeric value `1050`', async() => {
			const wholeDigits = RateConversionFactors.getWholeDigits('1,050.23');
			expect(wholeDigits).toEqual(1050);
		});

		it('pass in \'\' returns numeric value `null`', async() => {
			const wholeDigits = RateConversionFactors.getWholeDigits('');
			expect(wholeDigits).toEqual(null);
		});
	});
});
