import { IRecordInput, SObjectDO, SObjectSO } from '.';
import Util from '../util';

const FIELD_NAME_ACTIVE = 'IsActive__c';
const FIELD_NAME_PRODUCT_ID = 'ProductId__c';
const FIELD_RATE_CARD_ID = 'RateCardId__c';
const FIELD_NAME_UNIT_PRICE = 'UnitPrice__c';
const FIELD_NAME_UNIT_COST = 'UnitCost__c';
const MIN_DEFAULT_PRICE = 1;
const MAX_DEFAULT_PRICE = 10000;

interface RateCardItemRecordInput extends IRecordInput {
	productId?: string;
    rateCardId: string;
    unitCost?: number;
    unitPrice?: number;
    customAttributes: Record<string, any>;
}

function getRecordCreateDefaults(isDeployedInPackage = false, {
	rateCardId, productId, unitCost, unitPrice,
}: RateCardItemRecordInput) {
	const qualifier = Util.nameQualifier(isDeployedInPackage);
	const rateCardItemSO: SObjectSO = {};

	rateCardItemSO[qualifier(FIELD_NAME_ACTIVE)] = true;
	rateCardItemSO[qualifier(FIELD_RATE_CARD_ID)] = rateCardId;
	rateCardItemSO[qualifier(FIELD_NAME_PRODUCT_ID)] = productId;

	const unitCostForItem = unitCost === undefined ? Util.getRandomNumber(MIN_DEFAULT_PRICE, MAX_DEFAULT_PRICE) : unitCost;
	rateCardItemSO[qualifier(FIELD_NAME_UNIT_COST)] = unitCostForItem;

	const unitPriceForItem = unitPrice === undefined ? Util.getRandomNumber(unitCostForItem, MAX_DEFAULT_PRICE) : unitPrice;
	rateCardItemSO[qualifier(FIELD_NAME_UNIT_PRICE)] = unitPriceForItem;

	return rateCardItemSO;
}

const RateCardItem: SObjectDO = {
	apiName: 'RateCardItem__c',
	getRecordCreateDefaults,
};

export default RateCardItem;
