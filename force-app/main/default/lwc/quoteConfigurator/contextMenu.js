/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
/* eslint-disable max-lines-per-function */
import { IFrameCallback } from 'c/util';
import LABEL_ADD_RESOURCE from '@salesforce/label/c.AddResource';
import LABEL_ADD_SECTION from '@salesforce/label/c.AddSection';
import LABEL_EDIT_RESOURCE from '@salesforce/label/c.EditResource';
import LABEL_EDIT_SECTION from '@salesforce/label/c.EditSection';
import LABEL_REMOVE_RESOURCE from '@salesforce/label/c.RemoveResource';
import LABEL_REVOKE_COLLABORATION from '@salesforce/label/c.RevokeCollaboration';
import LABEL_INVITE_TO_COLLABORATE from '@salesforce/label/c.InviteToCollaborate';
import LABEL_CREATE_PHASE from '@salesforce/label/c.CreatePhase';
import LABEL_RENAME_PHASE from '@salesforce/label/c.RenamePhase';
import LABEL_RENAME_ROLE from '@salesforce/label/c.RenameRole';
import LABEL_MAKE_BILLABLE from '@salesforce/label/c.MakeBillable';
import LABEL_MAKE_NON_BILLABLE from '@salesforce/label/c.MakeNonBillable';

export default class ContextMenu {
	constructor(context) {
		this.items = {
			create_section: {
				name: LABEL_ADD_SECTION,
				hidden: IFrameCallback(isAddRowBelowHidden),
				callback: (...args) => context.openNameModal(...args),
				...(context.isCollaborationQuote() || context.disableSections()) && { hidden: () => true },
			},
			row_below: {
				name: LABEL_ADD_RESOURCE,
				hidden: IFrameCallback(isAddRowBelowHidden),
				callback: (...args) => context.handleOpenRoleDialog(...args),
			},
			edit_row: {
				name: LABEL_EDIT_RESOURCE,
				hidden: IFrameCallback(isEditRowHidden),
				callback: (...args) => context.handleOpenRoleDialog(...args),
			},
			remove_row: {
				name: LABEL_REMOVE_RESOURCE,
				hidden: IFrameCallback(isRemoveResourceHidden),
			},
			collaborate: {
				name: LABEL_INVITE_TO_COLLABORATE,
				hidden: IFrameCallback(() => true),
			},
			unfreeze_column: {
				name: 'Unfreeze column',
				hidden: IFrameCallback(() => true), // hidden by default
			},
			create_phase: {
				name: LABEL_CREATE_PHASE,
				disabled: IFrameCallback(isCreatePhaseDisabled),
				hidden: IFrameCallback(isCreatePhaseHidden),
				callback: (...args) => context.openNameModal(...args),
			},
			rename_phase: {
				name: LABEL_RENAME_PHASE,
				disabled: IFrameCallback(isUpdatePhaseDisabled),
				hidden: IFrameCallback(isUpdatePhaseHidden),
				callback: (...args) => context.openNameModal(...args),
			},
			rename_role: {
				name: LABEL_RENAME_ROLE,
				hidden: IFrameCallback(isRenameRoleHidden),
				callback: (...args) => context.openNameModal(...args),
			},
			edit_section: {
				name: LABEL_EDIT_SECTION,
				hidden: IFrameCallback(isRenameSectionHidden),
				callback: (...args) => context.openNameModal(...args),

			},
			revoke_section: {
				name: LABEL_REVOKE_COLLABORATION,
				hidden: IFrameCallback(isRevokeSectionHidden),
				callback: (...args) => context.handleRevoke(...args),
				...context.isCollaborationQuote() && { hidden: () => true },
			},
			toggle_non_billable: {
				name: LABEL_MAKE_NON_BILLABLE,
				hidden: IFrameCallback(rowIsNotBillable),
				callback: (...args) => context.handleToggleBilling(...args),
			},
			toggle_billable: {
				name: LABEL_MAKE_BILLABLE,
				hidden: IFrameCallback(rowIsBillable),
				callback: (...args) => context.handleToggleBilling(...args),
			},
		};
	}
}

function rowIsBillable() {
	let isHidden = true;
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	const toRow = selectedRange.to.row;
	if (fromRow === toRow || fromRow >= 0) {
		const quoteItemSO = this.getSourceDataAtRow(fromRow);
		if (quoteItemSO.isQuoteItem) {
			const nonBillableApiName = Object.keys(quoteItemSO).filter((fieldName) => fieldName.indexOf('NonBillable__c') > -1);
			isHidden = !quoteItemSO[nonBillableApiName];
		}
	}

	return isHidden;
}

function rowIsNotBillable() {
	let isHidden = true;
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	const toRow = selectedRange.to.row;
	if (fromRow === toRow || fromRow >= 0) {
		const quoteItemSO = this.getSourceDataAtRow(fromRow);
		if (quoteItemSO.isQuoteItem) {
			const nonBillableApiName = Object.keys(quoteItemSO).filter((fieldName) => fieldName.indexOf('NonBillable__c') > -1);
			isHidden = quoteItemSO[nonBillableApiName];
		}
	}

	return isHidden;
}

// TODO: need to use this for add resource/section above functionality
// function isAddRowAboveHidden() {
// 	const selectedRange = this.getSelectedRangeLast();
// 	const fromRow = selectedRange.from.row;
// 	if (fromRow !== selectedRange.to.row) {
// 		return true;
// 	}
//
// 	const canPreviousAddBelow = this.getSourceDataAtRow(fromRow - 1)?.canAddRowBelow || (fromRow - 1 < 0);
// 	const canCurrentAddAbove = this.getSourceDataAtRow(fromRow)?.canAddRowAbove;
// 	return (!canPreviousAddBelow || !canCurrentAddAbove);
// }

function isRenameSectionHidden() {
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	const toRow = selectedRange.to.row;
	if (fromRow !== toRow || fromRow < 0) {
		return true;
	}

	let _isSectionHeader = false;
	const cellMeta = this.getCellMeta(fromRow, 0);
	const { isSectionHeader } = cellMeta;
	if (isSectionHeader) {
		_isSectionHeader = true;
	}

	return !_isSectionHeader;
}

function isAddRowBelowHidden() {
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	if (fromRow !== selectedRange.to.row) {
		return true;
	}

	const canCurrentAddBelow = this.getSourceDataAtRow(fromRow)?.canAddRowBelow;
	const canNextAddAbove = this.getSourceDataAtRow(fromRow + 1)?.canAddRowAbove;
	return (!canCurrentAddBelow || !canNextAddAbove);
}

function isCreatePhaseDisabled() {
	const selectedRange = this.getSelectedRangeLast();
	const startColumn = selectedRange.from.col;
	const endColumn = selectedRange.to.col;
	let isDisabled = false;
	const lastRow = this.countRows() - 1;
	if (startColumn < 0) {
		return true;
	}

	for (let i = startColumn; i < endColumn + 1; i++) {
		const { phase, isTotal } = this.getCellMeta(lastRow, i);
		if (isTotal || phase) {
			isDisabled = true;
			break;
		}
	}

	return isDisabled;
}

function isCreatePhaseHidden() {
	const periodColumnOffset = 9;
	const selectedRange = this.getSelectedRangeLast();
	const startColumn = selectedRange.from.col;
	return startColumn < periodColumnOffset;
}

function isRevokeSectionHidden() {
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	const toRow = selectedRange.to.row;
	if (fromRow !== toRow || fromRow < 0) {
		return true;
	}

	return !this.getSourceDataAtRow(fromRow).isRevocable;
}

function isUpdatePhaseDisabled() {
	const selectedRange = this.getSelectedRangeLast();
	const startColumn = selectedRange.from.col;
	const endColumn = selectedRange.to.col;
	const lastRow = this.countRows() - 1;
	if (startColumn < 0) {
		return true;
	}

	const firstColumn = this.getCellMeta(lastRow, startColumn);
	const lastColumn = this.getCellMeta(lastRow, endColumn);
	const firstPhaseId = firstColumn.phase.$id;
	const lastPhaseId = lastColumn.phase.$id;

	return firstPhaseId !== lastPhaseId;
}

function isUpdatePhaseHidden() {
	const periodColumnOffset = 9;
	const selectedRange = this.getSelectedRangeLast();
	const startColumn = selectedRange.from.col;
	const endColumn = selectedRange.to.col;
	let isHidden = true;
	if (startColumn >= periodColumnOffset) {
		isHidden = false;
		const lastRow = this.countRows() - 1;
		const { phase: startPhase } = this.getCellMeta(lastRow, startColumn);
		if (!startPhase) {
			isHidden = true;
		} else {
			for (let i = startColumn + 1; i < endColumn + 1; i++) {
				const { phase } = this.getCellMeta(lastRow, i);
				if (!phase || phase.idx !== startPhase.idx) {
					isHidden = true;
					break;
				}
			}
		}
	}

	return isHidden;
}

function isEditRowHidden() {
	const selectedRange = this.getSelectedRangeLast();
	const fromRow = selectedRange.from.row;
	const toRow = selectedRange.to.row;
	if (fromRow !== toRow) {
		return true;
	}

	for (let i = fromRow; i < toRow + 1; i++) {
		const sourceData = this.getSourceDataAtRow(i);
		if (!sourceData?.isQuoteItem) {
			return true;
		}
	}

	return false;
}

function isRemoveResourceHidden() {
	const selectedRange = this.getSelectedRangeLast();
	let fromRow = selectedRange.from.row;
	let toRow = selectedRange.to.row;
	if (fromRow > toRow) {
		[fromRow, toRow] = [toRow, fromRow];
	}

	for (let i = fromRow; i < toRow + 1; i++) {
		const sourceData = this.getSourceDataAtRow(i);
		if (!sourceData?.isQuoteItem) {
			return true;
		}
	}

	return false;
}

function isRenameRoleHidden() {
	const selectedRange = this.getSelectedRangeLast();
	const isSingleColSelected = selectedRange.from.col === selectedRange.to.col;
	const isSingleRowSelected = selectedRange.from.row === selectedRange.to.row;
	if (selectedRange.from.col < 0 || selectedRange.from.row < 0 || !isSingleColSelected || !isSingleRowSelected) {
		return true;
	}

	const sourceData = this.getSourceDataAtRow(selectedRange.from.row);
	if (!sourceData?.isQuoteItem) {
		return true;
	}

	const cellMeta = this.getCellMeta(selectedRange.from.row, selectedRange.from.col);
	const { isRoleColumn } = cellMeta;
	return !isRoleColumn;
}
