import { Given } from '@cucumber/cucumber';
import { Actor } from '../features/support/actor';
import Login from '../features/tasks/login';

Given('{actor} (has )logs(ed) in', async(actor: Actor) => {
	await actor.attemptsTo(Login.withCredentials);
});
