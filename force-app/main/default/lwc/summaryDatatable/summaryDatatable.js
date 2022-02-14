/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { LightningElement, api } from 'lwc';

export default class SummaryDatatable extends LightningElement {
	static NUMBER_TYPES = ['decimal', 'currency', 'percent'];
	@api columns;
	baseRows = [];

	@api
	get rows() {
		const component = this;
		const formattedRows = [];
		component.baseRows.forEach((nextRow) => {
			const row = { ...nextRow };
			row.columns = [];
			component.columns.forEach((nextColumn) => {
				row.columns.push({
					name: `${row.rowName} - ${nextColumn.label}`,
					value: row[nextColumn.fieldName],
					type: nextColumn.type,
					isNumber: SummaryDatatable.NUMBER_TYPES.includes(nextColumn.type),
				});
			});
			formattedRows.push(row);
		});

		return formattedRows;
	}

	set rows(value) {
		this.baseRows = value;
	}
}
