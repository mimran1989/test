import { Connection, ErrorResult, RecordResult } from 'jsforce';
import { Actor } from '../../support/actor';
import { SObjectDO, SObjectSO } from '../../support/sObject';
import { getSalesforceConnection } from './connect';

const CREATED_RECORDS_KEY = 'createdRecords';
const LAST_CREATED_KEY = 'lastCreated';

type RecordOrError = RecordResult & ErrorResult;

export const Insert = {
	record: (objectType: string, record: SObjectSO) => async(actor: Actor): Promise<SObjectSO> => insertRecord(actor, objectType, record),
	records: (objectType: string, records: SObjectSO[]) => async(actor: Actor): Promise<SObjectSO[]> => insertRecords(actor, objectType, records),
};

export const Last = {
	created: (sObjectType: SObjectDO) => (actor: Actor): SObjectSO => {
		const lastCreatedRecord = getLastCreatedRecord(actor, sObjectType);
		if (!lastCreatedRecord) {
			throw new Error(`Could not find the last created record of type: ${sObjectType.apiName} `);
		}

		return lastCreatedRecord;
	},
};

function getLastCreatedRecord(actor: Actor, sObjectType: SObjectDO) {
	const lastCreatedRecords: Map<string, SObjectSO> = actor.recall(LAST_CREATED_KEY);
	return lastCreatedRecords?.get(`${actor.world.namespacePrefix}${sObjectType.apiName}`);
}

async function insertRecord(actor: Actor, objectType: string, record: SObjectSO): Promise<SObjectSO> {
	const insertedRecords = await insertRecords(actor, objectType, [record]);
	return insertedRecords[0];
}

async function insertRecords(actor: Actor, objectType: string, records: SObjectSO[]): Promise<SObjectSO[]> {
	const salesforceConnection: Connection = getSalesforceConnection(actor);
	const ctxRecords: SObjectSO[] = records;
	const createRecordsResult = await salesforceConnection.sobject(objectType).create(ctxRecords, { allOrNone: true });
	const errors: any = [];

	// remmeber the record id of inserted records
	const newRecordsWithIds = (createRecordsResult as unknown as RecordOrError[])
		.map((record, idx) => {
			const insertErrors = record.errors;
			if (insertErrors?.length) {
				errors.push(...insertErrors);
			}

			ctxRecords[idx].id = (record as any).id;
			return ctxRecords[idx];
		});

	if (errors.length > 0) {
		const isNamespaceError = errors.some((error) => error.statusCode === 'JSON_PARSER_ERROR');
		const recordsString = ctxRecords.map((ctxRecord) => JSON.stringify(ctxRecord, null, 4));
		if (isNamespaceError) {
			throw new Error(`Error inserting records: Invalid field definition for object type: ${objectType},\n${recordsString}`);
		} else {
			const errorString: string = errors.map((error) => error.message).join('\n');
			throw new Error(`Error inserting records:\n${errorString}\n${recordsString}`);
		}
	}

	rememberCreatedRecords(actor, newRecordsWithIds);

	const lastCreatedRecord = newRecordsWithIds[newRecordsWithIds.length - 1];
	rememberTheLastCreatedRecord(actor, objectType, lastCreatedRecord);

	return newRecordsWithIds;
}

async function rememberCreatedRecords(actor: Actor, createdRecords: SObjectSO[]) {
	let existingRecords: SObjectSO[] | null = actor.recall(CREATED_RECORDS_KEY);
	if (!existingRecords) {
		existingRecords = [];
		actor.remember(CREATED_RECORDS_KEY, existingRecords);
	}

	existingRecords.push(...createdRecords);
}

async function rememberTheLastCreatedRecord(actor: Actor, objectType: string, lastCreatedRecord: SObjectSO) {
	let lastCreated: Map<string, SObjectSO> | undefined = actor.recall(LAST_CREATED_KEY);
	if (!lastCreated) {
		lastCreated = new Map<string, SObjectSO>();
		actor.remember(LAST_CREATED_KEY, lastCreated);
	}

	lastCreated.set(objectType, lastCreatedRecord);
}

export default Insert;
