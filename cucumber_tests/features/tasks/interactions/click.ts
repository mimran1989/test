import { Selector } from 'testcafe';
import { Actor } from '../../support/actor';

const Click = {
	on: (selector: string | Selector | SelectorPromise) => async(actor: Actor) => actor.world.tc.click(Selector(selector).with({ boundTestRun: actor.world.tc })),
};

export default Click;
