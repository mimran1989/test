import { Actor } from '../support/actor';
import {
	Quote, RateCard, SObjectSO, SObjectSOCallback,
} from '../support/sObject';
import { Product, RECORD_TYPE_RESOURCE_ROLE } from '../support/sObject/product';
import RateCardItem from '../support/sObject/rateCardItem';
import Insert from './interactions/crud';
import Describe from './interactions/describe';

export const Create = {
	aQuote: ({
		thatIsEmpty: createAnEmptyQuote,
		withRateCard: createAnEmptyQuoteWithRateCard,
	}),
	aRateCard: ({
		thatIsEmpty: createAnEmptyRateCard,
		withRoles: createARateCardWithRoles,
	}),
	roles: createRoles,
};

export const Add = {
	roles: (roles: SObjectSO[]) => ({
		toRateCard: (rateCardSO: SObjectSO) => addRolesToARateCard(rateCardSO.id as string, roles),
	}),
};

function addRolesToARateCard(rateCardId: string, roles: SObjectSO[]) {
	return async(actor: Actor): Promise<SObjectSO> => {
		const rateCardItemsForRoles = roles.map((role: SObjectSO) => RateCardItem.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
			rateCardId, productId: role.id,
		}));

		return actor.attemptsTo(Insert.records(`${actor.world.namespacePrefix}${RateCardItem.apiName}`, rateCardItemsForRoles));
	};
}

async function createAnEmptyQuote(actor: Actor) {
	const rateCard = await actor.attemptsTo(Create.aRateCard.thatIsEmpty);
	return actor.attemptsTo(Create.aQuote.withRateCard(rateCard));
}

async function createAnEmptyRateCard(actor: Actor): Promise<SObjectSO> {
	return actor.attemptsTo(Insert.record(`${actor.world.namespacePrefix}${RateCard.apiName}`, RateCard.getRecordCreateDefaults(actor.world.isDeployedInPackage)));
}

function createAnEmptyQuoteWithRateCard(rateCard: SObjectSO | SObjectSOCallback) {
	return async(actor: Actor): Promise<SObjectSO> => {
		const rateCardId = rateCard instanceof Function ? rateCard(actor).id : rateCard.id;
		return actor.attemptsTo(Insert.record(`${actor.world.namespacePrefix}${Quote.apiName}`, Quote.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
			rateCardId,
		})));
	};
}

function createARateCardWithRoles(numberOfRoles: number) {
	return async(actor: Actor) => {
		const rateCardSO: SObjectSO = await actor.attemptsTo(Create.aRateCard.thatIsEmpty);
		const roles: SObjectSO[] = await actor.attemptsTo(Create.roles(numberOfRoles));
		return actor.attemptsTo(
			Add.roles(roles).toRateCard(rateCardSO),
		);
	};
}

function createRoles(numberOfRoles: number) {
	return async(actor: Actor): Promise<SObjectSO[]> => {
		const productObjectQualifiedName = `${actor.world.namespacePrefix}${Product.apiName}`;
		const recordTypeIdsByName = await actor.attemptsTo(Describe.theRecordTypes.for(productObjectQualifiedName));
		const rolesToCreate: SObjectSO[] = [];
		for (let i = 0; i < numberOfRoles; i++) {
			rolesToCreate.push(Product.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
				recordTypeId: recordTypeIdsByName.get(RECORD_TYPE_RESOURCE_ROLE),
			}));
		}

		return actor.attemptsTo(Insert.records(productObjectQualifiedName, rolesToCreate));
	};
}
