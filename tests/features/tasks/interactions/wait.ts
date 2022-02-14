import { Assert } from '../../questions/ensure';
import { Actor } from '../../support/actor';
import { WebComponentSelector } from '../../support/componentSelector';

const Wait = {
	for: (timeToWait: number) => ({
		seconds: (actor: Actor) => actor.world.tc.wait(timeToWait * 1000),
	}),
	upTo: (waitTime: number) => ({
		seconds: {
			until: (selector: Selector | WebComponentSelector) => Assert(selector, undefined, waitTime * 1000),
		},
	}),
};

export default Wait;
