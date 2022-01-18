import { AuthenticatedUser } from '../abilities/authenticate';
import Browse from '../tasks/interactions/browse';
import { Connect } from '../tasks/interactions/connect';
import Login from '../tasks/login';
import Assign from '../tasks/permissions';
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
			const { isLoggedIn: wasLoggedIn } = authenticateWithKeys;
			actor.whoCan(authenticateWithKeys);

			await actor.attemptsTo(
				Login.withCredentials, // login using the user interface
				Connect.withCredentials, // open a bulk api connection to salesforce
				Assign.permissionSets, // assign the required permission sets for this user role

			);

			if (!wasLoggedIn) {
				// repeated browsing to the application homepage causes
				// system instability
				await actor.attemptsTo(Browse.to.theHomePage);
			}
		}

		return actor;
	},
};
