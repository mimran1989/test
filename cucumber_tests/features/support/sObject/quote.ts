import { IRecordInput, SObjectDO, SObjectSO } from '.';
import Util from '../util';

const FIELD_NAME_RATE_CARD_ID = 'RateCardId__c';
const FIELD_NAME_SERVICE_END_DATE = 'ServiceEndDate__c';
const FIELD_NAME_SERVICE_START_DATE = 'ServiceStartDate__c';
const FIELD_NAME_TIME_PERIOD = 'TimePeriod__c';
const FIELD_NAME_TIME_PERIODS_ALIGNMENT = 'TimePeriodsAlignment__c';
const FIELD_NAME_TIME_PERIODS_GROUP_METHOD = 'TimePeriodsGroupMethod__c';
const TIME_PERIOD_MONTHS = 'Months';
const FIELD_NAME_TIME_PERIODS_ALIGNMENT_CALENDAR = 'Calendar';
const FIELD_NAME_TIME_PERIODS_GROUP_METHOD_YEAR = 'Year';

interface QuoteRecordInput extends IRecordInput {
	rateCardId: string;
}

function getRecordCreateDefaults(isDeployedInPackage = false, { rateCardId }: QuoteRecordInput) {
	const qualifier = Util.nameQualifier(isDeployedInPackage);

	const quoteSO: SObjectSO = {
		Name: Util.getRandomString(18),
	};

	quoteSO[qualifier(FIELD_NAME_RATE_CARD_ID)] = rateCardId;

	const serviceStartDate = new Date();
	const serviceEndDate = new Date();
	serviceEndDate.setFullYear(serviceEndDate.getFullYear() + 1);

	quoteSO[qualifier(FIELD_NAME_SERVICE_END_DATE)] = serviceEndDate;
	quoteSO[qualifier(FIELD_NAME_SERVICE_START_DATE)] = serviceStartDate;
	quoteSO[qualifier(FIELD_NAME_TIME_PERIOD)] = TIME_PERIOD_MONTHS; // TODO: randomize time period, time periods alignment and time periods group method
	quoteSO[qualifier(FIELD_NAME_TIME_PERIODS_ALIGNMENT)] = FIELD_NAME_TIME_PERIODS_ALIGNMENT_CALENDAR;
	quoteSO[qualifier(FIELD_NAME_TIME_PERIODS_GROUP_METHOD)] = FIELD_NAME_TIME_PERIODS_GROUP_METHOD_YEAR;

	return quoteSO;
}

const Quote: SObjectDO = {
	apiName: 'Quote__c',
	getRecordCreateDefaults,
};

export default Quote;
