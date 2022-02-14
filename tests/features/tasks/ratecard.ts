import { Actor } from '../support/actor';
import { RateCard, SObjectSO } from '../support/sObject';
import { ProductRecordInput } from '../support/sObject/product';
import RateCardItem from '../support/sObject/rateCardItem';
import Insert from './interactions/crud';
import { createNRoles, createRoles } from './product';

export interface IRateCardProduct {
	Name?: string;
	SkillLevel?: string;
	Location?: string;
}

export async function createAnEmptyRateCard(actor: Actor): Promise<SObjectSO> {
	return actor.attemptsTo(Insert.record(`${actor.world.namespacePrefix}${RateCard.apiName}`, RateCard.getRecordCreateDefaults(actor.world.isDeployedInPackage)));
}

export function createARateCardWithRoles(rolesOrNumRoles: number | IRateCardProduct[]) {
	return async(actor: Actor) => {
		const rateCardSO: SObjectSO = await actor.attemptsTo(createAnEmptyRateCard);
		let roles: SObjectSO[];
		if (!Array.isArray(rolesOrNumRoles)) {
			roles = await actor.attemptsTo(createNRoles(rolesOrNumRoles));
		} else {
			const rolesToCreate = [...rolesOrNumRoles.reduce((accumulator: Map<string, ProductRecordInput>, role: IRateCardProduct) => {
				accumulator.set(role.Name, { productName: role.Name });
				return accumulator;
			}, new Map<string, ProductRecordInput>()).values()];

			roles = await actor.attemptsTo(createRoles(rolesToCreate));
		}

		return actor.attemptsTo(addRolesToARateCard(rateCardSO.id, roles, Array.isArray(rolesOrNumRoles) ? rolesOrNumRoles as IRateCardProduct[] : null));
	};
}

export function addRolesToARateCard(rateCardId: string, roles: SObjectSO[], rates?: IRateCardProduct[]) {
	return async(actor: Actor): Promise<SObjectSO> => {
		let rateCardItemsForRoles: SObjectSO[];
		if (!rates) {
			rateCardItemsForRoles = roles.map((role: SObjectSO) => RateCardItem.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
				rateCardId, productId: role.id,
			}));
		} else {
			const rolesByName = roles.reduce((accumulator: Map<string, SObjectSO>, role: SObjectSO) => {
				accumulator.set(role.Name, role);
				return accumulator;
			}, new Map<string, SObjectSO>());

			rateCardItemsForRoles = rates.map((rateCardProduct: IRateCardProduct) => RateCardItem.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
				rateCardId,
				productId: rolesByName.get(rateCardProduct.Name).id,
			}));
		}

		return actor.attemptsTo(Insert.records(`${actor.world.namespacePrefix}${RateCardItem.apiName}`, rateCardItemsForRoles));
	};
}
