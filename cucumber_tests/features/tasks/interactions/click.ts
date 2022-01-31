import { Selector } from 'testcafe';
import { Actor } from '../../support/actor';
import { WebComponentSelector } from '../../support/componentSelector';

const Click = {
	on: (selector: string | Selector | WebComponentSelector) => async(actor: Actor) => actor.world.tc.click(Selector(selector).with({ boundTestRun: actor.world.tc })),
};

export default Click;
