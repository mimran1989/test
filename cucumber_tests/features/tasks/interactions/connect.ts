import jsforce, { Connection, UserInfo } from 'jsforce';
import { AuthenticatedUser } from '../../abilities/authenticate';
import { Actor } from '../../support/actor';

export const Connect = {
	withCredentials: async(actor: Actor): Promise<Error | UserInfo> => new Promise((resolve, reject) => {
		const authUserInfo: AuthenticatedUser = actor.getAbility(AuthenticatedUser) as AuthenticatedUser;
		if (!authUserInfo) {
			throw Error(`Actor: ${actor.name} does not have the ${AuthenticatedUser.type} ability.`);
		}

		if (authUserInfo.isConnected) {
			resolve(authUserInfo.connection.userInfo as UserInfo);
		} else {
			const { loginUrl, username, password } = authUserInfo;
			const connection: Connection = new jsforce.Connection({ loginUrl });
			connection.login(username, password, (err, userInfo) => {
				if (err) {
					reject(err);
				} else {
					const { accessToken, instanceUrl } = connection;
					authUserInfo.connected({
						connection,
						accessToken,
						instanceUrl,
						userInfo,
					});

					resolve(userInfo);
				}
			});
		}
	}),
};

export function getSalesforceConnection(actor: Actor): Connection {
	const authUserInfo: AuthenticatedUser = actor.getAbility(AuthenticatedUser) as AuthenticatedUser;
	if (!authUserInfo) {
		throw new Error(`Actor: ${actor.name} does not have the ability \`${AuthenticatedUser.type}}\``);
	}

	const salesforceConnection: Connection = authUserInfo.connection;
	if (!salesforceConnection) {
		throw new Error(`There is no open connection for: ${actor.name} `);
	}

	return salesforceConnection;
}
