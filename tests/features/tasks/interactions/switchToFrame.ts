import { Actor } from '../../support/actor';
import { WebComponentSelector } from '../../support/componentSelector';

const SwitchToFrame = (selector: WebComponentSelector) => async(actor: Actor) => actor.world.tc.switchToIframe(
	selector.with({ boundTestRun: actor.world.tc }),
);

export default SwitchToFrame;
