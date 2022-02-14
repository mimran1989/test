import { LightningElement, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

import getUsers from '@salesforce/apex/QuoteCollaborationController.getUsers';
import getAvailableQuoteSections from '@salesforce/apex/QuoteCollaborationController.getAvailableQuoteSections';
import submitInvitationForCollaboration from '@salesforce/apex/QuoteCollaborationController.submitInvitationForCollaboration';

// labels
import LABEL_COLLABORATION_INVITE_ERROR from '@salesforce/label/c.CollaborationInviteError';
import LABEL_COLLABORATION_FAILED_TO_INVITE_ERROR from '@salesforce/label/c.CollaborationFailedInviteError';

export default class QuoteCollaboration extends NavigationMixin(LightningElement) {
	@api recordId;
	@track showTotals;
	@track showOtherSections;
	@track showPhases;
	@track showMargin;
	@track showRevenue;

	@track searchKey = '';
	quoteCollaboratorGroupName = 'QuoteCollaborators';

	LABEL_COLLABORATION_INVITE_ERROR = LABEL_COLLABORATION_INVITE_ERROR;

	isInviteEnabled = false;
	closeDialog;
	error;
	render;

	groupUsers = [];
	filteredGroupUsers = [];
	selectedUserIds = [];
	userById = new Map();

	quoteSections = [];
	selectedQuoteSectionIds = [];

	userColumns = [
		{ label: 'Name', fieldName: 'Name', type: 'text' },
		{ label: 'Title', fieldName: 'Title', type: 'text' },
		{ label: 'Email Address', fieldName: 'Email', type: 'text' },
	];

	sectionColumns = [
		{ label: 'Name', fieldName: 'Name', type: 'text' },
	];

	_stateService;

	async connectedCallback() {
		// Users
		const data = await getUsers();

		// copy the groups because the source data is readonly
		this.filteredGroupUsers = data.map((datum) => ({ ...datum }));
		this.filteredGroupUsers.forEach((nextUser) => {
			this.userById.set(nextUser.Id, nextUser);
		});

		// Quote Sections
		const sectionData = await getAvailableQuoteSections({ quoteId: this.recordId });
		this.quoteSections = JSON.parse(sectionData);
	}

	async renderedCallback() {
		this._stateService = this.template.querySelector('c-message-service');
		this._stateService.publish({ key: 'deselect' }); // deselect cells in grid
	}

	clearUserSelections() {
		this.filteredGroupUsers.forEach((nextUser) => {
			const user = nextUser;
			user.selected = false;
		});
	}

	handleSelectedRows(event) {
		const selections = [];
		// Only clear when there is a new selection, otherwise we need these selections
		// to be preserved for persistence between searches.
		if (event.detail.selectedRows.length) {
			this.clearUserSelections();
		}

		event.detail.selectedRows.forEach((nextRow) => {
			selections.push(nextRow.Id);
			this.userById.get(nextRow.Id).selected = true;
		});

		if (selections.length) {
			this.selectedUserIds = selections;
		}

		this.toggleInvite();
	}

	handleSelectedSections(event) {
		const sections = [];
		event.detail.selectedRows.forEach((nextRow) => {
			sections.push(nextRow.Id);
		});
		this.selectedQuoteSectionIds = sections;
		this.toggleInvite();
	}

	handleSearchKeyChange(event) {
		this.searchKey = event.target.value;
	}

	handleCancel() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}

	async submitInvitationToCollaborate() {
		this.error = undefined;

		try {
			await submitInvitationForCollaboration({
				userId: this.selectedUserIds[0],
				quoteId: this.recordId,
				quoteSectionIds: this.selectedQuoteSectionIds,
			});
			this._stateService.publish({ key: 'invite' });
			this.dispatchEvent(new CloseActionScreenEvent());
		} catch (e) {
			this._stateService.notifySingleError(LABEL_COLLABORATION_FAILED_TO_INVITE_ERROR, e);
		}
	}

	get userData() {
		const results = [];
		const selections = [];
		this.filteredGroupUsers.forEach((user) => {
			if (user.selected) {
				selections.push(user.Id);
			}

			if (this.searchKey) {
				if (user.Name.toLowerCase().includes(this.searchKey.toLowerCase())) {
					results.push(user);
				}
			} else {
				results.push(user);
			}
		});

		this.selectedUserIds = selections;
		return results;
	}

	get quoteSectionData() {
		return this.quoteSections;
	}

	toggleInvite() {
		this.isInviteEnabled = !(!this.selectedUserIds.length || !this.selectedQuoteSectionIds.length);
		this.rerender();
	}

	rerender() {
		this.render = Date.now();
	}
}
