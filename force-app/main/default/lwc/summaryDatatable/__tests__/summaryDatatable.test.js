/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { createElement } from 'lwc';
import SummaryDatatable from 'c/summaryDatatable';

describe('c-summary-datatable', () => {
	let columns;
	let rows;
	beforeEach(() => {
		columns = [
			{ label: 'Test Column 1', fieldName: 'field1', type: 'decimal' },
			{ label: 'Test Column 2', fieldName: 'field2', type: 'percent' },
			{ label: 'Test Column 3', fieldName: 'field3', type: 'currency' },
		];

		rows = [
			{
				rowName: 'Test Row', field1: 'fieldValue1', field2: 'fieldValue2', field3: 'fieldValue3',
			},
		];
	});

	it('should create a td for each of the row columns', async() => {
		// Create element
		const element = createElement('c-summary-datatable', {
			is: SummaryDatatable,
		});

		element.columns = columns;
		element.rows = rows;
		document.body.appendChild(element);
		await Promise.resolve();

		const tdElems = element.shadowRoot.querySelectorAll('td');
		expect(tdElems.length).toEqual(3);
	});
});
