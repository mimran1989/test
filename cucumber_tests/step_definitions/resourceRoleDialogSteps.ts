import { Then, When } from '@cucumber/cucumber';
import Ensure from '../features/questions/ensure';
import { Actor } from '../features/support/actor';
import Click from '../features/tasks/interactions/click';
import ResourceRoleDialog from '../features/tasks/view-models/resourceRoleDialog';

When('{actor} close(s) the resource role dialog', (actor) => actor.attemptsTo(Click.on(ResourceRoleDialog.cancelButton)));

Then('{actor} can see the resource role dialog', (actor: Actor) => actor.attemptsTo(Ensure.the(ResourceRoleDialog.component).exists));

Then('{actor} should not see the resource role dialog', (actor: Actor) => actor.attemptsTo(Ensure.the(ResourceRoleDialog.component).doesNotExist));

Then('{actor} can see that he/she/they/I cannot close the resource role dialog', (actor: Actor) => actor
	.attemptsTo(Ensure.the(ResourceRoleDialog.cancelButton).isNotVisible));

Then('{actor} can see that they/I can close the resource role dialog', (actor: Actor) => actor
	.attemptsTo(
		Ensure.the(ResourceRoleDialog.cancelButton).isVisible,
		Ensure.the(ResourceRoleDialog.cancelButton).isNotDisabled,
	));

Then('{actor} can can see the no available roles info message', (actor) => actor.attemptsTo(Ensure.the(ResourceRoleDialog.noRolesAvailableText).isVisible));
