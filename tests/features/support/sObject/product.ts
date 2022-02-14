import { IRecordInput, SObjectDO, SObjectSO } from '.';
import Util from '../util';

const FIELD_NAME_ACTIVE = 'IsActive';
const FIELD_NAME_PRACTICE = 'Practice__c';
const FIELD_NAME_GROUP = 'Group__c';
const FIELD_NAME_RECORD_TYPE_ID = 'RecordTypeId';
const FIELD_NAME_ASSOCIATED_PRODUCT_ID = 'AssociatedProductId__c';
export const RECORD_TYPE_RESOURCE_ROLE = 'Resource Role';

export interface ProductRecordInput extends IRecordInput {
	recordTypeId?: string;
    serviceProductId?: string;
    practice?: string;
	productName?: string;
    group?: string;
}

function getRecordCreateDefaults(isDeployedInPackage = false, {
	productName, group, practice, recordTypeId, serviceProductId,
}: ProductRecordInput) {
	const qualifier = Util.nameQualifier(isDeployedInPackage);

	const productSO: SObjectSO = {
		Name: productName || Util.getRandomString(18),
	};

	productSO[FIELD_NAME_ACTIVE] = true;
	productSO[qualifier(FIELD_NAME_PRACTICE)] = practice;
	productSO[qualifier(FIELD_NAME_GROUP)] = group;
	productSO[qualifier(FIELD_NAME_ASSOCIATED_PRODUCT_ID)] = serviceProductId;
	productSO[FIELD_NAME_RECORD_TYPE_ID] = recordTypeId;

	return productSO;
}

export const Product: SObjectDO = {
	apiName: 'Product2',
	getRecordCreateDefaults,
};
