import { Actor } from '../support/actor';
import {
	Quote, SObjectSO, SObjectSOCallback,
} from '../support/sObject';
import Insert from './interactions/crud';
import { createRoles } from './product';
import { addRolesToARateCard, createAnEmptyRateCard, createARateCardWithRoles } from './ratecard';

export const Create = {
	aQuote: ({
		thatIsEmpty: createAnEmptyQuote,
		withRateCard: createAnEmptyQuoteWithRateCard,
	}),
	aRateCard: ({
		thatIsEmpty: createAnEmptyRateCard,
		withRoles: createARateCardWithRoles,
		with: (numRoles: number) => ({ roles: createARateCardWithRoles(numRoles) }),
	}),
	roles: createRoles,
};

export const Add = {
	roles: (roles: SObjectSO[]) => ({
		toRateCard: (rateCardSO: SObjectSO) => addRolesToARateCard(rateCardSO.id as string, roles),
	}),
};

async function createAnEmptyQuote(actor: Actor) {
	const rateCard = await actor.attemptsTo(Create.aRateCard.thatIsEmpty);
	return actor.attemptsTo(Create.aQuote.withRateCard(rateCard));
}

function createAnEmptyQuoteWithRateCard(rateCard: SObjectSO | SObjectSOCallback) {
	return async(actor: Actor): Promise<SObjectSO> => {
		const rateCardId = rateCard instanceof Function ? rateCard(actor).id : rateCard.id;
		return actor.attemptsTo(Insert.record(`${actor.world.namespacePrefix}${Quote.apiName}`, Quote.getRecordCreateDefaults(actor.world.isDeployedInPackage, {
			rateCardId,
		})));
	};
}
