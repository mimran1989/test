import { DataTable, Given } from '@cucumber/cucumber';
import { Actor } from '../features/support/actor';
import { Create } from '../features/tasks/create';

Given('{actor} have/has created a rate card with {int} role(s)', (actor: Actor, numberOfRoles: number) => actor.attemptsTo(
	Create.aRateCard.with(numberOfRoles).roles,
));

Given('{actor} have/has created a rate card with roles', (actor, dataTable: DataTable) => {
	const roles = dataTable.hashes().map((row) => ({
		Name: row.Name,
		SkillLevel: row['Skill Level'],
	}));

	return actor.attemptsTo(Create.aRateCard.withRoles(roles));
});
