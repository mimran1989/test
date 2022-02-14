import {
	LightningElement,
	wire,
	api,
	track,
} from 'lwc';
import getTemplateStructure from '@salesforce/apex/EstimateTemplateCreator.getTemplateStructure';
import getActivityGroups from '@salesforce/apex/EstimateTemplateCreator.getActivityGroups';
import getActivities from '@salesforce/apex/EstimateTemplateCreator.getActivities';
import getTasks from '@salesforce/apex/EstimateTemplateCreator.getTasks';
import getTaskParams from '@salesforce/apex/EstimateTemplateCreator.getTaskParams';

import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import TASKPARAMS_OBJECT from '@salesforce/schema/TaskParameterTemplate__c';
import getTaskParamValues from '@salesforce/apex/EstimateTemplateCreator.getTaskParamValues';
import upsertTaskParamsValues from '@salesforce/apex/EstimateTemplateCreator.upsertTaskParamsValues';
import deleteRecords from '@salesforce/apex/EstimateTemplateCreator.deleteRecords';
import saveRecords from '@salesforce/apex/EstimateTemplateCreator.saveRecords';
import RATECARD_FIELD from '@salesforce/schema/EstimateTemplate__c.RateCardId__c';
import SERVICE_PRODUCT_FIELD from '@salesforce/schema/EstimateTemplate__c.ServiceId__c';
import RATECARD_PRODUCTID_FIELD from '@salesforce/schema/RateCardItem__c.ProductId__c';
import PRODUCTR_PRACTICE_FIELD from '@salesforce/schema/EstimateTemplate__c.ServiceId__r.Practice__c';
import PRODUCTR_GROUP_FIELD from '@salesforce/schema/EstimateTemplate__c.ServiceId__r.Group__c';
import PRODUCT_PRACTICE_FIELD from '@salesforce/schema/Product2.Practice__c';
import PRODUCT_GROUP_FIELD from '@salesforce/schema/Product2.Group__c';

import ACTIVITY_GROUP_TEMPLATE_ID_FIELD from '@salesforce/schema/ActivityTemplate__c.ActivityGroupTemplateId__c';
import SEQUENCE_FIELD from '@salesforce/schema/ActivityTemplate__c.Sequence__c';
import ESTIMATE_TEMPLATE_ID_FIELD from '@salesforce/schema/ActivityGroupTemplate__c.EstimateTemplateId__c';
import IS_ACTIVE_FIELD from '@salesforce/schema/ActivityGroupTemplate__c.IsActive__c';
import DATA_TYPE_FIELD from '@salesforce/schema/TaskParameterTemplate__c.DataType__c';
import TASK_TEMPLATE_ID_FIELD from '@salesforce/schema/TaskParameterTemplate__c.TaskTemplateId__c';
import GUIDANCE_FIELD from '@salesforce/schema/ActivityGroupTemplate__c.Guidance__c';
import ACTIVITY_TEMPLATE_ID_FIELD from '@salesforce/schema/TaskTemplate__c.ActivityTemplateId__c';
import TASK_PARAMETER_TEMPLATE_ID_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.TaskParameterTemplateId__c';

import RESOURCE_ROLE_ID_FIELD from '@salesforce/schema/TaskTemplate__c.ResourceRoleId__c';
import GUIDANCE_TASK_TEMPLATE_FIELD from '@salesforce/schema/TaskTemplate__c.Guidance__c';
import SEQUENCE_TASK_TEMPLATE_FIELD from '@salesforce/schema/TaskTemplate__c.Sequence__c';
import TASK_TEMPLATE_OBJECT from '@salesforce/schema/TaskTemplate__c';

import LABEL_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.Label__c';
import PER_UNIT_DURATION_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.PerUnitDuration__c';
import FROM_VALUE_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.FromValue__c';
import TO_VALUE_FIELD from '@salesforce/schema/TaskParameterValueTemplate__c.ToValue__c';

import SaveButton from '@salesforce/label/c.SaveButton';
import CancelButton from '@salesforce/label/c.CancelButton';
import AddValuesButton from '@salesforce/label/c.AddValuesButton';
import DeleteButton from '@salesforce/label/c.DeleteButton';
import DeleteIcon from '@salesforce/label/c.DeleteIcon';
import AddIcon from '@salesforce/label/c.AddIcon';
import AddRow from '@salesforce/label/c.AddRow';
import Actions from '@salesforce/label/c.Actions';
import CloseButton from '@salesforce/label/c.CloseButton';

import {
	ShowToastEvent,
} from 'lightning/platformShowToastEvent';
import {
	refreshApex,
} from '@salesforce/apex';

const fields = [
	RATECARD_FIELD,
	PRODUCTR_PRACTICE_FIELD,
	PRODUCTR_GROUP_FIELD,
];

const IDRegex = /[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}/;

export default class EstimateTemplateCreator extends LightningElement {
	@track label = {
		SaveButton,
		CancelButton,
		AddValuesButton,
		DeleteButton,
		DeleteIcon,
		AddIcon,
		AddRow,
		CloseButton,
		Actions,
	};

	fieldLabels = {};

	@api recordId;
	displayAg = false;
	ActivityGroups = [];
	columns = [];
	@track gridData;
	@track error;
	agExists = false;
	gridExpandedRows = [];
	@track activityGroupData;
	loadedData;
	nameUpBool = true;
	nameDWBool = false;
	@track modalHeader;
	type;
	Data = [];
	parentId;
	taskParams = false;
	isTask = false;
	showParamPopUp = false;
	@track paramsData;
	paramHeader = 'Add Values';
	deletedRecords = [];
	deletedValues = [];
	disableSave = false;

	@track paramFields ={
		Sequence_field: SEQUENCE_FIELD.fieldApiName,
		PerUnitDuration_field: PER_UNIT_DURATION_FIELD.fieldApiName,
		Fromvalue_field: FROM_VALUE_FIELD.fieldApiName,
		Tovalue_field: TO_VALUE_FIELD.fieldApiName,
		Label_field: LABEL_FIELD.fieldApiName,

	}

	// function to get the child component value..
	selectedResource(event) {
		this.activityGroupData.forEach((ele) => {
			const elememt = ele;
			if (elememt.Id === event.detail.TaskId) {
				elememt[RESOURCE_ROLE_ID_FIELD.fieldApiName] = event.detail.recordId;
			}
		});
	}

	@wire(getObjectInfo, { objectApiName: TASK_TEMPLATE_OBJECT })
	taskInfo({ data }) {
		if (data) {
			this.fieldLabels.Sequence = data.fields[SEQUENCE_TASK_TEMPLATE_FIELD.fieldApiName].label;
			this.fieldLabels.Guidance = data.fields[GUIDANCE_TASK_TEMPLATE_FIELD.fieldApiName].label;
			this.fieldLabels.ResourceRole = data.fields[RESOURCE_ROLE_ID_FIELD.fieldApiName].label;
		}
	}

	@wire(getObjectInfo, { objectApiName: TASKPARAMS_OBJECT })
	taskParamInfo({ data }) {
		if (data) {
			this.fieldLabels.DataType = data.fields[DATA_TYPE_FIELD.fieldApiName].label;
		}
	}

	// Wire method to get the estimate details..Rate Card
	@wire(getRecord, {
		recordId: '$recordId',
		fields,
	})
	estimate;
	// Get Estimate Rate Card Id
	get estimateRateCardId() {
		return this.estimate.data.fields[RATECARD_FIELD.fieldApiName].value;
	}

	get filterCriteriaString() {
		const productIdRelField = RATECARD_PRODUCTID_FIELD.fieldApiName.replace('__c', '__r');
		const serviceProductField = SERVICE_PRODUCT_FIELD.fieldApiName.replace('__c', '__r');
		const practice = this.estimate.data.fields[serviceProductField].value.fields[PRODUCT_PRACTICE_FIELD.fieldApiName].value;
		const group = this.estimate.data.fields[serviceProductField].value.fields[PRODUCT_GROUP_FIELD.fieldApiName].value;
		let filterCriteriaValue = `${productIdRelField}.${PRODUCT_PRACTICE_FIELD.fieldApiName} = `;
		if (!practice) {
			filterCriteriaValue += 'NULL ';
		} else {
			filterCriteriaValue += `'${practice}' `;
		}

		filterCriteriaValue += `AND ${productIdRelField}.${PRODUCT_GROUP_FIELD.fieldApiName} = `;

		if (!group) {
			filterCriteriaValue += 'NULL ';
		} else {
			filterCriteriaValue += `'${group}' `;
		}

		return filterCriteriaValue;
	}

	// Get Object Details of the Task Params
	@wire(getObjectInfo, {
		objectApiName: TASKPARAMS_OBJECT,
	})
	objectInfo;
	// Get Picklist values of the TaskParamObject
	@wire(getPicklistValues, {
		recordTypeId: '$objectInfo.data.defaultRecordTypeId',
		fieldApiName: DATA_TYPE_FIELD,
	}) picklistValues;
	// Get Details of the tree grid structure..
	@wire(getTemplateStructure, {
		estimateId: '$recordId',
	})
	wiredAccount(result) {
		const {
			error,
			data,
		} = result;

		this.loadedData = result;

		if (data) {
			// eslint-disable-next-line no-alert
			this.agExists = data.length > 0;
			this.gridData = data;
			this.loadColumns();
			this.gridExpandedRows = data.length > 0 ? data[0].gridExpandedIds : [];
		} else if (error) {
			this.error = error;
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
			// eslint-disable-next-line no-restricted-syntax
			for (const n in def._children) {
				if (def._children[n].Type === 'ActivityTemplate') {
					actGrp.push(def.ActivityGroupId);
				}
			}
		});
		this.gridExpandedRows = actGrp;
	}
	// This function is used to collapse and expand the tree based on the user selection..
	showTasks() {
		const grid = this.template.querySelector('lightning-tree-grid');
		grid.expandAll();
	}
	// Sort Records based on the Sequence...
	sortRecs() {
		this.nameUpBool = this.nameDWBool;
		this.nameDWBool = !this.nameUpBool;

		if (this.nameUpBool) {
			this.activityGroupData.sort((a, b) => (a[SEQUENCE_FIELD.fieldApiName] < b[SEQUENCE_FIELD.fieldApiName] ? 1 : -1));
		} else {
			this.activityGroupData.sort((a, b) => (a[SEQUENCE_FIELD.fieldApiName] > b[SEQUENCE_FIELD.fieldApiName] ? 1 : -1));
		}
	}
	loadColumns() {
		this.columns = [{
			type: 'text',
			fieldName: 'ActivityGroup',
			label: 'Activity Group/Activity/Task',
			cellAttributes: {
				iconName: {
					fieldName: 'IconType',
				},
			},
			initialWidth: 400,
		},
		{
			type: 'text',
			fieldName: 'ResourceName',
			label: 'Resource Role',
			wrapText: true,
		},
		{
			label: '',
			type: 'button',
			typeAttributes: {
				label: {
					fieldName: 'Actionlabel',
				},
				iconName: {
					fieldName: 'ActionIcon',
				},
				title: {
					fieldName: 'ActionbuttonTitle',
				},
				variant: 'border-filled',
				disabled: {
					fieldName: 'ActionIconDisabled',
				},
			},
		},
		];
	}
	// Tree grid Actions
	handleRowAction(event) {
		this.deletedRecords = [];
		this.deletedValues = [];
		this.isTask = false;
		this.taskParams = false;

		const {
			row,
		} = event.detail;

		this.disableSave = false;

		switch (row.Actionlabel) {
			case 'Add/Edit Activities':
				this.createActivities(row);
				break;
			case 'Add/Edit Tasks':
				this.isTask = true;
				this.createTasks(row);
				break;
			case 'Add/Edit Task Parameters':
				this.createTaskParameters(row);
				break;
			default:
				break;
		}
	}
	async createActivityGroups() {
		this.deletedRecords = [];
		this.disableSave = false;
		this.modalHeader = 'Activity Groups';
		this.displayAg = true;
		this.taskParams = false;
		this.isTask = false;
		const result = await getActivityGroups({ estimateTemplateId: this.recordId });
		this.activityGroupData = result;
		this.type = 'Activity Group Templates';
		this.parentId = this.recordId;

		if (result.length === 0) {
			const record = {
				Id: 'Record1',
				Name: '',
			};

			record[ESTIMATE_TEMPLATE_ID_FIELD.fieldApiName] = this.recordId;
			record[IS_ACTIVE_FIELD.fieldApiName] = true;
			record[SEQUENCE_FIELD.fieldApiName] = '1';
			this.activityGroupData.push(record);
		}

		this.transformData('activityGroupData');
	}

	async createActivities(event) {
		this.displayAg = true;
		this.modalHeader = `${event.ActivityGroupName}/ Activities`;
		const result = await getActivities({ activityGroupTemplateId: event.ActivityGroupId });
		this.activityGroupData = result;
		this.parentId = event.ActivityGroupId;
		this.type = 'Activity Templates';

		if (result.length === 0) {
			const newRecord = {
				Id: 'Record1',
				Name: '',
			};

			newRecord[ACTIVITY_GROUP_TEMPLATE_ID_FIELD.fieldApiName] = event.ActivityGroupId;
			newRecord[SEQUENCE_FIELD.fieldApiName] = '1';
			newRecord[IS_ACTIVE_FIELD.fieldApiName] = true;

			this.activityGroupData.push(newRecord);
		}

		this.transformData('activityGroupData');
	}
	async createTasks(event) {
		this.modalHeader = `${event.ParentLabel}/ Tasks`;
		const result = await getTasks({ activityTemplateId: event.ActivityGroupId });
		this.activityGroupData = result;
		this.type = 'Task Templates';
		this.parentId = event.ActivityGroupId;
		this.displayAg = true;

		if (result.length === 0) {
			const record = {
				Id: 'Record1',
				Name: '',
			};

			record[SEQUENCE_FIELD.fieldApiName] = '1';
			record[IS_ACTIVE_FIELD.fieldApiName] = true;
			record[ACTIVITY_TEMPLATE_ID_FIELD.fieldApiName] = event.ActivityGroupId;

			this.activityGroupData.push(record);
		}

		this.transformData('activityGroupData');
	}
	async createTaskParameters(event) {
		this.displayAg = true;
		this.modalHeader = `${event.ParentLabel}/ Task Parameters `;
		this.taskParams = true;
		this.type = 'Task Parameters';
		this.parentId = event.ActivityGroupId;
		const result = await getTaskParams({ taskTemplateId: event.ActivityGroupId });
		this.activityGroupData = result;

		if (result.length === 0) {
			const record = {
				Id: 'Record1',
				Name: '',
			};

			record[SEQUENCE_FIELD.fieldApiName] = '1';
			record[IS_ACTIVE_FIELD.fieldApiName] = true;
			record[DATA_TYPE_FIELD.fieldApiName] = 'Integer';
			record[TASK_TEMPLATE_ID_FIELD.fieldApiName] = event.ActivityGroupId;
			this.activityGroupData.push(record);
		}

		this.transformData('activityGroupData');
	}
	// Close Modal window
	closeModal() {
		this.displayAg = false;
	}
	// Field change event handler..
	handleChange(event) {
		const foundIndex = this.activityGroupData.findIndex((rec) => rec.Id === event.target.dataset.id);
		if (event.target.name === 'Sequence') {
			this.activityGroupData[foundIndex][SEQUENCE_FIELD.fieldApiName] = event.target.value;
		} else if (event.target.name === 'Name') {
			this.activityGroupData[foundIndex].Name = event.target.value;
		} else if (event.target.name === 'Datatype') {
			this.activityGroupData[foundIndex][DATA_TYPE_FIELD.fieldApiName] = event.target.value;
		} else if (event.target.name === 'Guidance') {
			this.activityGroupData[foundIndex][GUIDANCE_FIELD.fieldApiName] = event.target.value;
		} else if (event.target.name === 'IsMultiplier__c') {
			//
		} else {
			this.activityGroupData[event.target.dataset.id][GUIDANCE_FIELD.fieldApiName] = event.target.value;
		}

		this.transformData('activityGroupData');
	}
	// Removing records
	async removeRow(event) {
		if (event.target.dataset.id.match(IDRegex)) {
			this.deletedRecords.push(event.target.dataset.id);
		}

		this.activityGroupData = this.activityGroupData.filter((rec) => rec.Id !== event.target.dataset.id);
		this.resequenceAttributeGroups();
	}
	// Adding Row..Activity Group, Activity, Task, TaskParams
	addRow(event) {
		const indx = this.activityGroupData.findIndex((ele) => ele.Id === event.target.dataset.id);
		let parentApiName;
		if (this.type === 'Activity Group Templates') {
			parentApiName = ESTIMATE_TEMPLATE_ID_FIELD.fieldApiName;
		} else if (this.type === 'Activity Templates') {
			parentApiName = ACTIVITY_GROUP_TEMPLATE_ID_FIELD.fieldApiName;
		} else if (this.type === 'Task Parameters') {
			parentApiName = TASK_TEMPLATE_ID_FIELD.fieldApiName;
		} else {
			parentApiName = ACTIVITY_TEMPLATE_ID_FIELD.fieldApiName;
		}

		const newJson = {
			Id: 'Record',
			Name: '',
		};

		newJson[SEQUENCE_FIELD.fieldApiName] = this.activityGroupData.length + 1;
		newJson[IS_ACTIVE_FIELD.fieldApiName] = true;

		if (this.type === 'Task Parameters') newJson[DATA_TYPE_FIELD.fieldApiName] = 'Integer';
		newJson[parentApiName] = this.parentId;
		this.activityGroupData.splice(indx + 1, 0, newJson);
		this.resequenceAttributeGroups();
		this.transformData('activityGroupData');
	}

	resequenceAttributeGroups() {
		this.activityGroupData.forEach((ele, ind) => {
			const element = ele;
			element.Id = ele.Id.startsWith('Record') ? `Record${(ind + 1).toString()}` : ele.Id;
			element[SEQUENCE_FIELD.fieldApiName] = ind + 1;
		});
	}

	// Save button for  ActivityGroup, Activity, Task, TaskParameters
	async saveRecord() {
		const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputField) => {
			inputField.reportValidity();
			return validSoFar && inputField.checkValidity();
		}, true);

		let lookUpValid = false;
		if (this.type === 'Task Templates') {
			this.template.querySelectorAll('c-custom-lookup').forEach((element) => element.isValid());

			lookUpValid = this.activityGroupData.some((ele) => ele[RESOURCE_ROLE_ID_FIELD.fieldApiName] === undefined);
		}

		if (isInputsCorrect && !lookUpValid) {
			this.disableSave = true;
			this.activityGroupData.forEach((def) => {
				const element = def;
				if (element.Id !== undefined) {
					if (element.Id.includes('Record')) {
						delete element.Id;
					}
				}
			});

			if (this.deletedRecords.length > 0) {
				await deleteRecords({ removeRecordIds: this.deletedRecords });
			}

			await saveRecords({
				recordString: JSON.stringify(this.activityGroupData),
				typeOf: this.type,
			});

			this.showNotification(`${this.type} Updated Successfully`, 'Success', 'success');
			refreshApex(this.loadedData);
			this.closeModal();
		}
	}
	// Close Param Values Modal Window..
	closeParamPopup() {
		this.deletedValues = [];
		this.showParamPopUp = false;
	}
	// Display Success or Failure notification..
	showNotification(title, message, variant) {
		const evt = new ShowToastEvent({
			title,
			message,
			variant,
		});

		this.dispatchEvent(evt);
	}
	// Add Values to the TaskParams/..
	async addValues(event) {
		const recId = event.target.dataset.id;
		const selectedRecord = this.activityGroupData.filter((e) => e.Id === recId)[0];

		this.paramsData = {};
		this.paramsData.taskTemplateParameter = selectedRecord;
		this.paramsData.isCheckbox = (selectedRecord[DATA_TYPE_FIELD.fieldApiName] === 'Checkbox');
		this.paramsData.isInteger = (selectedRecord[DATA_TYPE_FIELD.fieldApiName] === 'Integer');
		this.paramsData.isPicklist = (selectedRecord[DATA_TYPE_FIELD.fieldApiName] === 'Picklist');
		this.paramsData.IntegerTiers = (selectedRecord[DATA_TYPE_FIELD.fieldApiName] === 'Integer Tiers');

		if (this.paramsData.isCheckbox) {
			this.paramHeader = 'Define Duration if Checked';
		} else if (this.paramsData.isInteger) {
			this.paramHeader = 'Define Recommended Per Unit Duration';
		} else if (this.paramsData.isPicklist) {
			this.paramHeader = 'Define Recommended Durations';
		} else if (this.paramsData.IntegerTiers) {
			this.paramHeader = 'Define Recommended Durations';
		}

		if (!recId.startsWith('Record')) {
			const paramValues = await getTaskParamValues({
				taskParamsTemplateId: event.target.dataset.id,
			});

			if (paramValues.length > 0) {
				this.paramsData.paramValues = paramValues.filter((paramValue) => this.deletedRecords.indexOf(paramValue.Id) === -1);
				this.transformData('taskParamValues');
			} else {
				this.addRecordBasedonDataType(event);
			}
		} else {
			this.addRecordBasedonDataType(event);
		}

		this.showParamPopUp = true;
	}

	// eslint-disable-next-line max-lines-per-function
	addRecordBasedonDataType(event) {
		const paramVal = [];
		const record = {};
		record[SEQUENCE_FIELD.fieldApiName] = 1;
		record[PER_UNIT_DURATION_FIELD.fieldApiName] = 0;
		record[TASK_PARAMETER_TEMPLATE_ID_FIELD.fieldApiName] = event.target.dataset.id;

		if (this.paramsData.isCheckbox) {
			record.Id = 'RecordYes';
			record[LABEL_FIELD.fieldApiName] = 'Yes';
			record[TASK_PARAMETER_TEMPLATE_ID_FIELD.fieldApiName] = event.target.dataset.id;

			paramVal.push(record);
		} else if (this.paramsData.isInteger) {
			record.Id = 'RecordInteger';
			paramVal.push(record);
		} else if (this.paramsData.isPicklist) {
			record.Id = 'RecordPicklist0';

			record[LABEL_FIELD.fieldApiName] = '';

			paramVal.push(record);
		} else if (this.paramsData.IntegerTiers) {
			record.Id = 'RecordPicklist0';

			record[FROM_VALUE_FIELD.fieldApiName] = 0;
			record[TO_VALUE_FIELD.fieldApiName] = '';

			paramVal.push(record);
		}

		this.paramsData.paramValues = paramVal;
		this.transformData('taskParamValues');
	}

	transformData(type) {
		if (type === 'activityGroupData') {
			this.activityGroupData.forEach((ele) => {
				const element = ele;
				element.Sequence_field = element[SEQUENCE_FIELD.fieldApiName];
				element.Guidance_field = element[GUIDANCE_FIELD.fieldApiName];
				element.ResourceroleId_field = element[RESOURCE_ROLE_ID_FIELD.fieldApiName];
				element.Datatype_field = element[DATA_TYPE_FIELD.fieldApiName];
			});
		} else if (type === 'taskParamValues') {
			this.paramsData.paramValues.forEach((ele) => {
				const element = ele;
				element.Sequence_field = element[SEQUENCE_FIELD.fieldApiName];
				element.PerUnitDuration_field = element[PER_UNIT_DURATION_FIELD.fieldApiName];
				element.Fromvalue_field = element[FROM_VALUE_FIELD.fieldApiName];
				element.Tovalue_field = element[TO_VALUE_FIELD.fieldApiName];
				element.Label_field = element[LABEL_FIELD.fieldApiName];
			});
		}
	}

	// Handling the Param value field changes..
	valueHandleChange(event) {
		if (this.paramsData.paramValues !== undefined) {
			this.paramsData.paramValues.forEach((ele) => {
				const element = ele;
				if (element.Id === event.target.dataset.id) {
					element[event.target.dataset.field] = (event.target.type === 'Checkbox') ? event.target.checked : event.target.value;
				}
			});
		}

		this.transformData('taskParamValues');
	}
	// Adding new rows and deleting in the Param Values..
	// eslint-disable-next-line max-lines-per-function
	async changeValueRows(event) {
		const recId = event.target.dataset.id;
		const { type } = event.target.dataset;
		if (type === 'Add') {
			const indx = this.paramsData.paramValues.findIndex((ele) => ele.Id === recId);
			let newJson;
			if (this.paramsData.isPicklist) {
				newJson = {
					Id: `RecordPicklist${(indx + 1).toString()}`,
				};
				newJson[LABEL_FIELD.fieldApiName] = '';
				newJson[PER_UNIT_DURATION_FIELD.fieldApiName] = 0;
				newJson[TASK_PARAMETER_TEMPLATE_ID_FIELD.fieldApiName] = event.target.dataset.id;
			} else if (this.paramsData.IntegerTiers) {
				const previousRecord = this.paramsData.paramValues.find((ele) => ele.Id === recId);

				const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputField) => {
					inputField.reportValidity();
					return validSoFar && inputField.checkValidity();
				}, true);

				if (isInputsCorrect) {
					newJson = {
						Id: `RecordPicklist${(indx + 1).toString()}`,
						IsMultiplier__c: false,
					};
					newJson[PER_UNIT_DURATION_FIELD.fieldApiName] = 0;
					newJson[TASK_PARAMETER_TEMPLATE_ID_FIELD.fieldApiName] = event.target.dataset.id;
					newJson[FROM_VALUE_FIELD.fieldApiName] = +previousRecord[TO_VALUE_FIELD.fieldApiName] + +1;
					newJson[TO_VALUE_FIELD.fieldApiName] = '';
				}
			}

			if (newJson !== undefined) {
				this.paramsData.paramValues.splice(indx + 1, 0, newJson);
				this.paramsData.paramValues.forEach((ele, ind) => {
					const element = ele;
					element[SEQUENCE_FIELD.fieldApiName] = ind + 1;
				});
			}
		} else if (type === 'Remove') {
			this.paramsData.paramValues = this.paramsData.paramValues.filter((e) => e.Id !== recId);
			this.paramsData.paramValues.forEach((ele, ind) => {
				const element = ele;
				element[SEQUENCE_FIELD.fieldApiName] = ind + 1;
			});
			this.deletedValues.push(recId);
		}

		this.transformData('taskParamValues');
	}
	// Save logic for Param Values
	async saveParamValues() {
		const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputField) => {
			inputField.reportValidity();
			return validSoFar && inputField.checkValidity();
		}, true);

		if (isInputsCorrect) {
			const response = await upsertTaskParamsValues({
				taskParamTemplateRecord: this.paramsData.taskTemplateParameter,
				taskParamValues: this.paramsData.paramValues,
			});

			if (response === 'Success') {
				this.activityGroupData = await getTaskParams({ taskTemplateId: this.parentId });
				this.showNotification('Task Parameters values Updated Successfully', 'Success', 'success');
			}

			this.deletedRecords.push(...this.deletedValues);
			this.deletedValues = [];

			this.showParamPopUp = false;
		}

		this.transformData('taskParamValues');
		this.transformData('activityGroupData');
	}
}
