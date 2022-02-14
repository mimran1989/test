import { AuthenticatedUser } from '../../abilities/authenticate';
import { Actor } from '../../support/actor';
import { SObjectSO, SObjectSOCallback } from '../../support/sObject';

const Browse = {
	to: {
		theUrl: (url: string) => async(actor: Actor) => actor.world.tc.navigateTo(url),
		theSObject: browseToTheSObject,
		theHomePage: async(actor: Actor) => {
			const { instanceUrl } = (actor.getAbility(AuthenticatedUser) as AuthenticatedUser);
			let appNamespace = actor.world.namespacePrefix;
			if (!appNamespace) {
				appNamespace = 'c__';
			}

			actor.attemptsTo(Browse.to.theUrl(`${instanceUrl}/lightning/app/${appNamespace}ProvusQuoting`));
		},
	},
	toThe: (callback: SObjectSOCallback) => browseToTheSObject(callback).recordPage,
};

function browseToTheSObject(sObject: SObjectSO | SObjectSOCallback) {
	return {
		recordPage: async(actor: Actor) => {
			const recordId = sObject instanceof Function ? sObject(actor).id : sObject.id;
			return actor.world.tc.navigateTo(`/${recordId}`);
		},
	};
}

export default Browse;
