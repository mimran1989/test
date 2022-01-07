import { Actor } from '../../support/actor';
import { SObjectSO, SObjectSOCallback } from '../../support/sObject';

const Browse = {
	to: {
		theUrl: (url: string) => async(actor: Actor) => actor.world.tc.navigateTo(url),
		theSObject: browseToTheSObject,
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
