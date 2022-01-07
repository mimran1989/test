import { Connection, UserInfo } from 'jsforce';
import Ability from '../support/ability';
import { KeyChainEntry } from '../support/keychain';

export class AuthenticatedUser extends Ability {
	static type: string = 'authenticate';
	readonly username: string;
	readonly password: string;
	readonly loginUrl: string;

	private _loggedIn = false;
	private _connected = false;
	private _connection: Connection;
	private _accessToken: string;
	private _instanceUrl: string;
	private _userInfo: UserInfo;

	constructor(username: string, password: string, loginUrl: string) {
		super();
		this.username = username;
		this.password = password;
		this.loginUrl = loginUrl;
	}

	// eslint-disable-next-line class-methods-use-this
	get type(): string {
		return AuthenticatedUser.type;
	}

	get isLoggedIn(): boolean {
		return this._loggedIn;
	}

	get isConnected(): boolean {
		return this._connected;
	}

	get connection() {
		return this._connection;
	}

	loggedIn(): void {
		this._loggedIn = true;
	}

	connected({
		connection,
		accessToken,
		instanceUrl,
		userInfo,
	}: { connection: Connection, accessToken: string, instanceUrl: string, userInfo: UserInfo}) {
		this._connection = connection;
		this._accessToken = accessToken;
		this._instanceUrl = instanceUrl;
		this._userInfo = userInfo;
		this._connected = true;
	}
}

export const Authenticate = {
	usingUsernameAndPassword: (username: string, password: string, loginUrl: string) => new AuthenticatedUser(username, password, loginUrl),
	withKeys: (keys: KeyChainEntry) => new AuthenticatedUser(keys?.username, keys?.password, keys?.loginUrl),
};