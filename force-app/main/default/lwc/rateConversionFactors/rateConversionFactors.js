import {
	track, wire, api, LightningElement,
} from 'lwc';
import getObjectOverride from '@salesforce/apex/ObjectOverrideController.getObjectOverride';
import commitObjectOverride from '@salesforce/apex/ObjectOverrideController.commitObjectOverride';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NamespacePrefix from '@salesforce/apex/SystemUtility.getNamespacePrefix';
import DefaultLabel from '@salesforce/label/c.Default';
import OverrideHoursLabel from '@salesforce/label/c.OverrideHours';
import TimePeriodLabel from '@salesforce/label/c.TimePeriod';
import EditRateFactorLabel from '@salesforce/label/c.EditRateFactors';
import ErrorSavingMessageLabel from '@salesforce/label/c.ErrorSavingMessage';
import ErrorSavingNotificationTitleLabel from '@salesforce/label/c.ErrorSavingNotificationTitle';
import RateConversionFactorsLabel from '@salesforce/label/c.RateConversionFactors';
import RateConversionOverrideLessThanOrEqualZeroLabel from '@salesforce/label/c.RateConversionOverrideLessThanOrEqualZero';
import ValidationErrorTitleLabel from '@salesforce/label/c.ValidationErrorTitle';
import SuccessfullyUpdatedNotificationTitleLabel from '@salesforce/label/c.SuccessfullyUpdatedNotificationTitle';
import SuccessfullySavedLabel from '@salesforce/label/c.SuccessfullySaved';

import log from 'c/log';

export default class RateConversionFactors extends NavigationMixin(LightningElement) {
	@api recordId;
	@api objectOverrideVM;
	@api editRateFactor = EditRateFactorLabel;
	objectOverride;
	objectOverrideData;
	_componentState;
	labels = {
		errorSavingMessage: ErrorSavingMessageLabel,
		errorSavingNotificationTitle: ErrorSavingNotificationTitleLabel,
		rateConversionFactors: RateConversionFactorsLabel,
		rateConversionOverrideLessThanOrEqualZero: RateConversionOverrideLessThanOrEqualZeroLabel,
		ValidationErrorTitle: ValidationErrorTitleLabel,
		successfullyUpdatedNotificationTitle: SuccessfullyUpdatedNotificationTitleLabel,
		successfullySaved: SuccessfullySavedLabel,
	};
	conversionTableFactorColumns = [
		{
			label: TimePeriodLabel,
			fieldName: 'timePeriod',
			type: 'text',
		},
		{
			label: DefaultLabel,
			fieldName: 'defaultHours',
			type: 'number',
		},
		{
			label: OverrideHoursLabel,
			fieldName: 'overrideHours',
			type: 'number',
			typeAttributes: {
				minimumIntegerDigits: '1',
				maximumSignificantDigits: '4',
				maximumFractionDigits: '0',
			},
			editable: true,
		},
	];
	static FieldNames = {
		STANDARD_DAY_HOURS: '',
		STANDARD_WEEK_HOURS: '',
		STANDARD_MONTH_HOURS: '',
		STANDARD_YEAR_HOURS: '',
		SCHEDULE_SETTINGS: '',
	};

	@track rateConversionData;
	@wire(NamespacePrefix) nsPrefix;

	@wire(CurrentPageReference)
	getStateParameters(currentPageReference) {
		if (currentPageReference) {
			this.recordId = currentPageReference.state.recordId;
		}
	}

	async renderedCallback() {
		if (this.recordId && !this.objectOverride) {
			this._componentState = this.template.querySelector('.rate-factor-override');
			const ns = this.getNsPrefix();
			RateConversionFactors.FieldNames.SCHEDULE_SETTINGS = `${ns}ScheduleSetting__mdt`;
			RateConversionFactors.FieldNames.STANDARD_DAY_HOURS = `${ns}StandardDayHours__c`;
			RateConversionFactors.FieldNames.STANDARD_WEEK_HOURS = `${ns}StandardWeekHours__c`;
			RateConversionFactors.FieldNames.STANDARD_MONTH_HOURS = `${ns}StandardMonthHours__c`;
			RateConversionFactors.FieldNames.STANDARD_YEAR_HOURS = `${ns}StandardYearHours__c`;

			try {
				this.objectOverride = await getObjectOverride({
					quoteId: this.recordId,
					overrideObjectApiName: RateConversionFactors.FieldNames.SCHEDULE_SETTINGS,
				});
			} catch (error) {
				log(error);
			}

			this.processObjectOverride(this.objectOverride);
		}
	}

	processObjectOverride(objectOverrideDto) {
		this.objectOverrideVM = {
			objectApiName: objectOverrideDto.overrideObjectApiName,
			valueOverrides: {},
		};

		this.objectOverrideData = [
			this.getValueOverride(RateConversionFactors.FieldNames.STANDARD_DAY_HOURS),
			this.getValueOverride(RateConversionFactors.FieldNames.STANDARD_WEEK_HOURS),
			this.getValueOverride(RateConversionFactors.FieldNames.STANDARD_MONTH_HOURS),
			this.getValueOverride(RateConversionFactors.FieldNames.STANDARD_YEAR_HOURS),
		];
	}

	getNsPrefix() {
		return this.nsPrefix.data ? this.nsPrefix.data : '';
	}

	getValueOverride(standardDayHours) {
		const valueOverrideDto = this.objectOverride.valueOverrides
			.find((valueOverride) => valueOverride.fieldApiName === standardDayHours);

		return {
			id: standardDayHours,
			timePeriod: valueOverrideDto.fieldLabel,
			defaultHours: valueOverrideDto.defaultFieldValue,
			overrideHours: valueOverrideDto.fieldValue,
			fieldApiName: valueOverrideDto.fieldApiName,
		};
	}

	async handleSave(event) {
		if (this.validateValueRange(event.detail.draftValues) === false) {
			return;
		}

		const objectOverrideChanges = this.getChangedObjectOverride(event.detail.draftValues);
		if (!objectOverrideChanges.hasValidChanges) {
			this.dispatchEvent(new CloseActionScreenEvent());
		} else {
			const commitResult = await commitObjectOverride({
				quoteId: this.recordId,
				objectOverrideDto: objectOverrideChanges,
			});

			if (commitResult.valid) {
				this.showCommitSuccessToast();
				objectOverrideChanges.valueOverrides = [];
				const objectOverrideDto = commitResult.objectOverrideDtos[0];
				objectOverrideDto.valueOverrides = this.generateListOfOverrides(objectOverrideDto);

				const action = 'ratefactorchange';
				const payload = { reporter: 'rateConversionFactors', rateOverrideValues: JSON.stringify(objectOverrideDto.valueOverrides) };
				this._componentState.publish({ key: action, value: payload });
				this.dispatchEvent(new CloseActionScreenEvent());
			} else {
				this.showCommitFailureToast();
			}
		}
	}

	showCommitSuccessToast() {
		const evt = new ShowToastEvent({
			title: this.labels.successfullyUpdatedNotificationTitle,
			message: this.labels.successfullySaved.replace('{0}', this.labels.rateConversionFactors),
			variant: 'success',
		});

		this.dispatchEvent(evt);
	}

	showCommitFailureToast() {
		const evt = new ShowToastEvent({
			title: this.labels.errorSavingNotificationTitle,
			message: this.labels.errorSavingMessage.replace('{0}', this.labels.rateConversionFactors),
			variant: 'error',
		});

		this.dispatchEvent(evt);
	}
	validateValueRange(changedValues) {
		let isValid = true;
		for (let i = 0; i < changedValues.length; i++) {
			const changedValue = changedValues[i].overrideHours;
			const finalNumericValue = RateConversionFactors.getWholeDigits(changedValue);
			if (finalNumericValue != null && finalNumericValue <= 0) {
				isValid = false;
			}
		}

		if (isValid === false) {
			const evt = new ShowToastEvent({
				title: this.labels.errorSavingNotificationTitle,
				message: this.labels.rateConversionOverrideLessThanOrEqualZero,
				variant: 'error',
			});

			this.dispatchEvent(evt);
		}

		return isValid;
	}

	static getWholeDigits(value) {
		const decimalMatchReg = /[.,]\d+$/;
		const decimalMatch = value.match(decimalMatchReg);
		let currentValue = value;
		if (decimalMatch) {
			currentValue = currentValue.substring(0, decimalMatch.index);
		}

		if (currentValue.trim() === '') {
			return null;
		}

		let finalResult = '';
		const numericReg = /-?\d+/g;
		const matches = currentValue.match(numericReg);
		matches.forEach((match) => {
			// concat numeric characters to final resulting string
			finalResult = `${finalResult}${match}`;
		});

		return parseInt(finalResult, 10);
	}

	generateListOfOverrides(objectOverrideDto) {
		const valueOverrides = [];
		for (let i = 0; i < this.objectOverride.valueOverrides.length; i++) {
			const valueOverrideInUI = this.objectOverride.valueOverrides[i];

			const updatedValueOverride = objectOverrideDto.valueOverrides.find(
				(valueOverride) => valueOverride.fieldApiName === valueOverrideInUI.fieldApiName,
			);

			// updated value overrides take precedent over an existing one in the UI
			if (updatedValueOverride) {
				valueOverrides.push(updatedValueOverride);
			} else {
				valueOverrideInUI.fieldValue = '';
				valueOverrides.push(valueOverrideInUI);
			}
		}

		return valueOverrides;
	}

	getChangedObjectOverride(changedValues) {
		const { valueOverrides } = this.objectOverride;
		const objectOverrideChanges = { ...this.objectOverride };

		objectOverrideChanges.hasValidChanges = false;
		objectOverrideChanges.valueOverrides = [];

		if (this.objectOverride.junctionRecordId) {
			// If a junctionRecordId exists, it means we're modifying an existing override, so we need to update.
			objectOverrideChanges.hasValidChanges = true;
		}

		for (let i = 0; i < valueOverrides.length; i++) {
			const valueOverride = { ...valueOverrides[i] };
			const correspondingChangedRow = changedValues.find((draftValue) => draftValue.id === valueOverride.fieldApiName);
			if (correspondingChangedRow && RateConversionFactors.valueNotEmpty(correspondingChangedRow.overrideHours)) {
				valueOverride.fieldValue = correspondingChangedRow.overrideHours;
			} else if (correspondingChangedRow) {
				valueOverride.fieldValue = null;
			}

			if (RateConversionFactors.valueNotEmpty(valueOverride.fieldValue)) {
				objectOverrideChanges.valueOverrides.push(valueOverride);

				// Mark the object override changes as dirty so we know we need to update.
				if (!objectOverrideChanges.hasValidChanges) {
					objectOverrideChanges.hasValidChanges = true;
				}
			}
		}

		return objectOverrideChanges;
	}

	static valueNotEmpty(value) {
		return value && value.length > 0;
	}

	findValueOverrideByApiName(fieldApiName) {
		const foundValueOverride = this.objectOverride.valueOverrides.find((valueOverride) => valueOverride.fieldApiName === fieldApiName);
		return { ...foundValueOverride };
	}

	handleCancel() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}
