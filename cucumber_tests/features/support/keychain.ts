import fs from 'fs';
import { Authenticate, AuthenticatedUser } from '../abilities/authenticate';

export type KeyChainEntry = {
    loginUrl: string;
    username: string;
    password: string;
};

let rawKeys;
let availableKeys: AuthenticatedUser[] = [];
const checkedOutKeys: AuthenticatedUser[] = [];

export class KeyChain {
	static checkout() {
		if (!rawKeys) { // first time checking out any keys
			rawKeys = fs.readFileSync('keys.json', 'utf8');
			availableKeys = (JSON.parse(rawKeys) as KeyChainEntry[]).map((key: KeyChainEntry) => Authenticate.withKeys(key));
		}

		if (!availableKeys) {
			// TODO: improve intelligence by allowing 1 key to be checkout out once per scenario but many times when being run in parallel
			throw Error('There are no available credentials. Please add credentials to keys.json or reduce the number of parallel runs.');
		}

		const keyToCheckout = availableKeys.shift();
		checkedOutKeys.push(keyToCheckout as AuthenticatedUser);
		return buildCheckInKey(keyToCheckout as AuthenticatedUser);
	}

	static checkInAllKeys() {
		availableKeys = [...availableKeys, ...checkedOutKeys];
	}
}

function buildCheckInKey(entry: AuthenticatedUser) {
	return {
		checkIn: () => {
			availableKeys.push(entry);
			checkedOutKeys.splice(checkedOutKeys.indexOf(entry), 1);
		},
		entry,
	};
}