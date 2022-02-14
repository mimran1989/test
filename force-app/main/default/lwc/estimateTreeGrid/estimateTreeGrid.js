import {
	LightningElement, track, wire, api,
} from 'lwc';
import fetchRecords from '@salesforce/apex/EstimateTreeController.getRecords';
import getTaskDetails from '@salesforce/apex/EstimateTreeController.getTaskDetails';
import updateTask from '@salesforce/apex/EstimateTreeController.updateTask';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/sparkUtils';
import createSummaryRecords from '@salesforce/apex/EstimateTreeController.createSummaryRecords';
import getSourceSummary from '@salesforce/apex/EstimateTreeController.getSourceSummary';
import getRoleSummary from '@salesforce/apex/EstimateTreeController.getSummaryRecords';
import updateNotApplicableField from '@salesforce/apex/EstimateTreeController.updateNotApplicableField';

import ESTIMATENAME_FIELD from '@salesforce/schema/Estimate__c.Name';
import RESOURCEROLE_FIELD from '@salesforce/schema/TaskRoleSummary__c.ResourceRole__c';
import RESOURCE_ROLE_ID_FIELD from '@salesforce/schema/TaskRoleSummary__c.ResourceRoleId__c';
import TOTALCALCULATEDURATION_FIELD from '@salesforce/schema/TaskRoleSummary__c.TotalCalculatedDuration__c';
import TOTALADJUSTMENT_FIELD from '@salesforce/schema/TaskRoleSummary__c.TotalAdjustments__c';
import LEVELADJUSTMENT_FIELD from '@salesforce/schema/TaskRoleSummary__c.LevelAdjustment__c';
import TOTALESTIMATEDDURATION_FIELD from '@salesforce/schema/TaskRoleSummary__c.TotalEstimatedDuration__c';
import ACTIVITYID_FIELD from '@salesforce/schema/TaskRoleSummary__c.ActivityId__c';
import ACTIVITYGROUPID_FIELD from '@salesforce/schema/TaskRoleSummary__c.ActivityGroupId__c';
import ESTIMATEID_FIELD from '@salesforce/schema/TaskRoleSummary__c.EstimateId__c';

import PER_UNIT_DURATION_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.PerUnitDuration__c';
import FROM_VALUE_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.FromValue__c';
import TO_VALUE_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.ToValue__c';
import BOOLEANVALUE_FIELD from '@salesforce/schema/TaskParameterValue__c.BooleanValue__c';
import INTEGERVALUE_FIELD from '@salesforce/schema/TaskParameterValue__c.IntegerValue__c';
import TEXTVALUE_FIELD from '@salesforce/schema/TaskParameterValue__c.TextValue__c';
import TASK_PARAMETER_VALUE_TEMPLATE_OBJECT from '@salesforce/schema/TaskParameterValueTemplate__c';

import ESTIMATEEDDURATION_FIELD from '@salesforce/schema/Task__c.EstimatedDuration__c';
import CALCULATEDDURATION_FIELD from '@salesforce/schema/Task__c.CalculatedDuration__c';
import ADJUSTMENTREASON_FIELD from '@salesforce/schema/Task__c.AdjustmentReason__c';
import ISNOTAPPLICABLE_FIELD from '@salesforce/schema/Task__c.IsNotApplicable__c';

import TASKPARAM_TASKID_NAME_FIELD from '@salesforce/schema/TaskParameterValue__c.TaskId__r.Name';
import TASKPARAM_TASKID_ACTIVITY_NAME_FIELD from '@salesforce/schema/TaskParameterValue__c.TaskId__r.ActivityId__r.Name';
import TASKPARAM_TASKID_ACTIVITYGROUP_NAME_FIELD from '@salesforce/schema/TaskParameterValue__c.TaskId__r.ActivityId__r.ActivityGroupId__r.Name';
import TASKPARAM_TEMPLATE_NAME_FIELD from '@salesforce/schema/TaskParameterValue__c.TemplateId__r.Name';
import TASKPARAM_TEMPLATE_DATATYPE_FIELD from '@salesforce/schema/TaskParameterValue__c.TemplateId__r.DataType__c';
import TASK_NOTAPPPLICABLE_FIELD from '@salesforce/schema/TaskParameterValue__c.TaskId__r.IsNotApplicable__c';
import TASK_ESTIMATEEDDURATION_FIELD from '@salesforce/schema/TaskParameterValue__c.TaskId__r.EstimatedDuration__c';

import LABEL_ADD_RESOURCE from '@salesforce/label/c.AddResource';
import LABEL_CANCEL from '@salesforce/label/c.CancelButton';
import LABEL_CLOSE from '@salesforce/label/c.CloseButton';
import LABEL_DURATION_NOTIFICATION_MESSAGE from '@salesforce/label/c.DurationNotificationMessage';
import LABEL_LEVEL_ADJUSTMENT from '@salesforce/label/c.LevelAdjustment';
import LABEL_REQUIRED_FIELDS_MISSING_NOTIFICATION_MESSAGE from '@salesforce/label/c.RequiredFieldsMissingNotificationMessage';
import LABEL_RESOURCE from '@salesforce/label/c.Resource';
import LABEL_RESOURCE_NOTIFICATION_MESSAGE from '@salesforce/label/c.ResourceNotificationMessage';
import LABEL_ROLLED_UP_ADJUSTMENTS from '@salesforce/label/c.RolledUpAdjustments';
import LABEL_ROLLED_UP_CALCULATED_DURATION from '@salesforce/label/c.RolledUpCalculatedDuration';
import LABEL_ROLLED_UP_ESTIMATED_DURATION from '@salesforce/label/c.RolledUpEstimatedDuration';
import LABEL_SAVE from '@salesforce/label/c.SaveButton';

const FIELDS = [
	ESTIMATENAME_FIELD,
];

export default class EstimateTreeGrid extends LightningElement {
	@api recordId;
	@track openModal = false;
	@track taskDetails;
	@track taskFieldDef;
	@track taskforUpdate;
	@track estimatedTaskCost = 0;
	@track estimatedTaskDuration = 0;
	@track taskrole;
	@track gridExpandedRows;
	@track phasesList = [];
	@track openResourceSummary = false;
	@track resourceSummary = [];
	@track resourceSummaryExists = false;
	@track gridColumns = [];
	@track gridData;
	@track gridDataMain;
	@track loadedData;
	@track taskparamrecs;
	@track adjustedTaskDuration = 0;
	@track taskRow;
	@track openEstimateResourceSummary = false;
	@track data;
	@track draftValues = [];
	@track suppress = false;
	@track addResourcePanel = false;
	@track newAdjustedAmount = 0;
	@track selectedRecord;
	@track showTskWizard = false;
	@track sortBy = [];
	@track sortDirection = [];
	error;
	showSource = false;
	sourceData;
	sourceColumns = [];
	integerTierParameterColumns = [];
	fieldLabels = {};

	Label = {
		ADD_RESOURCE: LABEL_ADD_RESOURCE,
		CLOSE: LABEL_CLOSE,
		LEVEL_ADJUSTMENT: LABEL_LEVEL_ADJUSTMENT,
		CANCEL: LABEL_CANCEL,
		SAVE: LABEL_SAVE,
	}

	isEstimate = false;
	istreegridload = true;
	@track columns = [
		{
			label: LABEL_RESOURCE, fieldName: RESOURCEROLE_FIELD.fieldApiName, type: 'text', editable: false, sortable: 'true',
		},
		{
			label: LABEL_ROLLED_UP_CALCULATED_DURATION, fieldName: TOTALCALCULATEDURATION_FIELD.fieldApiName, type: 'number', editable: false,
		},
		{
			label: LABEL_ROLLED_UP_ADJUSTMENTS, fieldName: TOTALADJUSTMENT_FIELD.fieldApiName, type: 'number', editable: false, sortable: 'true',
		},
		{
			label: LABEL_LEVEL_ADJUSTMENT, fieldName: LEVELADJUSTMENT_FIELD.fieldApiName, type: 'number', editable: true,
		},
		{
			label: LABEL_ROLLED_UP_ESTIMATED_DURATION, fieldName: TOTALESTIMATEDDURATION_FIELD.fieldApiName, type: 'number', editable: false, sortable: 'true',
		},
	];
	// Get Estimate record details..
	@wire(getRecord, { recordId: '$recordId', fields: FIELDS })
	estimate;
	// Get Estimate record name...
	get estimateName() {
		return this.estimate.data.fields.Name.value;
	}
	// This method is to fetch the treegrid..
	@wire(fetchRecords, { estimateId: '$recordId' })
	TreeData(result) {
		const { error, data } = result;
		this.loadedData = result;

		if (data) {
			if (data.length > 0) {
				this.gridExpandedRows = data[0].gridExpandedIds;
				this.loadColumns();
				this.istreegridload = false;
			}

			this.gridDataMain = data;
			this.gridData = data;
		} else {
			this.toastError(error);
		}
	}

	@wire(getObjectInfo, { objectApiName: TASK_PARAMETER_VALUE_TEMPLATE_OBJECT })
	taskParamTemplateInfo({ data }) {
		if (data) {
			this.integerTierParameterColumns = [
				{
					label: data.fields[FROM_VALUE_FIELD.fieldApiName].label, fieldName: FROM_VALUE_FIELD.fieldApiName, type: 'text',
				},
				{
					label: data.fields[TO_VALUE_FIELD.fieldApiName].label, fieldName: TO_VALUE_FIELD.fieldApiName, type: 'text',
				},
				{
					label: 'Multiplier', fieldName: PER_UNIT_DURATION_FIELD.fieldApiName, type: 'text',
				},
			];
		}
	}

	// This method is used for inline edit save at the resource level summary..
	handleSave(event) {
		this.suppress = true;

		const recordInputs = event.detail.draftValues.slice().map((draft) => {
			const fields = { ...draft };
			return { fields };
		});

		const promises = recordInputs.map((recordInput) => updateRecord(recordInput));
		Promise.all(promises).then(() => {
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Success',
					message: LABEL_DURATION_NOTIFICATION_MESSAGE,
					variant: 'success',
				}),
			);

			if (!this.isEstimate) {
				this.showResourceMethod(this.taskDetails);
				this.suppress = true;
			} else {
				getRoleSummary({ recordId: this.recordId, type: 'Estimate' })
					.then((result) => {
						this.data = result;
						this.resourceSummaryExists = result.length > 0;
					})
					.catch((e) => {
						this.toastError(e);
						this.contacts = undefined;
					});
			}

			return refreshApex(this.loadedData);
		}).catch((e) => {
			this.toastError(e);
		});
	}
	handleCellChange() {
		this.suppress = false;
	}
	addResource() {
		this.addResourcePanel = true;
		this.newAdjustedAmount = 0;
	}

	updateNewResourceAdjst(event) {
		this.newAdjustedAmount = event.target.value;
	}

	// eslint-disable-next-line max-lines-per-function
	loadColumns() {
		this.createScopeSummaryColumns();
		this.gridColumns = [
			{
				type: 'text',
				fieldName: 'ActivityGroup',
				label: 'Activity Group / Activity / Task',
				cellAttributes: { iconName: { fieldName: 'IconType' } },
				initialWidth: 400,
			},
			{
				type: 'boolean',
				fieldName: 'NotApplicable',
				label: 'N/A',
				initialWidth: 50,
				editable: true,

			},
			{
				type: 'text',
				fieldName: 'CalculatedDuration',
				label: 'Rolled-up Calculated Duration',
				cellAttributes: { alignment: 'center' },
			},
			{
				type: 'text',
				fieldName: 'AdjustedDuration',
				label: 'Rolled-Up Duration Adjustment',
				cellAttributes: { alignment: 'center' },
			},
			{
				type: 'text',
				fieldName: 'levelAdjustments',
				label: 'Level Adjustments',
				cellAttributes: { alignment: 'center' },
			},
			{
				type: 'text',
				fieldName: 'EstimatedDuration',
				label: 'Estimated Duration',
				hideDefaultActions: 'true',
				cellAttributes: { iconName: { fieldName: 'NotTouched' }, iconPosition: 'right', alignment: 'center' },
			},
			{
				type: 'text',
				fieldName: 'Resourcerole',
				label: 'Resource Role',
				wrapText: true,
			},
			{
				label: '',
				type: 'button',
				initialWidth: 75,
				typeAttributes: {
					iconName: { fieldName: 'ActionIcon' },
					title: { fieldName: 'ActionbuttonTitle' },
					variant: 'border-filled',
					disabled: {
						fieldName: 'ActionIconDisabled',
					},
				},
			},
		];
	}
	// Initialize Scope Summary Columns
	createScopeSummaryColumns() {
		this.sourceColumns = [];
		const types = ['text', 'boolean'];
		const fieldNames = ['ActivityGroup', 'Activity', 'Taskname', 'NotApplicable', 'Taskparams', 'UserInput', 'TaskEstimatedDuration'];
		const labels = ['Activity Group', 'Activity', 'Task', 'N/A', 'Parameter Name', 'User Input', 'Estimated Duration'];
		let fieldNameIns;
		for (fieldNameIns = 0; fieldNameIns < fieldNames.length; fieldNameIns++) {
			const varIns = {
				type: fieldNames[fieldNameIns] === 'NotApplicable' ? types[1] : types[0],
				fieldName: fieldNames[fieldNameIns],
				label: labels[fieldNameIns],
				sortable: 'true',
				initialWidth: fieldNames[fieldNameIns] === 'NotApplicable' ? 50 : 0,
			};

			this.sourceColumns.push(varIns);
		}
	}
	// This function is used to collapse and expand the tree based on the user selection..
	showAG() {
		const grid = this.template.querySelector('lightning-tree-grid');
		grid.collapseAll();
	}
	// This function is used to collapse and expand the tree based on the user selection..
	showActivity() {
		const actGrp = [];
		this.gridData.forEach((def) => {
			if (def.Type === 'ActivityGroup') {
				actGrp.push(def.ActivityGroupId);
			}
		});
		this.gridExpandedRows = actGrp;
	}
	// This function is used to collapse and expand the tree based on the user selection..
	showTasks() {
		const grid = this.template.querySelector('lightning-tree-grid');
		grid.expandAll();
	}
	// Invokes the Resource Summary Page at the Estimate level..
	async showEstimateResourceSummary() {
		this.data = [];
		this.isEstimate = true;
		this.addResourcePanel = false;
		this.suppress = false;
		this.openEstimateResourceSummary = true;
		this.newAdjustedAmount = 0;
		this.addResourcePanel = false;
		const result = await getRoleSummary({ recordId: this.recordId, type: 'Estimate' });
		if (result) {
			this.data = result;
			this.resourceSummaryExists = result.length > 0;
		}
	}
	// Row level actions for the lightning tree grid..
	handleRowAction(event) {
		const { row } = event.detail;
		switch (row.Type) {
			case 'ActivityGroup':
				this.showResourceMethod(row);
				break;
			case 'Activity':
				this.showResourceMethod(row);
				break;
			case 'Task':
				this.showTaskDetails(row);
				break;
			default:
		}
	}
	// This fucntion is called when Resource summary button is clicked at the Activity group and activity level..
	async showResourceMethod(row) {
		this.data = [];
		this.isEstimate = false;
		this.suppress = true;
		this.addResourcePanel = false;
		this.taskDetails = row;
		this.openResourceSummary = true;
		const result = await getRoleSummary({ recordId: row.ActivityGroupId, type: row.Type });
		if (result) {
			this.data = result;
			this.resourceSummaryExists = result.length > 0;
		}
	}
	// This function is called when Edit Task is invoked from the task level..
	async showTaskDetails(row) {
		this.taskDetails = row;
		this.estimatedTaskDuration = row.EstimatedDuration;
		this.adjustedTaskDuration = row.AdjustedDuration;
		this.taskrole = row.Resourcerole;

		const result = await getTaskDetails({ taskId: row.ActivityGroupId });
		if (result) {
			this.taskFieldDef = result.TaskParams;
			this.taskDetails = result.TaskDetails;
			this.openModal = true;
		}
	}

	async showSourceSummary() {
		this.sourceData = [];
		const result = await getSourceSummary({ estimateId: this.recordId });
		if (result) {
			result.forEach((ele) => {
				const rec = {};

				rec.Taskname = this.getPropByString(ele, TASKPARAM_TASKID_NAME_FIELD.fieldApiName);
				rec.Id = ele.Id;
				rec.ActivityGroup = this.getPropByString(ele, TASKPARAM_TASKID_ACTIVITYGROUP_NAME_FIELD.fieldApiName);
				rec.Activity = this.getPropByString(ele, TASKPARAM_TASKID_ACTIVITY_NAME_FIELD.fieldApiName);
				rec.Taskparams = this.getPropByString(ele, TASKPARAM_TEMPLATE_NAME_FIELD.fieldApiName);
				rec.TaskEstimatedDuration = this.getPropByString(ele, TASK_ESTIMATEEDDURATION_FIELD.fieldApiName);

				if (this.getPropByString(ele, TASKPARAM_TEMPLATE_DATATYPE_FIELD.fieldApiName) === 'Integer'
				|| this.getPropByString(ele, TASKPARAM_TEMPLATE_DATATYPE_FIELD.fieldApiName) === 'Integer Tiers') {
					rec.UserInput = this.getPropByString(ele, INTEGERVALUE_FIELD.fieldApiName);
				} else if (this.getPropByString(ele, TASKPARAM_TEMPLATE_DATATYPE_FIELD.fieldApiName) === 'Checkbox') {
					rec.UserInput = this.getPropByString(ele, BOOLEANVALUE_FIELD.fieldApiName) ? 'Yes' : 'No';
				} else if (this.getPropByString(ele, TASKPARAM_TEMPLATE_DATATYPE_FIELD.fieldApiName) === 'Picklist') {
					rec.UserInput = this.getPropByString(ele, TEXTVALUE_FIELD.fieldApiName);
				}

				rec.NotApplicable = this.getPropByString(ele, TASK_NOTAPPPLICABLE_FIELD.fieldApiName);
				this.sourceData.push(rec);
			});
			this.showSource = true;
		}
	}
	// To handle event for SourceSummaryData
	handleSortSourceSummaryData(event) {
		const sortByValue = event.detail.fieldName;
		const sortDirectionValue = event.detail.sortDirection;
		this.sortBy = sortByValue;
		this.sortDirection = sortDirectionValue;
		const parseData = JSON.parse(JSON.stringify(this.sourceData));
		this.sortSummaryData(this.sortBy, this.sortDirection, parseData);
	}
	// To handle event for ResourceSummaryData
	handleResourceSummaryData(event) {
		const sortByValue = event.detail.fieldName;
		const sortDirectionValue = event.detail.sortDirection;
		this.sortBy = sortByValue;
		this.sortDirection = sortDirectionValue;
		const parseData = JSON.parse(JSON.stringify(this.data));
		this.sortSummaryData(this.sortBy, this.sortDirection, parseData);
	}
	// Sorting the columns of sourcesummary and resourcesummary by ascending and descending order
	sortSummaryData(fieldname, direction, parseData) {
		const keyValue = (keyVal) => {
			const value = keyVal[fieldname];
			return typeof value === 'string' ? value.toUpperCase() : value;
		};

		const isReverse = direction === 'asc' ? 1 : -1;
		parseData.sort((firstVal, lastVal) => {
			let firstValue = firstVal;
			let lastValue = lastVal;
			firstValue = keyValue(firstValue) ? keyValue(firstValue) : '';
			lastValue = keyValue(lastValue) ? keyValue(lastValue) : '';
			return isReverse * ((firstValue > lastValue) - (lastValue > firstValue));
		});
		this.sourceData = parseData;
		this.data = parseData;
	}
	// eslint-disable-next-line class-methods-use-this
	getPropByString(obj, propString) {
		if (!propString) {
			return obj;
		}

		let prop;
		let i;
		const props = propString.split('.');
		for (i = 0; i < props.length - 1; i++) {
			prop = props[i];

			const candidate = obj[prop];
			if (candidate !== undefined) {
				// eslint-disable-next-line no-param-reassign
				obj = candidate;
			} else {
				break;
			}
		}

		return obj[props[i]];
	}

	async getPreviousSaveTask() {
		await updateTask({ tsk: this.buildTaskRecord(), taskParams: this.taskparamrecs });
		refreshApex(this.loadedData);
		getRecordNotifyChange([{ recordId: this.recordId }]);
		this.adjustedTaskDuration = 0;
		const result = await getTaskDetails({ taskId: this.taskDetails.beforeTaskId });
		if (result) {
			this.resetTaskDetails(result);
		}
	}

	async getnextSaveTask() {
		const response = updateTask({ tsk: this.buildTaskRecord(), taskParams: this.taskparamrecs });
		if (response) {
			refreshApex(this.loadedData);
			getRecordNotifyChange([{ recordId: this.recordId }]);
			this.adjustedTaskDuration = 0;
			const result = await getTaskDetails({ taskId: this.taskDetails.afterTaskId });
			if (result) {
				this.resetTaskDetails(result);
			}
		}
	}

	resetTaskDetails(result) {
		this.taskFieldDef = result.TaskParams;
		this.taskDetails = result.TaskDetails;
		this.estimatedTaskDuration = this.taskDetails.EstimatedDuration;
		this.adjustedTaskDuration = this.taskDetails.AdjustedDuration;
		this.taskrole = this.taskDetails.Resourcerole;
		this.openModal = true;
	}

	buildTaskRecord() {
		const taskrec = {};
		taskrec.Id = this.taskDetails.ActivityGroupId;
		taskrec[LEVELADJUSTMENT_FIELD.fieldApiName] = this.taskDetails.AdjustedDuration;
		taskrec[CALCULATEDDURATION_FIELD.fieldApiName] = this.taskDetails.CalculatedDuration;
		taskrec[ADJUSTMENTREASON_FIELD.fieldApiName] = this.taskDetails.AdjustmentReason;
		taskrec[ISNOTAPPLICABLE_FIELD.fieldApiName] = this.taskDetails.NotApplicable;
		taskrec[ESTIMATEEDDURATION_FIELD.fieldApiName] = +this.taskDetails.CalculatedDuration + +this.taskDetails.AdjustedDuration;

		if (this.taskDetails.NotApplicable) {
			taskrec[LEVELADJUSTMENT_FIELD.fieldApiName] = 0;
			taskrec[CALCULATEDDURATION_FIELD.fieldApiName] = 0;
			taskrec[ADJUSTMENTREASON_FIELD.fieldApiName] = '';
			taskrec[ESTIMATEEDDURATION_FIELD.fieldApiName] = 0;
		}

		return taskrec;
	}

	closeResourceModal() {
		this.addResourcePanel = false;
	}
	// Method to capture the resourceId selected in the Lookup component..
	SelectedResource(event) {
		this.selectedRecord = event.detail.recordId;
	}

	showValidationMessage() {
		const event = new ShowToastEvent({
			title: LABEL_REQUIRED_FIELDS_MISSING_NOTIFICATION_MESSAGE,
			variant: 'error',
			mode: 'dismissable',
		});

		this.dispatchEvent(event);
	}

	async saveResource() {
		const summaryRec = {};
		if (this.isEstimate) {
			summaryRec[ESTIMATEID_FIELD.fieldApiName] = this.recordId;
		} else if (this.taskDetails.Type === 'Activity') {
			summaryRec[ACTIVITYID_FIELD.fieldApiName] = this.taskDetails.ActivityGroupId;
		} else if (this.taskDetails.Type === 'ActivityGroup') {
			summaryRec[ACTIVITYGROUPID_FIELD.fieldApiName] = this.taskDetails.ActivityGroupId;
		}

		if (!this.selectedRecord) {
			this.showValidationMessage();
			return;
		}

		summaryRec[RESOURCE_ROLE_ID_FIELD.fieldApiName] = this.selectedRecord;
		summaryRec[LEVELADJUSTMENT_FIELD.fieldApiName] = this.newAdjustedAmount;
		const rectype = this.isEstimate ? 'Estimate' : this.taskDetails.Type;
		await createSummaryRecords({ summaryRecord: summaryRec, typeof: rectype });

		const event = new ShowToastEvent({
			title: LABEL_RESOURCE_NOTIFICATION_MESSAGE,
			variant: 'success',
			mode: 'dismissable',
		});

		this.dispatchEvent(event);
		this.selectedRecord = undefined;
		getRecordNotifyChange([{ recordId: this.recordId }]);
		this.addResourcePanel = false;

		if (this.isEstimate) {
			this.showEstimateResourceSummary(event);
		} else {
			this.showResourceMethod(this.taskDetails);
		}

		refreshApex(this.loadedData);
	}

	// Generic method to close modal windows..
	closeModal() {
		this.openModal = false;
		this.openResourceSummary = false;
		this.openEstimateResourceSummary = false;
		this.addResourcePanel = false;
		this.showSource = false;
	}

	async saveAndClose() {
		this.openResourceSummary = false;
		this.openEstimateResourceSummary = false;

		if (!this.isEstimate) {
			if (this.taskDetails.NotApplicable) {
				const event = new ShowToastEvent({
					title: `${this.taskDetails.Type}-${this.taskDetails.ActivityGroupName} is made "Not Applicable".`,
					variant: 'success',
					mode: 'dismissable',
				});

				this.dispatchEvent(event);
			}

			this.openModal = false;

			try {
				await updateNotApplicableField({
					recordId: this.taskDetails.ActivityGroupId,
					notApplicable: this.taskDetails.NotApplicable,
					type: this.taskDetails.Type,
				});

				refreshApex(this.loadedData);
				getRecordNotifyChange([{ recordId: this.recordId }]);
				this.adjustedTaskDuration = 0;
			} catch (e) {
				this.toastError(e);
			}
		}
	}
	NotApplicable(event) {
		this.taskDetails.NotApplicable = event.target.checked;

		if (event.target.checked) {
			// Can add modal window confirmation box.
		}
	}
	// This function is called when a task is saved from the Edit Task Screen.
	saveTask() {
		const taskrec = {};
		taskrec.Id = this.taskDetails.ActivityGroupId;
		taskrec[LEVELADJUSTMENT_FIELD.fieldApiName] = this.taskDetails.AdjustedDuration;
		taskrec[CALCULATEDDURATION_FIELD.fieldApiName] = this.taskDetails.CalculatedDuration;
		taskrec[ADJUSTMENTREASON_FIELD.fieldApiName] = this.taskDetails.AdjustmentReason;
		taskrec[ISNOTAPPLICABLE_FIELD.fieldApiName] = this.taskDetails.NotApplicable;
		taskrec[ESTIMATEEDDURATION_FIELD.fieldApiName] = +this.taskDetails.CalculatedDuration + +this.taskDetails.AdjustedDuration;

		if (this.taskDetails.NotApplicable) {
			taskrec[LEVELADJUSTMENT_FIELD.fieldApiName] = 0;
			taskrec[CALCULATEDDURATION_FIELD.fieldApiName] = 0;
			taskrec[ADJUSTMENTREASON_FIELD.fieldApiName] = '';
			taskrec[ESTIMATEEDDURATION_FIELD.fieldApiName] = 0;
		}

		updateTask({ tsk: taskrec, taskParams: this.taskparamrecs })
			.then(() => {
				refreshApex(this.loadedData);

				const event = new ShowToastEvent({
					title: 'Task Updated Successfully',
					variant: 'success',
					mode: 'dismissable',
				});

				this.dispatchEvent(event);
				this.openModal = false;
				getRecordNotifyChange([{ recordId: this.recordId }]);
				this.adjustedTaskDuration = 0;
			})
			.catch((e) => {
				this.toastError(e);
			});
	}
	// Calulation when adjustment is changed at the tasklevel in the Edit task screen.
	handleAdjustmentAmountChange(e) {
		if (e.detail.value === '' || e.detail.value === null) {
			this.taskDetails.AdjustedDuration = 0;
		}

		this.taskDetails.AdjustedDuration = e.detail.value;
		this.taskDetails.EstimatedDuration = +this.taskDetails.CalculatedDuration + +e.detail.value;
	}
	// Assign the adjustment reason value to the taskdetails variable
	handleAdjustmentReason(e) {
		this.taskDetails.AdjustmentReason = e.detail.value;
	}
	// This method is invoked when fields are changed in the Edit task Screen.
	handleChange(event) {
		let enteredValue = event.target.value;
		if (enteredValue === null || enteredValue === '') enteredValue = 0;

		this.taskFieldDef.forEach((def) => {
			const element = def;
			if (element.FieldId === event.target.name) {
				if (def.Datatype === 'Integer' || def.Datatype === 'Integer Tiers') {
					element.selectedValue = +enteredValue;
				} else if (element.Datatype === 'Picklist') {
					element.selectedValue = enteredValue;
					element.picklistLabel = event.target.options.find((opt) => opt.value === event.detail.value).label;
				} else if (element.Datatype === 'Checkbox') {
					element.selectedValue = event.target.checked;
				}
			}
		});
		this.updateTaskDetails(this.taskFieldDef);
	}

	updateTaskDetails(fieldDef) {
		let calculatedtaskDuration = 0;
		const recs = [];
		fieldDef.forEach((def) => {
			if (def.selectedValue !== undefined) {
				const paramrec = {};
				paramrec.Id = def.TaskParameterValueId;

				if (def.Datatype === 'Integer') {
					calculatedtaskDuration += (+def.selectedValue * +def.Multiplier);
					paramrec[INTEGERVALUE_FIELD.fieldApiName] = def.selectedValue;
				} else if (def.Datatype === 'Picklist') {
					calculatedtaskDuration += +def.selectedValue;
					paramrec[TEXTVALUE_FIELD.fieldApiName] = def.picklistLabel;
				} else if (def.Datatype === 'Checkbox') {
					paramrec[BOOLEANVALUE_FIELD.fieldApiName] = def.selectedValue;
					calculatedtaskDuration += paramrec[BOOLEANVALUE_FIELD.fieldApiName] ? +def.Multiplier : 0;
				} else if (def.Datatype === 'Integer Tiers') {
					paramrec[INTEGERVALUE_FIELD.fieldApiName] = +def.selectedValue;
					// eslint-disable-next-line max-len
					const matchTier = def.IntegerTiers.find((ele) => ele[FROM_VALUE_FIELD.fieldApiName] <= +def.selectedValue && +def.selectedValue <= ele[TO_VALUE_FIELD.fieldApiName]);
					if (matchTier !== undefined) {
						calculatedtaskDuration += (+def.selectedValue * +matchTier[PER_UNIT_DURATION_FIELD.fieldApiName]);
					}
				}

				recs.push(paramrec);
			}
		});
		this.taskparamrecs = recs;
		this.taskDetails.CalculatedDuration = calculatedtaskDuration;
		this.taskDetails.EstimatedDuration = +this.taskDetails.CalculatedDuration + +this.taskDetails.AdjustedDuration;
	}

	toastError(error) {
		this.dispatchEvent(
			new ShowToastEvent({
				title: 'Application Exception',
				message: reduceErrors(error).join(', '),
				variant: 'error',
			}),
		);
	}
}
