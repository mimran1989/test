import { Actor } from '../support/actor';
import { SObjectSO } from '../support/sObject';
import { Product, ProductRecordInput, RECORD_TYPE_RESOURCE_ROLE } from '../support/sObject/product';
import Insert from './interactions/crud';
import Describe from './interactions/describe';

export function createRoles(roles: ProductRecordInput[]) {
	return async(actor: Actor): Promise<SObjectSO[]> => {
		const productObjectQualifiedName = `${Product.apiName}`;
		const recordTypeIdsByName = await actor.attemptsTo(Describe.theRecordTypes.for(productObjectQualifiedName));
		const rolesToCreate: SObjectSO[] = [];
		for (let i = 0; i < roles.length; i++) {
			rolesToCreate.push(Product.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
				...roles[i],
				recordTypeId: recordTypeIdsByName.get(RECORD_TYPE_RESOURCE_ROLE),
			}));
		}

		return actor.attemptsTo(Insert.records(`${actor.world.namespacePrefix}${Product.apiName}`, rolesToCreate));
	};
}

export function createNRoles(numberOfRoles: number) {
	return async(actor: Actor): Promise<SObjectSO[]> => {
		const productObjectQualifiedName = `${Product.apiName}`;
		const recordTypeIdsByName = await actor.attemptsTo(Describe.theRecordTypes.for(productObjectQualifiedName));
		const rolesToCreate: SObjectSO[] = [];
		for (let i = 0; i < numberOfRoles; i++) {
			rolesToCreate.push(Product.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
				recordTypeId: recordTypeIdsByName.get(RECORD_TYPE_RESOURCE_ROLE),
			}));
		}

		return actor.attemptsTo(Insert.records(`${actor.world.namespacePrefix}${Product.apiName}`, rolesToCreate));
	};
}
