import { Then, When } from '@cucumber/cucumber';
import Ensure from '../features/questions/ensure';
import { Actor } from '../features/support/actor';
import { World } from '../features/support/world';
import Click from '../features/tasks/interactions/click';
import Wait from '../features/tasks/interactions/wait';
import Select from '../features/tasks/select';
import ResourceRoleDialog from '../features/tasks/view-models/resourceRoleDialog';

When('{actor} close(s) the resource role dialog', (actor) => actor.attemptsTo(Click.on(ResourceRoleDialog.cancelButton)));

When('selects the {string} resource role', function selectTheResourceRole(this: World, roleName: string) {
	return this.actorLookup.lastActor.attemptsTo(Select.item(ResourceRoleDialog.roleDropDownItem.labeled(roleName))
		.inComboBox(ResourceRoleDialog.roleDropdown));
});

When('selects a rate', function selectFirstRateCardItem(this: World) {
	return this.actorLookup.lastActor.attemptsTo(
		Click.on(ResourceRoleDialog.rateItem.number(1).radioButton),
		Wait.for(2).seconds, // TODO: add an explicit wait for the selection to complete
		Click.on(ResourceRoleDialog.addToQuoteButton),
	);
});

Then('{actor} can see the resource role dialog', (actor: Actor) => actor.attemptsTo(
	Wait.upTo(30).seconds.until(ResourceRoleDialog.component).exists,
));

Then('{actor} should not see the resource role dialog', (actor: Actor) => actor.attemptsTo(Ensure.the(ResourceRoleDialog.component).doesNotExist));

Then('{actor} can see that he/she/they/I cannot close the resource role dialog', (actor: Actor) => actor
	.attemptsTo(Ensure.the(ResourceRoleDialog.cancelButton).isNotVisible));

Then('{actor} can see that they/I can close the resource role dialog', (actor: Actor) => actor
	.attemptsTo(
		Ensure.the(ResourceRoleDialog.cancelButton).isNotDisabled,
	));

Then('{actor} can can see the no available roles info message', (actor) => actor.attemptsTo(Ensure.the(ResourceRoleDialog.noRolesAvailableText).isVisible));
