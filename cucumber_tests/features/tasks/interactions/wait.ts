import { Assert } from '../../questions/ensure';
import { Actor } from '../../support/actor';

const Wait = {
	for: (timeToWait: number) => ({
		seconds: (actor: Actor) => actor.world.tc.wait(timeToWait * 1000),
	}),
	upTo: (waitTime: number) => ({
		seconds: {
			until: (selector: Selector) => Assert(selector, undefined, waitTime * 1000),
		},
	}),
};

export default Wait;
