/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
import { loadDiscounts } from '../quoteTotalsSupport';

describe('loadDiscounts', () => {
	it('should update discount amount on grid values when saved type is discount percent', async() => {
		const savedRecord = {};
		savedRecord.CurrentAmount = 1000;
		savedRecord.CurrentMargin = 100;
		savedRecord.CurrentDiscount = 0;
		savedRecord.DiscountAmount = 0;
		savedRecord.DiscountType = 'Discount Percent';
		savedRecord.DiscountPercent = 10;
		savedRecord.NewAmount = 0;
		savedRecord.NewMargin = 0;
		savedRecord.Cost = 500;

		loadDiscounts(savedRecord, 1);
		expect(savedRecord.DiscountPercent).toBe(10);
		expect(savedRecord.DiscountType).toBe('Discount Percent');
		expect(savedRecord.DiscountAmount).toBe('100.00');
		expect(savedRecord.NewMargin).toBe('44.44');
		expect(savedRecord.NewAmount).toBe(900);
	});
	it('should update discount percent on grid values when saved type is discount amount', async() => {
		const savedRecord = {};
		savedRecord.CurrentAmount = 1000;
		savedRecord.CurrentMargin = 100;
		savedRecord.CurrentDiscount = 0;
		savedRecord.DiscountAmount = 100;
		savedRecord.DiscountType = 'Discount Amount';
		savedRecord.DiscountPercent = 0;
		savedRecord.NewAmount = 0;
		savedRecord.NewMargin = 0;
		savedRecord.Cost = 500;

		loadDiscounts(savedRecord, 1);
		expect(savedRecord.DiscountAmount).toBe(100);
		expect(savedRecord.DiscountType).toBe('Discount Amount');
		expect(savedRecord.DiscountPercent).toBe('10.00');
		expect(savedRecord.NewMargin).toBe('44.44');
		expect(savedRecord.NewAmount).toBe(900);
	});
});
