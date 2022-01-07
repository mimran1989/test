import { Actor } from '../../support/actor';
import { WebComponentSelector } from '../../support/componentSelector';

const Enter = {
	theValue: (textValue: string) => ({
		into: (selector: string | Selector | WebComponentSelector) => async(actor: Actor) => actor.world.tc.typeText(selector, textValue),
	}),
};

export default Enter;
