import { Connection } from 'jsforce';
import { AuthenticatedUser } from '../abilities/authenticate';
import { Actor } from '../support/actor';
import { getSalesforceConnection } from './interactions/connect';
import Insert from './interactions/crud';

export const Assign = {
	permissionSets: async(actor: Actor) => {
		const salesforceConnection: Connection = getSalesforceConnection(actor);
		const { username, permissionSets } = (actor.getAbility(AuthenticatedUser) as AuthenticatedUser).keys;
		const userRecord = await salesforceConnection.query(`SELECT Id FROM User where Username='${username}'`);
		const userId = (userRecord.records[0] as any).Id as string;

		const requiredPermissionSetsQryString = permissionSets
			.map((permSetName) => `'${permSetName}'`)
			.join(',');

		const requiredPermissionSetIds = (await salesforceConnection
			.query(`SELECT Id, Name FROM PermissionSet Where Name IN (${requiredPermissionSetsQryString})`))
			.records
			.map((permissionSet: any) => permissionSet.Id);

		const assignedPermissionSetIds = (await salesforceConnection
			.query(`SELECT Id, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = '${userId}'`))
			.records
			.map((permissionSet: any) => permissionSet.PermissionSetId);

		const permissionSetAssignmentsToInsert = requiredPermissionSetIds
			.filter((permissionSetId) => !assignedPermissionSetIds.includes(permissionSetId))
			.map((permissionSetId) => ({
				AssigneeId: userId,
				PermissionSetId: permissionSetId,
			}));

		await actor.attemptsTo(Insert.records('PermissionSetAssignment', permissionSetAssignmentsToInsert));
	},
};

export default Assign;
