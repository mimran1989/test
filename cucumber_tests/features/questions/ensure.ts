import { t } from 'testcafe';
import { Actor } from '../support/actor';

const assertions = (selector: Selector, message?: string) => ({
	doesNotExist: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).exists).notOk(message),
	exists: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).exists).ok(message),
	isVisible: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).visible).ok(message),
	isNotVisible: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).visible).notOk(message),
	isDisabled: async(actor: Actor) => actor
		.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).hasAttribute('disabled')).ok(message),
	isNotDisabled: async(actor: Actor) => actor
		.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).hasAttribute('disabled')).notOk(message),
});

const Ensure = {
	that: t.expect,
	the: (selector: Selector, message?: string) => assertions(selector, message),
};

export default Ensure;
