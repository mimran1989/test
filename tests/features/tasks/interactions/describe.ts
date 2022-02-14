import { Connection, RecordTypeInfo } from 'jsforce';
import { Actor } from '../../support/actor';
import { getSalesforceConnection } from './connect';

export const Describe = {
	theRecordTypes: {
		for: (objectName: string) => async(actor: Actor): Promise<Map<string, string>> => {
			const salesforceConnection: Connection = getSalesforceConnection(actor);

			const describeResults : Map<string, string> = (await salesforceConnection.sobject(objectName).describe())
				.recordTypeInfos.reduce((recordTypeIdsByName: Map<string, string>, nextRecordTypeInfo: RecordTypeInfo) => {
					recordTypeIdsByName.set(nextRecordTypeInfo.name, nextRecordTypeInfo.recordTypeId);
					return recordTypeIdsByName;
				}, new Map<string, string>());

			return describeResults;
		},
	},
};

export default Describe;
