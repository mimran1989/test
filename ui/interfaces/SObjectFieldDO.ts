export interface SObjectFieldDO {
	fieldName: string;
	fieldLabel: string;
	dataType: any;
	sourceObject: string;
	pickListValues: string[];
	isEditable: boolean;
	isRequired: boolean;
	isHidden: boolean;
	sequence: number;
}
