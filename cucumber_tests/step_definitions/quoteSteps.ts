import { Given, When } from '@cucumber/cucumber';
import { Actor } from '../features/support/actor';
import { Quote, RateCard } from '../features/support/sObject';
import { Create } from '../features/tasks/create';
import Browse from '../features/tasks/interactions/browse';
import { Last } from '../features/tasks/interactions/crud';
import Wait from '../features/tasks/interactions/wait';

Given('{actor} have/has created a quote', async(actor: Actor) => actor.attemptsTo(
	Create.aQuote.thatIsEmpty,
));

Given('{actor} have/has created an empty quote with this rate card', (actor) => actor.attemptsTo(Create.aQuote.withRateCard(Last.created(RateCard))));

Given('{actor} have/has created a rate card with {int} role(s)', (actor: Actor, numberOfRoles: number) => actor.attemptsTo(
	Create.aRateCard.withRoles(numberOfRoles),
));

When('{actor} visit(s) the quote', async(actor: Actor) => actor.attemptsTo(
	Browse.toThe(Last.created(Quote)),
	Wait.for(5).seconds, // arbitrarily wait for 5 seconds to give the page time to load
));
