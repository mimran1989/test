import { AuthenticatedUser } from '../abilities/authenticate';
import { Connect } from '../tasks/interactions/connect';
import Login from '../tasks/login';
import { KeyChain } from './keychain';
import { World } from './world';

export default {
	name: 'actor',
	regexp: /[A-Z][a-z]+|I/,
	async transformer(this: World, actorName: string) {
		const actor = this.findOrCreateActor(actorName);
		if (!actor.hasAbility(AuthenticatedUser)) {
			const keyChain = KeyChain.checkout();
			const authenticateWithKeys = keyChain.entry;
			actor.whoCan(authenticateWithKeys);
			await actor.attemptsTo(
				Login.withCredentials, // login using the user interface
				Connect.withCredentials, // open a bulk api connection to salesforce
			);
		}

		return actor;
	},
};
