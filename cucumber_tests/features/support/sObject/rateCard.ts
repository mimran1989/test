import { SObjectDO, SObjectSO } from '.';
import Util from '../util';

const FIELD_NAME_ACTIVE = 'IsActive__c';
const FIELD_NAME_EFFECTIVE_DATE = 'EffectiveDate__c';
const FIELD_NAME_EXPIRATION_DATE = 'ExpirationDate__c';
function getRecordCreateDefaults(isDeployedInPackage = false) {
	const nsPrefix = isDeployedInPackage ? `${Util.namespace}__` : '';

	const rateCardSO: SObjectSO = {
		Name: Util.getRandomString(18),
	};

	rateCardSO[`${nsPrefix}${FIELD_NAME_ACTIVE}`] = true;

	// generate a valid effective and expiration date
	const effectiveDate = new Date();
	const expirationDate = new Date();
	effectiveDate.setDate(effectiveDate.getDate() - 1);
	expirationDate.setFullYear(expirationDate.getFullYear() + 1);

	rateCardSO[`${nsPrefix}${FIELD_NAME_EFFECTIVE_DATE}`] = effectiveDate;
	rateCardSO[`${nsPrefix}${FIELD_NAME_EXPIRATION_DATE}`] = expirationDate;

	return rateCardSO;
}

const RateCard: SObjectDO = {
	apiName: 'RateCard__c',
	getRecordCreateDefaults,
};

export default RateCard;
